pragma solidity ^0.4.3;

import "helpers/Owned.sol";

import "tokens/Token.sol";
import "InvestmentFund.sol";

import "Claim.sol";

contract InsuranceFund is Owned, Token {
    string public standard = 'InsuranceToken 0.1';
    string public name;
    string public symbol;
    uint16 public tokenTypes;
    uint256 public totalSupply;

    uint insurancePeriod = 30 days;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event NewClaim(address claimAddress, address originator);
    event PayoutForClaim(address claimAddress, uint256 claimAmount);

    InvestmentFund public investmentFund;

    mapping (uint16 => uint256) public tokenPrices;
    mapping (uint16 => mapping (address => uint256)) public balance;

    mapping (uint256 => address) public claims;
    uint256 public claimIndex;

    mapping (uint16 => address) public examiners;
    uint16 private examinerIndex;

    uint256 public soldPremiums;
    uint256 public claimedMoney;
    uint256 public accumulatedLosses;

    struct InsuredProfile {
        uint16 plan;
        uint256 startDate;
        uint256 finalDate;
        address[] claims;
    }

    mapping (address => InsuredProfile) public insuredProfile;

    function InsuranceFund(
        string tokenName,
        string tokenSymbol,
        uint256[] initialTokenPrices
        ) {
        owner = msg.sender;

        uint256 initialSupplyPerToken = uint256(2**256 - 1);
        if (initialTokenPrices.length == 0) {
          uint256[] memory prices = new uint[](2);
          prices[0] = 1000;
          prices[1] = 10000;
          setup(1000, "", "", prices);
        } else {
          setup(initialSupplyPerToken, tokenName, tokenSymbol, initialTokenPrices);
        }
    }

    function setup(
      uint256 initialSupplyPerToken,
      string tokenName,
      string tokenSymbol,
      uint256[] initialTokenPrices
      ) {
        for (uint16 i=0; i<initialTokenPrices.length; ++i) {
          balance[i][this] = initialSupplyPerToken;
          tokenPrices[i] = initialTokenPrices[i];
          totalSupply += initialSupplyPerToken;
          tokenTypes += 1;
        }

        name = tokenName;
        symbol = tokenSymbol;
    }

    function addExaminer(address examinerAddress) onlyOwner {
      examiners[examinerIndex] = examinerAddress;
      examinerIndex += 1;
    }

    function removeExaminer(address examinerAddress) onlyOwner {
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

    function balanceOf(address _owner) constant returns (uint256) {
        uint256 b = 0;
        for (uint256 i=0; i<tokenTypes; ++i) {
            b += balance[uint16(i)][_owner];
        }
        return b;
    }

    function getPlanIdentifier(uint16 tokenType) constant returns (uint16) {
      return 1 + 100 * tokenType;
    }

    function setInvestmentFundAddress(address newAddress) onlyOwner {
        if (newAddress == 0) { throw; }
        investmentFund = InvestmentFund(newAddress);
    }

    function buyInsuranceToken(uint16 tokenType) payable returns (uint16 n) {
        int256 delta = int256(msg.value) - int256(tokenPrices[tokenType]);
        if (delta < 0) {
           throw;
        }

        if (delta > 0 && !msg.sender.send(uint256(delta))) {  // recursion attacks
          throw;
        }

        n = getPlanIdentifier(tokenType);

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

        if (balance[tokenType][this] < n) { throw; }
        balance[tokenType][this] -= n;
        balance[tokenType][msg.sender] = n;
        soldPremiums += tokenPrices[tokenType];

        Transfer(this, msg.sender, n);

        return n;
    }

    function createClaim(uint16 claimType, string evidence, address beneficiary) returns (int) {
      Claim newClaim = new Claim(claimType, evidence, this, beneficiary);
      newClaim.transferOwnership(msg.sender);
      return submitClaim(newClaim, claimType, msg.sender);
    }

    function submitClaim(Claim submittedClaim, uint16 claimType, address claimer) returns (int) {
      uint16 planId = getPlanIdentifier(claimType);

      InsuredProfile insured = insuredProfile[claimer];
      if (balance[claimType][claimer] >= planId
          && insured.plan == planId && insured.finalDate >= now
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

    function performFundAccounting() public onlyOwner {
      int256 balance = int256(soldPremiums) - int256(claimedMoney) - int256(accumulatedLosses);
      if (balance > 0) {
        if (address(investmentFund) != 0) {
          if (investmentFund.sendProfitsToInvestors.value(uint256(balance))()) {
            soldPremiums = 0;
            claimedMoney = 0;
            accumulatedLosses = 0;
          } else {
            throw;
          }
        } else {
          Log("No investment fund known :(");
          throw;
        }
      } else {
        soldPremiums = 0;
        claimedMoney = 0;
        accumulatedLosses = uint256(-balance);
      }
    }

    function addTokenType(uint256 newTokenPrice, uint256 mintAmount) onlyOwner {
        tokenTypes += 1;
        tokenPrices[tokenTypes] = newTokenPrice;
        balance[tokenTypes][this] = mintAmount;
        totalSupply += mintAmount;
    }

    function mintToken(uint256 mintAmount) onlyOwner {
        for (uint16 i=0; i<tokenTypes; ++i) {
            balance[i][this] += mintAmount;
            totalSupply += mintAmount;
        }
    }

    function () payable {}
}
