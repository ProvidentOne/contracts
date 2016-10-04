contract Owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender == owner) _
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}
