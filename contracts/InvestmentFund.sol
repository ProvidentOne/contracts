import "helpers/Owned.sol";
import "tokens/StandardToken.sol";

contract InvestmentFund is Owned, StandardToken {
    string public standard = 'InvestmentToken 0.1';
    string public name;
    string public symbol;
    address public insuranceFund;

    mapping (address => uint256) public dividends;

    function InvestmentFund(
      uint256 initialSupply,
      string tokenName,
      string tokenSymbol,
      uint256 initialTokenPrice,
      address insuranceFundAddress
      ) {

      owner = msg.sender;
      name = tokenName;
      symbol = tokenSymbol;
      insuranceFund = insuranceFundAddress;
      totalSupply = initialSupply;
      balances[this] = initialSupply;
      addIfNewHolder(this);
    }

    function sendProfitsToHolders() returns (bool) {
      uint256 dividendPerToken = msg.value / totalSupply;
      for (uint i = 0; i<lastIndex; ++i) {
        address holder = tokenHolders[i];
        dividends[holder] += balances[holder] * dividendPerToken;
      }
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
}
