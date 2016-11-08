pragma solidity ^0.4.3;
contract Manager {
  function addressForHash(bytes32) constant returns (address);
  function addressFor(string) constant returns (address);
}
