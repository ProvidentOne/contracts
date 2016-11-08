pragma solidity ^0.4.3;

import "services/InsuranceService.sol";
import "services/InvestmentService.sol";
import "helpers/Owned.sol";
import "helpers/Managed.sol";
import "helpers/Manager.sol";

contract InsuranceFund is Owned, Manager {
  bool isDeployed;

  mapping (bytes32 => address) private services;
  mapping (bytes32 => address) private persistance;

  address public insurance;

  function InsuranceFund() {
    owner = msg.sender;
    isDeployed = false;
  }

  function bootstrapInsurance() onlyOwner {
    if (isDeployed) {
      throw;
    }

    setService(address(createInsuranceService()));
    setService(address(createInvestmentService()));

    isDeployed = true;
  }

  function setService(address newService) {
    Managed service = Managed(newService);
    bytes32 h = service.identifier();
    if (services[h] != 0x0) {
      service.destroy();
    }
    services[h] = newService;
  }

  function addressFor(string identifier) constant returns (address) {
    return addressForHash(sha3(identifier));
  }

  function addressForHash(bytes32 h) constant returns (address) {
    if (services[h] != 0x0) {
      return services[h];
    }

    if (persistance[h] != 0x0) {
      return persistance[h];
    }

    throw;
  }

  function createInsuranceService() returns (InsuranceService) {
    return new InsuranceService(new uint256[](0));
  }

  function createInvestmentService() returns (InvestmentService) {
    return new InvestmentService("InvFund", "INV", 100000, 1 ether, 100, 20);
  }
}
