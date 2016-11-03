pragma solidity ^0.4.3;

contract Claim {
  struct H {
    uint h;
  }
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
    Examiner
  }

  enum ExaminerDecision {
    Pending,
    Reject,
    Approve
  }

  ClaimStates public currentState;

  uint256 public createDate;
  uint256 public modifiedDate;

  address public ownerAddress;
  address public insuranceAddress;

  uint16 public claimType;
  string public claimEvidence;

  uint256 public approvedPayout;
  address public beneficiaryAddress;

  mapping (uint16 => address) public examiners;
  uint16 totalExaminers;
  uint16 neededApprovals;

  mapping (address => ExaminerDecision) examinerDecision;

  event StateTransitionNotAllowed(ClaimStates oldState, ClaimStates newState, address originary);
  event StateDidTransition(ClaimStates oldState, ClaimStates newState, address originary);
  event ActionNotAllowed(ClaimStates state, address originary);

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

    currentState = ClaimStates.Created;
  }

  modifier onlyAddress(Originator _originary) {
    if (isOriginatorType(_originary)) {
      ActionNotAllowed(currentState, msg.sender);
      return;
    }
    _;
  }

  function transferOwnership(address newOwner)
           onlyAddress(Originator.Owner) {
    ownerAddress = newOwner;
  }

  modifier onlyState(ClaimStates _state) {
    if (currentState != _state) {
      ActionNotAllowed(currentState, msg.sender);
      return;
    }
    _;
  }

  function isOriginatorType(Originator originator) private constant returns (bool) {
    if (originator == Originator.Owner) { return msg.sender == ownerAddress; }
    if (originator == Originator.Insurance) { return msg.sender == insuranceAddress; }
    if (originator == Originator.Examiner) { return isExaminer(msg.sender); }

    return false;
  }

  function isExaminer(address ad) private constant returns (bool) {
    for (uint16 i = 0; i < totalExaminers; i++) {
      if (examiners[i] == ad) {
        return true;
      }
    }
    return false;
  }

  function assignExaminers(address[] memory _examiners, uint16 _neededApprovals)
    onlyAddress(Originator.Insurance)
    onlyState(ClaimStates.Review) public {
      for (uint16 i = 0; i < _examiners.length; i++) {
        examiners[i] = _examiners[i];
        totalExaminers += 1;
      }

      neededApprovals = _neededApprovals;
  }

  function addExaminerDecision(ExaminerDecision decision) onlyAddress(Originator.Examiner) {
    examinerDecision[msg.sender] = decision;
  }

  function submitNewEvidence(string newEvidence)
    onlyState(ClaimStates.PendingInfo)
    onlyAddress(Originator.Owner) {

    claimEvidence = newEvidence;
    transitionState(ClaimStates.Review);
  }

  function withdrawClaim() onlyAddress(Originator.Owner) {
    transitionState(ClaimStates.Withdrawn);
  }

  function transitionState(ClaimStates newState) {
    if (!isTransitionAllowed(uint(currentState), uint(newState))) {
      StateTransitionNotAllowed(currentState, newState, msg.sender);
      return;
    }

    StateDidTransition(currentState, newState, msg.sender);
    currentState = newState;
  }

  function isTransitionAllowed(uint state, uint newState) constant returns (bool) {
    if (isOriginatorType(Originator.Owner)) {
      if (state == uint(ClaimStates.PendingInfo) && newState == uint(ClaimStates.Review)) { return true; }
      if (state == uint(ClaimStates.Review) && newState == uint(ClaimStates.Withdrawn)) { return true; }
      if (state == uint(ClaimStates.PendingInfo) && newState == uint(ClaimStates.Withdrawn)) { return true; }
    }

    if (isOriginatorType(Originator.Insurance)) {
      if (state == uint(ClaimStates.Created) && newState == uint(ClaimStates.Review)) { return true; }
      if (state == uint(ClaimStates.Review) && newState == uint(ClaimStates.PendingInfo)) { return true; }
      if (state == uint(ClaimStates.Review) && newState == uint(ClaimStates.Accepted)) { return true; }
      if (state == uint(ClaimStates.Review) && newState == uint(ClaimStates.Rejected)) { return true; }
    }

    return false;
  }
}
