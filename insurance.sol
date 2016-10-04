pragma solidity ^0.4.0;

contract Owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract InsuranceFund is Owned {
    string public standard = 'InsuranceToken 0.1';
    string public name;
    string public symbol;
    uint16 public tokenTypes = 3;
    uint256 public initialSupply;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    InvestmentFund public investmentFund;
    
    mapping (uint16 => uint256) public supply;
    
    mapping (uint16 => uint256) public tokenPrices;
    mapping (uint16 => mapping (address => uint256)) public balance;
    
    function InsuranceFund(
        uint256 initialSupplyPerToken,
        string tokenName,
        string tokenSymbol,
        uint256[] initialTokenPricesFinney
        ) {
          
        for (uint16 i=0; i<initialTokenPricesFinney.length; ++i) {
          balance[i][this] = initialSupplyPerToken;
          tokenPrices[i] = initialTokenPricesFinney[i] * (1 finney / 1 wei);
        }
        
        owner = msg.sender;                     
        name = tokenName;                                   
        symbol = tokenSymbol;                              
    }
    
    function balanceOf(address _owner) constant returns (uint256 b) {
        for (uint256 i=0; i<3; ++i) {
            b += balance[uint16(i)][_owner];
        }
    }
    
    function setInvestmentFundAddress(address newAddress) onlyOwner {
        if (newAddress == 0) { throw; } 
        investmentFund = InvestmentFund(newAddress);
    }
    
    function buyInsuranceToken(uint16 tokenType) payable returns (uint16 n) {
    
        uint256 delta = msg.value - tokenPrices[tokenType];
        if (delta < 0) {
           throw; 
        }
        
        if (delta > 0 && !msg.sender.send(delta)) {  // recursion attacks
            throw;
        }
       
        n = 1;
        
        if (balance[tokenType][this] < n) { throw; }
        balance[tokenType][this] -= n;
        balance[tokenType][msg.sender] += n;
        supply[tokenType] += n;
        
        Transfer(this, msg.sender, n);

    }
    
    function transferForClaim(uint256 claim, uint16 claimType, address claimer, address beneficiaryAddress) onlyOwner {
        uint256 delta = checkFundBalance(getBalance()) - claim;
        if (delta < 0) {
            solveFundBalance(delta);
            throw; // Cannot pay for claims rn, but asked for money to investment fund. Money will be available on next block.
        }
        
        uint16 n = 1;
        
        if (balance[claimType][claimer] > 0) {
            balance[claimType][claimer] -= n;
            balance[claimType][this] += n;
            
        } else {
            throw;
        }
        
        if (!beneficiaryAddress.send(delta)) {
            throw;
        } else {
            Transfer(msg.sender, this, n);
        }
    }
    
    function calculatePremiums() returns (uint256 premiums){
        for (uint256 i=0; i<tokenTypes; ++i) {
            premiums += supply[uint16(i)];
        }
    }
    
    function getBalance() returns (uint256) {
        address insuranceFund = this;
        return insuranceFund.balance;
    }
    
    function equilibrateFunds() { 
        solveFundBalance(checkFundBalance(getBalance()));
    }    
    
    function checkFundBalance(uint256 balance) private returns (uint256 delta){
        delta = balance - calculatePremiums();
    }
    
    function solveFundBalance(uint256 delta) private {
        if (delta > 0) {
            investmentFund.profits.value(delta)();
        } else {
            investmentFund.needs(-delta);
        }
    }

    function sendInvestmentInjection() payable {
        
    }
    
    function addTokenType(uint256 newTokenPriceFinney) onlyOwner {
        tokenTypes += 1;
        tokenPrices[tokenTypes] = newTokenPriceFinney * (1 finney / 1 wei);
        balance[tokenTypes][this] = initialSupply;
    } 
    
    function mintToken(uint256 mintedAmount) onlyOwner {
        for (uint16 i=0; i<tokenTypes; ++i) {
            balance[i][this] += mintedAmount;
            supply[i] += mintedAmount;
        }
    }
}

contract InvestmentFund is Owned {
    string public standard = 'InvestmentToken 0.1';
    string public name;
    string public symbol;
    
    InsuranceFund public insuranceFund;
    
    function InvestmentFund(
        uint256 initialSupplyPerToken,
        string tokenName,
        string tokenSymbol,
        uint256 initialTokenPrice,
        address insuranceFundAddress
        ) {
        
        owner = msg.sender;                     
        name = tokenName;                                   
        symbol = tokenSymbol;  
        
        insuranceFund = InsuranceFund(insuranceFundAddress);
    }
    
    function profits() payable {
    }
    
    function buyTokens() {
        // TODO
    }
    
    function sellTokens() {
        // TODO
    }
    
    function needs(uint256 needed) {
        if (msg.sender != address(insuranceFund)) { throw; }
        // This is a nice check, but it doesn't allow the case when there isn't enough money to pay for a claim.
        // if (needed != (insuranceFund.getBalance() - insuranceFund.calculatePremiums())) { throw; }
        
        insuranceFund.sendInvestmentInjection.value(needed)();
    }
}

