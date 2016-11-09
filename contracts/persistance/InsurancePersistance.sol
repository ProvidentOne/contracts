pragma solidity ^0.4.4;

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

  struct InsuredProfile {
      uint16 plan;
      uint256 startDate;
      uint256 finalDate;
      uint256 totalSubscribedClaims;
  }
  mapping (address => InsuredProfile) public insuredProfile;
  // mapping (address => mapping (uint256 => address)) public subscribedClaims;

  // Allow for not setting values by sending -1
  function setInsuranceProfile(address insured, int16 plan, int256 startDate, int256 finalDate) {
    if (plan >= 0) {
      insuredProfile[insured].plan = uint16(plan);
    }
    if (startDate >= 0) {
      insuredProfile[insured].startDate = uint256(startDate);
    }
    if (finalDate >= 0) {
      insuredProfile[insured].finalDate = uint256(finalDate);
    }
  }

  function () { throw; }
}
