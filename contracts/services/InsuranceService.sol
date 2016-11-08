pragma solidity ^0.4.3;

import "../Claim.sol";
import "./InvestmentService.sol";
import "../helpers/Managed.sol";
import "../persistance/InsurancePersistance.sol";

contract InsuranceService is Managed('InsuranceService') {
    struct InsuredProfile {
        uint16 plan;
        uint256 startDate;
        uint256 finalDate;
        address[] claims;
    }
    mapping (address => InsuredProfile) private insuredProfile;

    uint insurancePeriod = 30 days;

    mapping (uint16 => uint256) public planPrices;
    uint16 public planTypes;

    uint256 public soldPremiums;
    uint256 public claimedMoney;
    uint256 public accumulatedLosses;

    mapping (uint256 => address) public claims;
    uint256 public claimIndex;

    mapping (uint16 => address) public examiners;
    uint16 private examinerIndex;

    event InsuranceBought(address insured, uint16 insuranceType);
    event NewClaim(address claimAddress, address originator);
    event PayoutForClaim(address claimAddress, uint256 claimAmount);

    function InsuranceService() {
    }

    function setInsurancePlans(uint256[] plans) requiresPermission(PermissionLevel.Write) {
      persistance().setInsurancePlans(plans);
    }

    function addExaminer(address examinerAddress) requiresPermission(PermissionLevel.Manager) {
      examiners[examinerIndex] = examinerAddress;
      examinerIndex += 1;
    }

    function removeExaminer(address examinerAddress) requiresPermission(PermissionLevel.Manager) {
      bool foundExaminer = false;
      for (uint16 i = 0; i<examinerIndex; i++) {
        if (!foundExaminer && examiners[i] == examinerAddress) {
          foundExaminer = true;
        }
        if (foundExaminer) {
          if (i < examinerIndex) {
            examiners[i] = examiners[i+1];
          }
        }
      }

      if (foundExaminer) {
        examinerIndex -= 1;
      }
    }

    function getInsuranceProfile(address insured) constant returns
     (int256 plan,
      int256 startDate,
      int256 finalDate) {

      InsuredProfile profile = insuredProfile[insured];
      if (profile.startDate == 0) {
          return (-1, -1, -1);
      }

      return (int256(profile.plan), int256(profile.startDate), int256(profile.finalDate));
    }

    function getInsurancePlan(address insured) constant returns (int256 plan) {
      int256 b;
      int256 c;
      (plan, b, c) = getInsuranceProfile(insured);
    }

    function getPlanIdentifier(uint16 planType) constant returns (uint16) {
      return 1 + 100 * planType;
    }

    function buyInsurancePlan(uint16 planType) payable returns (bool) {
        int256 delta = int256(msg.value) - int256(planPrices[planType]);
        if (delta < 0) {
           return false;
        }

        if (delta > 0 && !msg.sender.send(uint256(delta))) {  // return remaining money
          throw;
        }

        uint16 n = getPlanIdentifier(planType);

        if (insuredProfile[msg.sender].startDate == 0) {
          insuredProfile[msg.sender] = InsuredProfile({plan: n, startDate: now, finalDate: now, claims: new address[](0)});
        } else {
          insuredProfile[msg.sender].plan = n;
          if (now > insuredProfile[msg.sender].finalDate) {
            insuredProfile[msg.sender].startDate = now;
            insuredProfile[msg.sender].finalDate = now;
          }
        }

        insuredProfile[msg.sender].finalDate += insurancePeriod;

        soldPremiums += planPrices[planType];

        InsuranceBought(msg.sender, n);

        return true;
    }

    function createClaim(uint16 claimType, string evidence, address beneficiary) returns (int) {
      Claim newClaim = new Claim(claimType, evidence, this, beneficiary);
      newClaim.transferOwnership(msg.sender);
      return submitClaim(newClaim, claimType, msg.sender);
    }

    function submitClaim(Claim submittedClaim, uint16 claimType, address claimer) returns (int) {
      uint16 planId = getPlanIdentifier(claimType);

      InsuredProfile insured = insuredProfile[claimer];
      if (insured.plan == planId && insured.finalDate >= now
          && insured.startDate <= now) {
          return -1;
      }

      insured.claims.push(address(submittedClaim));

      claims[claimIndex] = address(submittedClaim);
      claimIndex += 1;

      NewClaim(address(submittedClaim), claimer);
      submittedClaim.transitionState(Claim.ClaimStates.Review);
      submittedClaim.assignExaminers(examinersForClaim(claimType), examinerIndex);

      return int(claimIndex - 1);
    }

    function submitClaimAddress(address claimAddress) returns (int) {
      Claim claim = Claim(claimAddress);
      uint16 claimType = claim.claimType();
      address claimer = claim.ownerAddress();
      return submitClaim(claim, claimType, claimer);
    }

    function transferForClaim(address claimAddress) {
      Claim claim = Claim(claimAddress);
      if (claim.currentState() == Claim.ClaimStates.Accepted) {
        uint256 claimAmount = moneyForClaim(claim.claimType());
        if (claim.sendPayout.value(claimAmount)() &&
            claim.currentState() == Claim.ClaimStates.Payed) {
          claimedMoney += claimAmount;
          PayoutForClaim(claimAddress, claimAmount);
        } else {
          throw;
        }
      }
    }

    function examinersForClaim(uint16 claimType) private returns (address[]) {
      // right now it the difference among claimTypes
      address[] memory claimExaminers = new address[](examinerIndex);
      for (uint16 i = 0; i < examinerIndex; i++) {
        claimExaminers[i] = examiners[i];
      }
      return claimExaminers;
    }

    function insuredClaims(address insured) constant returns (address[]) {
      return insuredProfile[insured].claims;
    }

    function moneyForClaim(uint16 claimType) constant returns (uint256) {
      return 5 ether;
    }

    function performFundAccounting() public requiresPermission(PermissionLevel.Manager) {
      int256 balance = int256(soldPremiums) - int256(claimedMoney) - int256(accumulatedLosses);
      if (balance > 0) {
          if (InvestmentService(addressFor('Investment')).sendProfitsToInvestors.value(uint256(balance))()) {
            soldPremiums = 0;
            claimedMoney = 0;
            accumulatedLosses = 0;
          } else {
            throw;
          }
      } else {
        soldPremiums = 0;
        claimedMoney = 0;
        accumulatedLosses = uint256(-balance);
      }
    }

    function persistance() constant private returns (InsurancePersistance) {
      return InsurancePersistance(addressFor('InsuranceDB'));
    }

    function () payable {}
}
