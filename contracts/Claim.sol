pragma solidity ^0.4.3;

import "ClaimsStateMachine.sol";

contract Claim {
  using ClaimsStateMachine for ClaimsStateMachine.ClaimStates;

  ClaimsStateMachine.ClaimStates public currentState;

  uint256 public createDate;
  uint256 public modifiedDate;

  address public ownerAddress;
  address public insuranceAddress;

  uint16 public claimType;
  string public claimEvidence;

  uint256 public approvedPayout;
  address public beneficiaryAddress;

  event StateTransitionNotAllowed(ClaimsStateMachine.ClaimStates oldState, ClaimsStateMachine.ClaimStates newState, address originary);
  event StateDidTransition(ClaimsStateMachine.ClaimStates oldState, ClaimsStateMachine.ClaimStates newState, address originary);
  event ActionNotAllowed(ClaimsStateMachine.ClaimStates state, address originary);

  function Claim(
    uint16 _type,
    string _evidence,
    address _insurance,
    address _beneficiary
  ) {
    createDate = now;
    modifiedDate = now;

    ownerAddress = msg.sender;
    insuranceAddress = _insurance;

    claimType = _type;
    claimEvidence = _evidence;
    beneficiaryAddress = _beneficiary;

    currentState = ClaimsStateMachine.ClaimStates.Created;
  }

  modifier onlyAddress(ClaimsStateMachine.Originator _originary) {
    if (uint256(originatorType()) != uint256(_originary)) {
      ActionNotAllowed(currentState, msg.sender);
      return;
    }
    _;
  }

  function transferOwnership(address newOwner) onlyAddress(ClaimsStateMachine.Originator.Owner) {
    ownerAddress = newOwner;
  }

  modifier onlyState(ClaimsStateMachine.ClaimStates _state) {
    if (currentState != _state) {
      ActionNotAllowed(currentState, msg.sender);
      return;
    }
    _;
  }

  function originatorType() private returns (ClaimsStateMachine.Originator) {
    if (msg.sender == ownerAddress) { return ClaimsStateMachine.Originator.Owner; }
    if (msg.sender == insuranceAddress) { return ClaimsStateMachine.Originator.Insurance; }
    return ClaimsStateMachine.Originator.Any;
  }

  function submitNewEvidence(string newEvidence) onlyState(ClaimsStateMachine.ClaimStates.PendingInfo) onlyAddress(ClaimsStateMachine.Originator.Owner) {
    claimEvidence = newEvidence;
    transitionState(ClaimsStateMachine.ClaimStates.Review);
  }

  function withdrawClaim() onlyAddress(ClaimsStateMachine.Originator.Owner) {
    transitionState(ClaimsStateMachine.ClaimStates.Withdrawn);
  }

  function transitionState(ClaimsStateMachine.ClaimStates newState) {

    if (!isTransitionAllowed(uint(currentState), uint(newState), uint(originatorType()))) {
      // StateTransitionNotAllowed(currentState, newState, msg.sender);
      return;
    }

    // StateDidTransition(currentState, newState, msg.sender);
    currentState = newState;
  }

  // TODO: Get this out of here :(
  function isTransitionAllowed(uint state, uint newState, uint originator) constant returns (bool) {
    if (originator == uint(ClaimsStateMachine.Originator.Owner)) {
      if (state == uint(ClaimsStateMachine.ClaimStates.PendingInfo) && newState == uint(ClaimsStateMachine.ClaimStates.Review)) { return true; }
      if (state == uint(ClaimsStateMachine.ClaimStates.Review) && newState == uint(ClaimsStateMachine.ClaimStates.Withdrawn)) { return true; }
      if (state == uint(ClaimsStateMachine.ClaimStates.PendingInfo) && newState == uint(ClaimsStateMachine.ClaimStates.Withdrawn)) { return true; }
    }

    if (originator == uint(ClaimsStateMachine.Originator.Insurance)) {
      if (state == uint(ClaimsStateMachine.ClaimStates.Created) && newState == uint(ClaimsStateMachine.ClaimStates.Review)) { return true; }
      if (state == uint(ClaimsStateMachine.ClaimStates.Review) && newState == uint(ClaimsStateMachine.ClaimStates.PendingInfo)) { return true; }
      if (state == uint(ClaimsStateMachine.ClaimStates.Review) && newState == uint(ClaimsStateMachine.ClaimStates.Accepted)) { return true; }
      if (state == uint(ClaimsStateMachine.ClaimStates.Review) && newState == uint(ClaimsStateMachine.ClaimStates.Rejected)) { return true; }
    }

    return false;
  }
}
