pragma solidity ^0.4.3;

import "ClaimsStateMachine.sol";

contract Claim {
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

  function transferOwnership(address newOwner) onlyAddress(ownerAddress) {
    ownerAddress = newOwner;
  }

  modifier onlyState(ClaimsStateMachine.ClaimStates _state) {
    if (currentState != _state) {
      ActionNotAllowed(currentState, msg.sender);
      return;
    }
    _;
  }

  modifier onlyAddress(address _address) {
    if (msg.sender != _address) {
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

  function submitNewEvidence(string newEvidence) onlyState(ClaimsStateMachine.ClaimStates.PendingInfo) onlyAddress(ownerAddress) {
    claimEvidence = newEvidence;
    transitionState(ClaimsStateMachine.ClaimStates.Review);
  }

  function withdrawClaim() onlyAddress(ownerAddress) {
    transitionState(ClaimsStateMachine.ClaimStates.Withdrawn);
  }

  function transitionState(ClaimsStateMachine.ClaimStates newState) {
    if (ClaimsStateMachine.isTransitionAllowed(currentState, newState, originatorType())) {
      StateTransitionNotAllowed(currentState, newState, msg.sender);
      return;
    }

    StateDidTransition(currentState, newState, msg.sender);
    currentState = newState;
  }
}
