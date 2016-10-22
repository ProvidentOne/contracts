import "./Logger.sol";

contract Owned is Logger {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) { throw; }
        else _
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}
