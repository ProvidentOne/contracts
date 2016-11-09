pragma solidity ^0.4.4;

import "./Provident.sol";

import "services/InsuranceService.sol";
import "services/InvestmentService.sol";

import "persistance/AccountingPersistance.sol";

import "helpers/Owned.sol";
import "helpers/Managed.sol";

contract InsuranceFund is Manager { // is Provident (Solidity compiler bug)
  bool isBootstraped;

  function InsuranceFund() {
    owner = msg.sender;
    isBootstraped = false;
  }

  function getNumberOfInsurancePlans() constant public returns (uint16) {
    return insurance().getPlanCount();
  }

  function getInsurancePlanPrice(uint16 plan) constant public returns (uint256) {
    return insurance().getPlanPrice(plan);
  }

  function buyInsurancePlan(uint16 plan) payable public {
    if (!insurance().buyInsurancePlanFor(msg.sender, msg.value, plan)) {
      throw; // If it failed, reverse transaction returning funds.
    }
    accounting().saveTransaction(AccountingPersistance.TransactionDirection.Incoming, msg.value, msg.sender, this, 'premium bought');
  }

  function insurance() private returns (InsuranceService) {
    return InsuranceService(addressFor('InsuranceService'));
  }

  function accounting() private returns (AccountingPersistance) {
    return AccountingPersistance(addressFor('AccountingDB'));
  }

  // Bootstrap

  function bootstrapInsurance() onlyOwner {
    if (isBootstraped) {
      throw;
    }

    InsurancePersistance insuranceDB = new InsurancePersistance();
    addPersistance(address(insuranceDB));
    AccountingPersistance accountingDB = new AccoutingPersistance();
    addPersistance(address(accountingDB));

    InsuranceService insuranceService = new InsuranceService();
    insuranceDB.assignPermission(address(insuranceService), Managed.PermissionLevel.Write);
    insuranceService.setInitialPlans();

    addService(address(insuranceService));
    addService(address(createInvestmentService()));

    isBootstraped = true;
  }

  function createInvestmentService() returns (InvestmentService) {
    return new InvestmentService("InvFund", "INV", 100000, 1 ether, 100, 20);
  }
}
