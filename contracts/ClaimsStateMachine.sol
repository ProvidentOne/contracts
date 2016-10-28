pragma solidity ^0.4.3;

library ClaimsStateMachine {
  enum ClaimStates {
    Created,
    Review,
    PendingInfo,
    Accepted,
    Rejected,
    Withdrawn
  }

  enum Originator {
    Owner,
    Insurance,
    Any
  }

  function isTransitionAllowed(uint state, uint newState, uint originator) constant returns (bool) {
    if (originator == uint(Originator.Owner)) {
      if (state == uint(ClaimStates.PendingInfo) && newState == uint(ClaimStates.Review)) { return true; }
      if (state == uint(ClaimStates.Review) && newState == uint(ClaimStates.Withdrawn)) { return true; }
      if (state == uint(ClaimStates.PendingInfo) && newState == uint(ClaimStates.Withdrawn)) { return true; }
    }

    if (originator == uint(Originator.Insurance)) {
      if (state == uint(ClaimStates.Created) && newState == uint(ClaimStates.Review)) { return true; }
      if (state == uint(ClaimStates.Review) && newState == uint(ClaimStates.PendingInfo)) { return true; }
      if (state == uint(ClaimStates.Review) && newState == uint(ClaimStates.Accepted)) { return true; }
      if (state == uint(ClaimStates.Review) && newState == uint(ClaimStates.Rejected)) { return true; }
    }

    return false;
  }
}
