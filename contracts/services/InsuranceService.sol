pragma solidity ^0.4.4;

import "../Claim.sol";
import "./InvestmentService.sol";
import "../helpers/Managed.sol";
import "../persistance/InsurancePersistance.sol";

contract InsuranceService is Managed('InsuranceService') {
    uint insurancePeriod = 30 days;

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

    function getPlanCount() requiresPermission(PermissionLevel.Read) constant returns (uint16) {
      return persistance().planTypes();
    }

    function getPlanPrice(uint16 plan) requiresPermission(PermissionLevel.Read) constant returns (uint256) {
      return persistance().planPrices(plan);
    }

    function setInitialPlans() {
      setInsurancePlans(getInitialInsurancePrices(3));
    }

    function getInitialInsurancePrices(uint16 k) constant private returns (uint256[]) {
      uint256[] memory prices = new uint256[](k);
      for (uint16 i=0; i < k; i++) {
        prices[i] = uint256(i + 1) * 2 ether;
      }
      return prices;
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
     (int16 plan,
      uint256 startDate,
      uint256 finalDate,
      uint256 totalSubscribedClaims) {

      var (p, s, f, cs) = persistance().insuredProfile(insured);
      return (s > 0 ? int16(p) : int16(-1), s, f, cs);
    }

    function getInsurancePlan(address insured) constant returns (int256 plan) {
      (plan,) = getInsuranceProfile(insured);
      return;
    }

    function getPlanIdentifier(uint16 planType) constant returns (uint16) {
      return 1 + 100 * planType;
    }

    function buyInsurancePlanFor(address insured, uint256 amountPayed, uint16 planType) payable returns (bool) {
      if (int256(amountPayed) < int256(persistance().planPrices(planType))) {
         return false;
      }

      uint16 planIdentifier = getPlanIdentifier(planType);
      var (p, s, f, cc) = getInsuranceProfile(insured);

      // If never subscribed or current subscription was expired, new plan.
      uint256 planStart = (s > 0 && now < f) ? s : now;
      persistance().setInsuranceProfile(insured, int16(planIdentifier), int256(planStart), int256(planStart + insurancePeriod));

      // soldPremiums += planPrices[planType];
      InsuranceBought(msg.sender, planIdentifier);

      return true;
    }

    function createClaim(uint16 claimType, string evidence, address beneficiary) returns (int) {
      Claim newClaim = new Claim(claimType, evidence, this, beneficiary);
      newClaim.transferOwnership(msg.sender);
      return submitClaim(newClaim, claimType, msg.sender);
    }

    function submitClaim(Claim submittedClaim, uint16 claimType, address claimer) returns (int) {
      uint16 planId = getPlanIdentifier(claimType);

      /*
      InsuredProfile insured = insuredProfile[claimer];
      if (insured.plan == planId && insured.finalDate >= now
          && insured.startDate <= now) {
          return -1;
      }

      insured.claims.push(address(submittedClaim));
      */

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
