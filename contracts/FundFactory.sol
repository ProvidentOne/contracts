import "./InsuranceFund.sol";
import "./InvestmentFund.sol";
import "./helpers/Owned.sol";

contract FundFactory is Owned {
  address public insuranceFund;
  address public investmentFund;

  function FundFactory() {
    owner = msg.sender;
  }

  function deployContracts() onlyOwner {
    InsuranceFund insuranceFundContract = createInsuranceFund();
    insuranceFund = address(insuranceFundContract);
    investmentFund = address(createInvestmentFund(insuranceFund));
    insuranceFundContract.setInvestmentFundAddress(investmentFund);
    insuranceFundContract.transferOwnership(msg.sender);
  }

  function createInsuranceFund() returns (InsuranceFund) {
    return new InsuranceFund("InsFund", "INS", mockPricesInsurance());
  }

  function createInvestmentFund(address insuranceFund) returns (address) {
    InvestmentFund investmentFund = new InvestmentFund("InvFund", "INV", 100000, 1 ether, insuranceFund, 100, 20);
    investmentFund.transferOwnership(msg.sender);
    return investmentFund;
  }

  function mockPricesInsurance() returns (uint256[]) {
    uint256[] memory prices = new uint256[](3);
    prices[0] = 1 ether;
    prices[1] = 2 ether;
    prices[2] = 3 ether;
    return prices;
  }
}
