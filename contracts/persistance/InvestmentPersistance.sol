pragma solidity ^0.4.4;

import "../helpers/Managed.sol";

contract InsurancePersistance is Managed('InsuranceDB') {
  function InsurancePersistance() {}

  uint256 public totalSupply;
  uint256 public tokenPrice;
  mapping (address => uint256) public dividends;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  mapping (uint256 => address) public tokenHolders;
  uint256 internal lastIndex

  function () { throw; }
}
