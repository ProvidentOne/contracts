pragma solidity ^0.4.3;

import "services/InsuranceService.sol";
import "services/InvestmentService.sol";
import "helpers/Owned.sol";
import "helpers/Managed.sol";

contract InsuranceFund is Manager {
  bool isBootstraped;

  function InsuranceFund() {
    owner = msg.sender;
    isBootstraped = false;
  }

  function good() returns (uint16){
    if (isBootstraped) {
      return 508;
    } else {
      return 12;
    }
  }

  function bootstrapInsurance() onlyOwner {
    if (isBootstraped) {
      throw;
    }

    InsurancePersistance insuranceDB = new InsurancePersistance();
    addPersistance(address(insuranceDB));

    InsuranceService insuranceService = new InsuranceService();
    insuranceDB.assignPermission(address(insuranceService), Managed.PermissionLevel.Write);
    insuranceService.setInsurancePlans(getInitialInsurancePrices(3));

    addService(address(insuranceService));
    addService(address(createInvestmentService()));

    isBootstraped = true;
  }

  function getInitialInsurancePrices(uint16 k) constant returns (uint256[]) {
    uint256[] memory prices = new uint256[](k);
    for (uint16 i=0; i<k; i++) {
      prices[i] = uint256(i) * 1 ether;
    }
    return prices;
  }

  function createInvestmentService() returns (InvestmentService) {
    return new InvestmentService("InvFund", "INV", 100000, 1 ether, 100, 20);
  }
}
