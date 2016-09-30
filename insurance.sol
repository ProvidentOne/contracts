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
    uint16 public tokenTypes;
    uint256 public initialSupply;
    
    InvestmentFund public investmentFund;
    
    mapping (uint16 => uint256) public supply;
    
    mapping (uint16 => uint256) public tokenPrices;
    mapping (uint16 => mapping (address => uint256)) public balance;
    
    function InsuranceFund(
        uint256 initialSupplyPerToken,
        string tokenName,
        string tokenSymbol,
        uint256[] initialTokenPrices
        ) {
          
        uint16 nTokenTypes = uint16(initialTokenPrices.length);
        for (uint16 i=0; i<nTokenTypes; ++i) {
          balance[i][msg.sender] = initialSupplyPerToken;
          tokenPrices[i] = initialTokenPrices[i];
        }
        
        tokenTypes = nTokenTypes;
        owner = msg.sender;                     
        name = tokenName;                                   
        symbol = tokenSymbol;                              
    }
    
    function setInvestmentFundAddress(address newAddress) onlyOwner {
        if (newAddress == 0) { throw; } 
        investmentFund = InvestmentFund(newAddress);
    }
    
    function buyInsuranceToken(uint16 tokenType) {
        uint256 amount; // TODO: Get trans amount
        if (amount < tokenPrices[tokenType]) {
           throw; 
        }
        
        uint16 n = 1; // Only one token at the time
        
        if (balance[tokenType][owner] < n) { throw; }
        balance[tokenType][owner] -= n;
        balance[tokenType][msg.sender] += n;
        supply[tokenType] += n;
        solveFundBalance(checkFundBalance(getBalance()));
    }
    
    function transferForClaim(uint256 claim, address beneficiaryAddress) onlyOwner {
        uint256 delta = checkFundBalance(getBalance()) - claim;
        if (delta < 0) {
            solveFundBalance(delta);
            throw; // Cannot pay for claims rn, but asked for money to investment fund. Money will be available on next block.
        }
        
        beneficiaryAddress.send(delta);
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
    
    function addTokenType(uint256 newTokenPrice) onlyOwner {
        tokenTypes += 1;
        tokenPrices[tokenTypes] = newTokenPrice;
        balance[tokenTypes][owner] = initialSupply;
    } 
    
    function mintToken(uint256 mintedAmount) onlyOwner {
        for (uint16 i=0; i<tokenTypes; ++i) {
            balance[i][owner] += mintedAmount;
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

