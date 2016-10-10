import "helpers/Owned.sol";
import "tokens/StandardToken.sol";

contract InvestmentFund is Owned, StandardToken {
    string public standard = 'InvestmentToken 0.1';
    string public name;
    string public symbol;
    address public insuranceFund;
    uint8 public decimals;

    uint8 public newTokenPct; // Expressed in % since you cannot express not whole numbers in solidity.
    uint8 public holderTokensPct;

    bool private mintingAllowed;

    uint256 public tokenSellPrice;

    mapping (address => uint256) public dividends;
    event Dividends(uint perToken);
    event TokenOffering(uint tokenAmount, uint tokenPrice);

    function InvestmentFund(
      string tokenName,
      string tokenSymbol,
      uint256 initialSupply,
      uint256 initialTokenPrice,
      address insuranceFundAddress,
      uint8 tokensIssuedPerDividendPct,
      uint8 tokensForHolderPct
      ) {

      owner = msg.sender;
      name = tokenName;
      symbol = tokenSymbol;
      insuranceFund = insuranceFundAddress;
      tokenSellPrice = initialTokenPrice;

      newTokenPct = tokensIssuedPerDividendPct;
      holderTokensPct = tokensForHolderPct;

      mintingAllowed = true;
      mintTokens(initialSupply);
    }

    function mintTokens(uint256 newTokens) {
      if (mintingAllowed) {
        mintingAllowed = false;
      } else {
        throw;
      }

      uint256 tokensForHolder = (newTokens * holderTokensPct) / 100;
      if (tokensForHolder > newTokens) { // wtf
        throw;
      }

      totalSupply += newTokens;

      balances[this] += newTokens - tokensForHolder;
      balances[owner] += tokensForHolder;
      addIfNewHolder(this);
      addIfNewHolder(owner);

      TokenOffering(availableTokens(), tokenSellPrice);
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

    function sendProfitsToInvestors() returns (bool) {
      if (msg.sender != insuranceFund && msg.sender != owner) { // Keep owner for testing purposes. Should be removed ASAP.
        throw; // Don't allow cash injections by other entities other than the insurance fund. Can complicate things.
      }

      uint256 dividendPerToken = msg.value / (totalSupply - balances[this]); // Tokens held by contract do not participate in dividends
      for (uint i = 0; i<lastIndex; ++i) {
        address holder = tokenHolders[i];
        if (holder != address(this)) {
          dividends[holder] += balances[holder] * dividendPerToken;
        }
      }
      Dividends(dividendPerToken);

      if (msg.sender == insuranceFund) {
        mintingAllowed = true;
        mintTokens(totalSupply * newTokenPct / 100);
      }

      return true;
    }

    function withdraw() {
      bool success = msg.sender.call.value(dividends[msg.sender])();
      dividends[msg.sender] = 0;
      if (!success) { throw; }
    }

    function changeTokenSellPrice(uint256 newPrice) onlyOwner {
      tokenSellPrice = newPrice;
    }

    function() {
      throw;
    }
}
