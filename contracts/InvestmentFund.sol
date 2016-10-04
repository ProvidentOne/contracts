import "helpers/Owned.sol";
import "tokens/StandardToken.sol";

contract InvestmentFund is Owned, StandardToken {
    string public standard = 'InvestmentToken 0.1';
    string public name;
    string public symbol;

    address public insuranceFund;

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
        insuranceFund = insuranceFundAddress;
    }

    function profits() {
    }

    function buyTokens() {
        // TODO
    }

    function needs(uint256 needed) {
        if (msg.sender != address(insuranceFund)) { throw; }
        // This is a nice check, but it doesn't allow the case when there isn't enough money to pay for a claim.
        // if (needed != (insuranceFund.getBalance() - insuranceFund.calculatePremiums())) { throw; }
        if (!insuranceFund.send(needed)) {
          throw;
        }
    }
}
