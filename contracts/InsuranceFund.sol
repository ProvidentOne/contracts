pragma solidity ^0.4.3;

import "./Provident.sol";

import "services/InsuranceService.sol";
import "services/InvestmentService.sol";

import "helpers/Owned.sol";
import "helpers/Managed.sol";


contract InsuranceFund is Manager { // is Provident (Solidity compiler bug)
  bool isBootstraped;

  function InsuranceFund() {
    owner = msg.sender;
    isBootstraped = false;
  }

  function getNumberOfInsurancePlans() constant public returns (uint16) {
    return InsuranceService(addressFor('InsuranceService')).getPlanCount();
  }

  function getInsurancePlanPrice(uint16 plan) constant public returns (uint256) {
    return InsuranceService(addressFor('InsuranceService')).getPlanPrice(plan);
  }

  // Bootstrap

  function bootstrapInsurance() onlyOwner {
    if (isBootstraped) {
      throw;
    }

    InsurancePersistance insuranceDB = new InsurancePersistance();
    addPersistance(address(insuranceDB));

    InsuranceService insuranceService = new InsuranceService();
    insuranceDB.assignPermission(address(insuranceService), Managed.PermissionLevel.Write);
    insuranceService.setInsurancePlans(insuranceService.getInitialInsurancePrices(3));

    addService(address(insuranceService));
    addService(address(createInvestmentService()));

    isBootstraped = true;
  }

  function createInvestmentService() returns (InvestmentService) {
    return new InvestmentService("InvFund", "INV", 100000, 1 ether, 100, 20);
  }
}
