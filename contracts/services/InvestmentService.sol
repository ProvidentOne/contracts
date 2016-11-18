pragma solidity ^0.4.4;

import "../tokens/Token.sol";
import "../helpers/Managed.sol";
import "../persistance/InvestmentPersistance.sol";

contract InvestmentService is Managed('InvestmentService'), Token {
  string constant public standard = 'InsuranceToken 0.1';
  string constant public name = 'InsuranceToken';
  string constant public symbol = 'INS';
  uint8 constant public decimals = 0;

  // Expressed in % since you cannot express floats numbers in solidity.
  uint8 constant public holderTokensPct = 10;
  bool public mintingAllowed;

  event Dividends(uint perToken);
  event TokenOffering(uint tokenAmount, uint tokenPrice);

  function InvestmentService() {
    mintingAllowed = false;
  }

  function bootstrapInvestmentService(uint256 initialSupply, uint256 initialTokenPrice) requiresPermission(PermissionLevel.Manager) {
    mintingAllowed = true;
    persistance().setTokenPrice(initialTokenPrice);
    mintTokens(initialSupply);
  }

  function totalSupply() constant returns (uint256) {
    return persistance().tokenSupply();
  }

  function availableTokenSupply() constant returns (uint256) {
    return persistance.balances(manager);
  }

  function tokenPrice() constant returns (uint256) {
    return persistance().tokenPrice();
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

    persistance.setTokenSupply(persistance.totalSupply() + newTokens);
    persistance.operateBalance(manager, newTokens - tokensForHolder);
    persistance.operateBalance(Manager(manager).owner(), tokensForHolder);

    TokenOffering(availableTokenSupply(), tokenPrice());
  }

  function assingTokens(address holder, uint256 value) requiresPermission(PermissionLevel.Manager) {
    uint256 tokenAmount = value / tokenPrice();
    if (persistance().balances(manager) >= tokenAmount && persistance().balances(holder) + tokenAmount > persistance().balances(holder))  {
      persistance().operateBalance(holder, tokenAmount);
      persistance().operateBalance(manager, -1 * tokenAmount);

      Transfer(this, holder, tokenAmount);
    } else {
      throw;
    }
  }

  function sendProfitsToInvestors(uint256 profits) payable requiresPermission(PermissionLevel.Manager) returns (bool) {
    uint256 circulatingTokens = totalSupply() - persistance.getBalance(manager);
    uint256 dividendPerToken = profits / circulatingTokens; // Tokens held by contract do not participate in dividends

    uint256 holderIndex = persistance().holderIndex();
    for (uint i = 0; i<holderIndex; ++i) {
      address holder = persistance().tokenHolders(i);
      if (holder != manager) {
        persistance().operateDividend(persistance().balances(holder) * dividendPerToken);
      }
    }
    Dividends(dividendPerToken);

    mintingAllowed = true;
    // mintTokens(totalSupply * newTokenPct / 100);

    return true;
  }

  function transfer(address _to, uint256 _value) returns (bool success) {
      //Default assumes totalSupply can't be over max (2^256 - 1).
      //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
      //Replace the if with this one instead.
      //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
      if (persistance().balance(msg.sender) >= _value && _value > 0) {
          persistance().operateBalance(msg.sender, -1 * _value);
          persistance().operateBalance(_to, _value);

          Transfer(msg.sender, _to, _value);
          return true;
      } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      //same as above. Replace this line with the following if you want to protect against wrapping uints.
      //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
      if (persistance().balance(_from) >= _value && persistance().allowance(_from)(msg.sender) >= _value && _value > 0) {
          persistance().operateBalance(_to, _value);
          persistance().operateBalance(_from, -1 * _value);
          persistance().operateAllowance(_from, msg.sender, -1 * _value);

          Transfer(_from, _to, _value);
          return true;
      } else { return false; }
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
      return persistance().balances(_owner);
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
      persistance().operateAllowance(msg.sender, _spender, _value);
      Approval(msg.sender, _spender, _value);
      return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return persistance().allowed(_owner)(_spender);
  }

  function persistance() returns (InvestmentPersistance) {
    return InvestmentPersistance(addressFor('InvestmentDB'));
  }

  function() {
    throw;
  }
}
