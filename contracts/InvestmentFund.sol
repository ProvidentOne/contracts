import "helpers/Owned.sol";
import "tokens/StandardToken.sol";

contract InvestmentFund is Owned, StandardToken {
    string public standard = 'InvestmentToken 0.1';
    string public name;
    string public symbol;
    address public insuranceFund;
    uint8 public decimals;

    uint256 public tokenSellPrice;

    mapping (address => uint256) public dividends;
    event Dividends(uint perToken);

    function InvestmentFund(
      string tokenName,
      string tokenSymbol,
      uint256 initialSupply,
      uint256 initialTokenPrice,
      address insuranceFundAddress
      ) {

      owner = msg.sender;
      name = tokenName;
      symbol = tokenSymbol;
      insuranceFund = insuranceFundAddress;
      totalSupply = initialSupply;
      balances[this] = initialSupply;
      tokenSellPrice = initialTokenPrice;

      addIfNewHolder(this);
    }

    function availableTokens() constant returns (uint256) {
      return balances[this];
    }

    function buyTokens() {
      uint256 tokenAmount = msg.value / tokenSellPrice;
      if (balances[this] >= tokenAmount && balances[msg.sender] + tokenAmount > balances[msg.sender])  {
        balances[msg.sender] += tokenAmount;
        balances[this] -= tokenAmount;
        Transfer(this, msg.sender, tokenAmount);
        addIfNewHolder(msg.sender);
        if (!insuranceFund.call.value(msg.value)()) {
          throw;
        }
      } else {
        throw;
      }
    }

    function sendProfitsToHolders() returns (bool) {
      uint256 dividendPerToken = msg.value / totalSupply;
      for (uint i = 0; i<lastIndex; ++i) {
        address holder = tokenHolders[i];
        dividends[holder] += balances[holder] * dividendPerToken;
      }
      Dividends(dividendPerToken);
      return true;
    }

    function withdraw() {
      bool success = msg.sender.call.value(dividends[msg.sender])();
      dividends[msg.sender] = 0;
      if (!success) { throw; }
    }

    function mintToken(uint256 mintAmount) onlyOwner {
      balances[msg.sender] += mintAmount;
      totalSupply += mintAmount;
      addIfNewHolder(msg.sender);
    }

    function() {
      throw;
    }
}
