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
  mapping (address => mapping (uint256 => address)) public subscribedClaims;

  // Allow for not setting values by sending -1
  function setInsuranceProfile(address insured, int16 plan, int256 startDate, int256 finalDate) requiresPermission(PermissionLevel.Write) {
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

  function subscribeInsuredToClaim(address insured, address claim) {
    subscribedClaims[insured][insuredProfile[insured].totalSubscribedClaims] = claim;
    insuredProfile[insured].totalSubscribedClaims += 1;
  }

  mapping (uint256 => address) public claims;
  uint256 public claimIndex;

  function addClaim(address claim) {
    claims[claimIndex] = claim;
    claimIndex += 1;
  }

  mapping (uint16 => address) public examiners;
  uint16 private examinerIndex;

  function addExaminer(address examinerAddress) requiresPermission(PermissionLevel.Manager) {
    examiners[examinerIndex] = examinerAddress;
    examinerIndex += 1;
  }

  function removeExaminer(address examinerAddress) requiresPermission(PermissionLevel.Manager) {
    bool foundExaminer = false;
    for (uint16 i = 0; i<examinerIndex; i++) {
      if (!foundExaminer && examiners[i] == examinerAddress) {
        foundExaminer = true;
      }
      if (foundExaminer) {
        if (i < examinerIndex) {
          examiners[i] = examiners[i+1];
        }
      }
    }

    if (foundExaminer) {
      examinerIndex -= 1;
    }
  }

  function () { throw; }
}
