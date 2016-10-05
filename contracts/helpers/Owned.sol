import "./Logger.sol";

contract Owned is Logger {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        Log("Only owner");
        // Log(string(msg.sender));
        if (msg.sender == owner) _
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}
