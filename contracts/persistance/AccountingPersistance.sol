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
  uint256 public lastTransation;

  function saveTransaction(TransactionDirection direction, uint256 amount, address from, address to, string concept) {
    transactions[lastTransation] = Transaction({direction: direction, amount: amount, from: from, to: to, concept: concept, timestamp: now});
    lastTransation += 1;
  }

  function () { throw; }
}
