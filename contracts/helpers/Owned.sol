pragma solidity ^0.4.4;

contract Owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) { throw; }
        else
          _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}
