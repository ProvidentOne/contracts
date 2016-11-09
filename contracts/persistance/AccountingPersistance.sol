pragma solidity ^0.4.4;

import "../helpers/Managed.sol";

contract AccountingPersistance is Managed('AccountingDB') {
  function AccountingPersistance() {}

  enum TransactionDirection {
    Incoming,
    Outgoing
  }

  struct Transaction {
    TransactionDirection direction;
    uint256 amount;
    address from;
    address to;
    string concept;

    uint256 timestamp;
  }

  mapping (uint256 => Transaction) public transactions;
  uint256 public lastTransaction;

  function saveTransaction(TransactionDirection direction, uint256 amount, address from, address to, string concept, bool isDividend) {
    transactions[lastTransaction] = Transaction({direction: direction, amount: amount, from: from, to: to, concept: concept, timestamp: now});
    lastTransaction += 1;

    if (!isDividend){
      if (direction == TransactionDirection.Incoming) {
        accountingPeriods[currentPeriod].premiums += amount;
      }
      if (direction == TransactionDirection.Outgoing) {
        accountingPeriods[currentPeriod].claims += amount;
      }
    } else {
      accountingPeriods[currentPeriod].dividends += amount;
    }
  }

  struct AccountingPeriod {
    uint256 premiums;
    uint256 claims;
    uint256 dividends;
    uint256 pastLosses;
    bool closed;
  }

  mapping (uint256 => AccountingPeriod) public accountingPeriods;
  uint256 public currentPeriod;

  function startNewAccoutingPeriod() {
    currentPeriod += 1;
    var lastPeriod = accountingPeriods[currentPeriod - 1];
    var lastProfit = int256(lastPeriod.premiums) - int256(lastPeriod.claims) - int256(lastPeriod.pastLosses);
    if (lastProfit < 0) {
      accountingPeriods[currentPeriod].pastLosses = uint256(-lastProfit);
    }
    accountingPeriods[currentPeriod - 1].closed = true;
  }

  function () { throw; }
}
