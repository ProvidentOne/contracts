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

  function isTransitionAllowed(ClaimStates state, ClaimStates newState, Originator originator) returns (bool) {
    if (originator == Originator.Owner) {
      if (state == ClaimStates.PendingInfo && newState == ClaimStates.Review) { return true; }
      if (state == ClaimStates.Review && newState == ClaimStates.Withdrawn) { return true; }
      if (state == ClaimStates.PendingInfo && newState == ClaimStates.Withdrawn) { return true; }
    }

    if (originator == Originator.Insurance) {
      if (state == ClaimStates.Created && newState == ClaimStates.Review) { return true; }
      if (state == ClaimStates.Review && newState == ClaimStates.PendingInfo) { return true; }
      if (state == ClaimStates.Review && newState == ClaimStates.Accepted) { return true; }
      if (state == ClaimStates.Review && newState == ClaimStates.Rejected) { return true; }
    }

    return false;
  }
}
