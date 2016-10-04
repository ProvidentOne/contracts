import "helpers/Owned.sol";
import "helpers/ConvertLib.sol";

import "tokens/Token.sol";
import "InvestmentFund.sol";

contract InsuranceFund is Owned, Token {
    string public standard = 'InsuranceToken 0.1';
    string public name;
    string public symbol;
    uint16 public tokenTypes = 3;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    InvestmentFund public investmentFund;

    mapping (uint16 => uint256) public soldPremiums;

    mapping (uint16 => uint256) public tokenPrices;
    mapping (uint16 => mapping (address => uint256)) public balance;

    function InsuranceFund(
        uint256 initialSupplyPerToken,
        string tokenName,
        string tokenSymbol,
        uint256[] initialTokenPricesFinney
        ) {

        for (uint16 i=0; i<initialTokenPricesFinney.length; ++i) {
          balance[i][this] = initialSupplyPerToken;
          tokenPrices[i] = ConvertLib.finneyToWei(initialTokenPricesFinney[i]);
          totalSupply += initialSupplyPerToken;
        }

        owner = msg.sender;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function balanceOf(address _owner) constant returns (uint256 b) {
        for (uint256 i=0; i<3; ++i) {
            b += balance[uint16(i)][_owner];
        }
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

        n = 1;

        if (balance[tokenType][this] < n) { throw; }
        balance[tokenType][this] -= n;
        balance[tokenType][msg.sender] += n;
        soldPremiums[tokenType] += n;

        Transfer(this, msg.sender, n);

    }

    function transferForClaim(uint256 claim, uint16 claimType, address claimer, address beneficiaryAddress) onlyOwner {
        uint256 delta = checkFundBalance(getBalance()) - claim;
        if (delta < 0) {
            solveFundBalance(delta);
            throw; // Cannot pay for claims rn, but asked for money to investment fund. Money will be available on next block.
        }

        uint16 n = 1;

        if (balance[claimType][claimer] > 0) {
            balance[claimType][claimer] -= n;
            balance[claimType][this] += n;

        } else {
            throw;
        }

        if (!beneficiaryAddress.send(delta)) {
            throw;
        } else {
            Transfer(msg.sender, this, n);
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

    function addTokenType(uint256 newTokenPriceFinney, uint256 mintAmount) onlyOwner {
        tokenTypes += 1;
        tokenPrices[tokenTypes] = ConvertLib.finneyToWei(newTokenPriceFinney);
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
