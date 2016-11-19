pragma solidity ^0.4.4;

import "./Provident.sol";

import "services/InsuranceService.sol";
import "services/InvestmentService.sol";

import "persistance/AccountingPersistance.sol";

import "helpers/Managed.sol";

contract InsuranceFund is Provident, Manager {
  bool isBootstraped;

  function InsuranceFund() {
    owner = msg.sender;
    isBootstraped = false;
    bootstrapPersistance();
  }

  event TokenAddressChanged(address newTokenAddress);

  function getNumberOfInsurancePlans() constant public returns (uint16) {
    return insurance().getPlanCount();
  }

  function getInsurancePlanPrice(uint16 plan) constant public returns (uint256) {
    return insurance().getPlanPrice(plan);
  }

  function getInsuredProfile() constant returns (int16 plan, uint256 startDate, uint256 finalDate) {
    var (p,s,f,) = insurance().getInsuranceProfile(msg.sender);
    return (p,s,f);
  }

  function buyInsurancePlan(uint16 plan) payable public {
    if (!insurance().buyInsurancePlanFor(msg.sender, msg.value, plan)) {
      throw; // If it failed, reverse transaction returning funds.
    }
    accounting().saveTransaction(AccountingPersistance.TransactionDirection.Incoming, msg.value, msg.sender, this, 'premium bought', false);
  }

  function createClaim(uint16 claimType, string evidence, address beneficiary) returns (bool) {
    return insurance().createClaim(msg.sender, claimType, evidence, beneficiary);
  }

  function getTokenAddress() constant returns (address) {
    return address(investment());
  }

  function getCurrentTokenOffer() constant returns (uint256 price, uint256 availableTokens) {
    return (investment().tokenPrice(), investment().availableTokenSupply());
  }

  function buyTokens() payable public {
    if (!investment().buyTokens(msg.sender, msg.value)) {
      throw;
    }
    accounting().saveTransaction(AccountingPersistance.TransactionDirection.Incoming, msg.value, msg.sender, this, 'tokens bought', false);
  }

  function withdrawDividends() public {
    investment().withdrawDividendsForHolder(msg.sender);
  }

  // Private

  modifier onlyWaivedServices {
    if (msg.sender == addressFor('InsuranceService') || msg.sender == addressFor('InvestmentService')) {
      _;
    } else {
      throw;
    }
  }

  function sendFunds(address recipient, uint256 amount, string concept, bool isDividend) onlyWaivedServices returns (bool) {
    accounting().saveTransaction(AccountingPersistance.TransactionDirection.Outgoing, amount, this, recipient, concept, isDividend);
    if (!recipient.send(amount)) {
      throw;
    }
    return true;
  }

  function insurance() private returns (InsuranceService) {
    return InsuranceService(addressFor('InsuranceService'));
  }

  function investment() private returns (InvestmentService) {
    return InvestmentService(addressFor('InvestmentService'));
  }

  function accounting() private returns (AccountingPersistance) {
    return AccountingPersistance(addressFor('AccountingDB'));
  }

  // Bootstrap
  function bootstrapPersistance() onlyOwner {
    if (isBootstraped) {
      throw;
    }
    InsurancePersistance insuranceDB = new InsurancePersistance();
    addPersistance(address(insuranceDB));
    AccountingPersistance accountingDB = new AccountingPersistance();
    addPersistance(address(accountingDB));
    InvestmentPersistance investmentDB = new InvestmentPersistance();
    addPersistance(address(investmentDB));
    isBootstraped = true;
  }

  function setInsuranceService(address insurance, bool setInitialPlans) onlyOwner {
    InsuranceService insuranceService = InsuranceService(insurance);
    InsurancePersistance(addressFor('InsuranceDB')).assignPermission(insurance, Managed.PermissionLevel.Write);
    addService(insurance);

    if (setInitialPlans) {
      insuranceService.setInitialPlans();
    }
  }

  function setInvestmentService(address investment, bool bootstrap) onlyOwner {
    InvestmentPersistance(addressFor('InvestmentDB')).assignPermission(investment, Managed.PermissionLevel.Write);
    AccountingPersistance(addressFor('AccountingDB')).assignPermission(investment, Managed.PermissionLevel.Write);
    addService(investment);

    if (bootstrap) {
      InvestmentService(investment).bootstrapInvestmentService(1000000, 1 ether);
    }

    TokenAddressChanged(investment);
  }
}
