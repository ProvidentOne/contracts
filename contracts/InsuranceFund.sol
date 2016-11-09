pragma solidity ^0.4.4;

import "./Provident.sol";

import "services/InsuranceService.sol";
import "services/InvestmentService.sol";

import "persistance/AccountingPersistance.sol";
import "persistance/InsurancePersistance.sol";

import "helpers/Managed.sol";

contract InsuranceFund is Manager { // is Provident (Solidity compiler bug)
  bool isBootstraped;

  function InsuranceFund() {
    owner = msg.sender;
    isBootstraped = false;
    bootstrapPersistance();
  }

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

  function insurance() private returns (InsuranceService) {
    return InsuranceService(addressFor('InsuranceService'));
  }

  function accounting() private returns (AccountingPersistance) {
    return AccountingPersistance(addressFor('AccountingDB'));
  }

  // Bootstrap

  function bootstrapPersistance() {
    if (isBootstraped) {
      throw;
    }
    InsurancePersistance insuranceDB = new InsurancePersistance();
    addPersistance(address(insuranceDB));
    AccountingPersistance accountingDB = new AccountingPersistance();
    addPersistance(address(accountingDB));
    isBootstraped = true;
  }

  function setInsuranceService(address insurance, bool setInitialPlans) onlyOwner {
    InsuranceService insuranceService = InsuranceService(insurance);
    InsurancePersistance(addressFor('InsuranceDB')).assignPermission(address(insuranceService), Managed.PermissionLevel.Write);
    addService(address(insuranceService));

    if (setInitialPlans) {
      insuranceService.setInitialPlans();
    }

    addService(address(createInvestmentService()));
  }

  function createInvestmentService() returns (InvestmentService) {
    return new InvestmentService("InvFund", "INV", 100000, 1 ether, 100, 20);
  }
}
