pragma solidity ^0.4.4;

import "../helpers/Managed.sol";

contract InvestmentPersistance is Managed('InvestmentDB') {
  function InvestmentPersistance() {}

  uint256 public totalSupply;
  uint256 public tokenPrice;
  mapping (address => uint256) public dividends;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  mapping (uint256 => address) public tokenHolders;
  uint256 private holderIndex;
  mapping (address => bool) private isHolder;

  function setTokenSupply(uint256 newTotalSupply) requiresPermission(PermissionLevel.Write) {
    totalSupply = newTotalSupply;
  }

  function setTokenPrice(uint256 newTokenPrice) requiresPermission(PermissionLevel.Write) {
    tokenPrice = newTokenPrice;
  }

  function operateBalance(address holder, int256 diff) requiresPermission(PermissionLevel.Write) {
    // Some logic is here in persistance but it's only here becuase of Solidity data structures limitations.
    if (!isHolder[holder]) {
      addTokenHolder(holder);
    }
    // Avoid sign overloading
    var newBalance = int256(balances[holder]) + diff;
    if (newBalance < 0) { throw; }
    balances[holder] = uint256(newBalance);
  }

  function operateDividend(address holder, int256 diff) requiresPermission(PermissionLevel.Write) {
    var newDividend = int256(dividends[holder]) + diff;
    if (newDividend < 0) { throw; }
    dividends[holder] = uint256(newDividend);
  }

  function operateAllowance(address from, address to, int256 diff) requiresPermission(PermissionLevel.Write) {
    var newAllowance = int256(allowed[from][to]) + diff;
    if (newAllowance < 0) { throw; }
    allowed[from][to] = uint256(newAllowance);
  }

  function addTokenHolder(address holder) private {
    isHolder[holder] = true;
    tokenHolders[holderIndex] = holder;
    holderIndex += 1;
  }

  function () { throw; }
}
