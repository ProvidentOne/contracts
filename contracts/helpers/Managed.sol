pragma solidity ^0.4.3;

import "./Manager.sol";

contract Managed {
    address public manager;
    bytes32 public identifier;

    function Managed(string _identifier) {
      manager = msg.sender;
      identifier = sha3(_identifier);
    }

    function addressFor(string _id) returns (address) {
      return Manager(manager).addressForHash(sha3(_id));
    }

    function destroy() onlyManager {
      selfdestruct(manager);
    }

    modifier onlyManager {
      if (msg.sender != manager) { throw; }
      else
        _;
    }
}
