pragma solidity ^0.4.4;

import "../Claim.sol";

import "../helpers/Managed.sol";
import "../tokens/StandardToken.sol";

contract InvestmentService is Managed("Investment"), StandardToken {
    string public standard = 'InvestmentToken 0.1';
    string public name;
    string public symbol;

    uint8 public decimals;

    uint8 public newTokenPct; // Expressed in % since you cannot express not whole numbers in solidity.
    uint8 public holderTokensPct;

    bool private mintingAllowed;

    uint256 public tokenSellPrice;

    mapping (address => uint256) public dividends;

    event Dividends(uint perToken);
    event TokenOffering(uint tokenAmount, uint tokenPrice);

    function InvestmentService(
      string tokenName,
      string tokenSymbol,
      uint256 initialSupply,
      uint256 initialTokenPrice,
      uint8 tokensIssuedPerDividendPct,
      uint8 tokensForHolderPct
      ) {

      name = tokenName;
      symbol = tokenSymbol;

      tokenSellPrice = initialTokenPrice;

      newTokenPct = tokensIssuedPerDividendPct;
      holderTokensPct = tokensForHolderPct;

      mintingAllowed = true;
      mintTokens(initialSupply);
    }

    // TODO: Add token mint allowance quotas.
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
      balances[manager] += tokensForHolder;
      addIfNewHolder(this);
      addIfNewHolder(manager);

      TokenOffering(availableTokens(), tokenSellPrice);
    }

    function availableTokens() constant returns (uint256) {
      return balances[this];
    }

    function buyTokens() payable {
      uint256 tokenAmount = msg.value / tokenSellPrice;
      if (balances[this] >= tokenAmount && balances[msg.sender] + tokenAmount > balances[msg.sender])  {
        balances[msg.sender] += tokenAmount;
        balances[this] -= tokenAmount;
        Transfer(this, msg.sender, tokenAmount);
        addIfNewHolder(msg.sender);
        if (!addressFor("Insurance").call.value(msg.value)()) {
          throw;
        }
      } else {
        throw;
      }
    }

    function sendProfitsToInvestors() payable requiresPermission(PermissionLevel.Manager) returns (bool) {
      uint256 dividendPerToken = msg.value / (totalSupply - balances[this]); // Tokens held by contract do not participate in dividends
      for (uint i = 0; i<lastIndex; ++i) {
        address holder = tokenHolders[i];
        if (holder != address(this)) {
          dividends[holder] += balances[holder] * dividendPerToken;
        }
      }
      Dividends(dividendPerToken);

      mintingAllowed = true;
      mintTokens(totalSupply * newTokenPct / 100);

      return true;
    }

    function withdraw() {
      bool success = msg.sender.call.value(dividends[msg.sender])();
      dividends[msg.sender] = 0;
      if (!success) { throw; }
    }

    function changeTokenSellPrice(uint256 newPrice) requiresPermission(PermissionLevel.Manager) {
      tokenSellPrice = newPrice;
    }

    function() {
      throw;
    }
}
