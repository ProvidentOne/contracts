pragma solidity ^0.4.3;

import "../helpers/Managed.sol";

contract InsurancePersistance is Managed('InsuranceDB') {
  function InsurancePersistance() {}

  mapping (uint16 => uint256) public planPrices;
  uint16 public planTypes;

  function setInsurancePlans(uint256[] initialPlanPrices) requiresPermission(PermissionLevel.Write) {
    planTypes = 0;
    for (uint16 i=0; i<initialPlanPrices.length; i++) {
      planPrices[i] = initialPlanPrices[i];
      planTypes += 1;
    }
  }

  function getInsurancePlanPrices() constant requiresPermission(PermissionLevel.Read) returns (uint256[]) {
    uint256[] memory prices = new uint256[](planTypes);
    for (uint16 i=0; i<planTypes; i++) {
      prices[i] = planPrices[i];
    }
    return prices;
  }

  struct InsuredProfile {
      uint16 plan;
      uint256 startDate;
      uint256 finalDate;
      address[] claims;
  }
  mapping (address => InsuredProfile) private insuredProfile;

  function () { throw; }
}
