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
    insuranceFund = createInsuranceFund();
    investmentFund = createInvestmentFund(insuranceFund);
  }

  function createInsuranceFund() returns (address) {
    InsuranceFund insuranceFund = new InsuranceFund("InsFund", "INS", mockPricesInsurance());
    insuranceFund.transferOwnership(msg.sender);
    return address(insuranceFund);
  }

  function createInvestmentFund(address insuranceFund) returns (address) {
    InvestmentFund investmentFund = new InvestmentFund("InvFund", "INV", 100000, 1 ether, insuranceFund, 100, 20);
    investmentFund.transferOwnership(msg.sender);
    return address(investmentFund);
  }

  function mockPricesInsurance() returns (uint256[]) {
    uint256[] memory prices = new uint256[](3);
    prices[0] = 1 ether;
    prices[1] = 2 ether;
    prices[2] = 3 ether;
    return prices;
  }
}
