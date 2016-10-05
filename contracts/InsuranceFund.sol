import "helpers/Owned.sol";

import "tokens/Token.sol";
import "InvestmentFund.sol";

contract InsuranceFund is Owned, Token {
    string public standard = 'InsuranceToken 0.1';
    string public name;
    string public symbol;
    uint16 public tokenTypes;
    uint256 public totalSupply;

    uint insurancePeriod = 30 days;

    event Transfer(address indexed from, address indexed to, uint256 value);

    InvestmentFund public investmentFund;

    mapping (uint16 => uint256) public soldPremiums;
    mapping (uint16 => uint256) public tokenPrices;
    mapping (uint16 => mapping (address => uint256)) public balance;

    struct InsuredProfile {
        uint16 plan;
        uint256 startDate;
        uint256 finalDate;
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

    function buyInsuranceToken(uint16 tokenType) returns (uint16 n) {
        uint256 delta = msg.value - tokenPrices[tokenType];
        if (delta < 0) {
           throw;
        }

        if (delta > 0 && !msg.sender.send(delta)) {  // recursion attacks
            throw;
        }

        n = getPlanIdentifier(tokenType);

        if (insuredProfile[msg.sender].startDate == 0) {
          insuredProfile[msg.sender] = InsuredProfile({plan: n, startDate: now, finalDate: now});
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
        soldPremiums[tokenType] += n;

        Transfer(this, msg.sender, n);
    }

    function transferForClaim(uint256 claimAmount, uint16 insuranceType, address claimer, address beneficiaryAddress) onlyOwner {
        uint16 n = getPlanIdentifier(insuranceType);

        InsuredProfile insured = insuredProfile[claimer];
        if (balance[insuranceType][claimer] >= n && insured.plan == n && insured.finalDate >= now && insured.startDate <= now) {
            balance[insuranceType][claimer] -= n;
            balance[insuranceType][this] += n;
        } else {
            throw;
        }

        if (beneficiaryAddress.send(claimAmount)) {
            Transfer(msg.sender, this, n);
        } else {
            throw;
        }
    }

    function calculatePremiums() returns (uint256 premiums){
        for (uint256 i=0; i<tokenTypes; ++i) {
            premiums += soldPremiums[uint16(i)];
        }
    }

    function getBalance() returns (uint256) {
        address insuranceFund = this;
        return insuranceFund.balance;
    }

    function equilibrateFunds() {
        solveFundBalance(checkFundBalance(getBalance()));
    }

    function checkFundBalance(uint256 balance) private returns (uint256 delta){
        delta = balance - calculatePremiums();
    }

    function solveFundBalance(uint256 delta) private {
        if (delta > 0) {
            investmentFund.profits.value(delta)();
        } else {
            investmentFund.needs(-delta);
        }
    }

    function sendInvestmentInjection() {

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
}
