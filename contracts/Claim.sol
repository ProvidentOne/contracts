pragma solidity ^0.4.4;

contract Claim {
  enum ClaimStates {
    Created,
    Review,
    PendingInfo,
    Accepted,
    Rejected,
    Payed,
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
  mapping (address => uint256) public allowance;

  mapping (address => ExaminerDecision) examinerDecision;
  mapping (uint16 => address) public examiners;
  uint16 totalExaminers;
  uint16 neededApprovals;

  event StateTransitionNotAllowed(ClaimStates oldState, ClaimStates newState, address originary);
  event StateDidTransition(ClaimStates oldState, ClaimStates newState, address originary);
  event ActionNotAllowed(ClaimStates state, address originary);

  modifier onlyAddress(Originator _originary) {
    if (isOriginatorType(_originary)) {
      ActionNotAllowed(currentState, msg.sender);
      return;
    }
    _;
  }

  modifier onlyState(ClaimStates _state) {
    if (currentState != _state) {
      ActionNotAllowed(currentState, msg.sender);
      return;
    }
    _;
  }

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

  function assignExaminers(address[] memory _examiners, uint16 _neededApprovals)
    onlyAddress(Originator.Insurance)
    onlyState(ClaimStates.Review) public {

      for (uint16 i = 0; i < _examiners.length; i++) {
        examiners[i] = _examiners[i];
        totalExaminers += 1;
      }

      neededApprovals = _neededApprovals;
  }

  function addExaminerDecision(ExaminerDecision decision)
    onlyAddress(Originator.Examiner)
    onlyState(ClaimStates.Review) public returns (bool) {

      examinerDecision[msg.sender] = decision;
      return checkClaimDecisions();
  }

  function submitNewEvidence(string newEvidence)
    onlyState(ClaimStates.PendingInfo)
    onlyAddress(Originator.Owner) returns (bool) {

      claimEvidence = newEvidence;
      return transitionState(ClaimStates.Review);
  }

  function transferOwnership(address newOwner)
    onlyAddress(Originator.Owner) returns (bool) {

      ownerAddress = newOwner;
      return true;
  }

  function sendPayout()
    onlyState(ClaimStates.Accepted)
    onlyAddress(Originator.Insurance)
    payable returns (bool) {

      approvedPayout = msg.value;
      allowance[beneficiaryAddress] = msg.value;
      return transitionState(ClaimStates.Payed);
  }

  function withdraw(uint256 amount) {
    if (allowance[msg.sender] >= amount && msg.sender.send(amount)) {
      allowance[msg.sender] -= amount;
    } else {
      throw;
    }
  }

  function createAllowance(uint256 amount, address allowedAddress) {
    if (allowance[msg.sender] >= amount) {
      allowance[msg.sender] -= amount;
      allowance[allowedAddress] += amount;
    } else {
      throw;
    }
  }

  function transitionState(ClaimStates newState) returns (bool) {
    if (!isTransitionAllowed(uint(currentState), uint(newState))) {
      StateTransitionNotAllowed(currentState, newState, msg.sender);
      return false;
    }

    StateDidTransition(currentState, newState, msg.sender);
    currentState = newState;
    return true;
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

  function checkClaimDecisions() private returns (bool) {
    if (hasBeenApproved()) {
      return transitionState(ClaimStates.Accepted);
    }

    if (hasBeenRejected()) {
      return transitionState(ClaimStates.Rejected);
    }

    return true;
  }

  function hasBeenApproved() private returns (bool) {
    uint16 total; uint16 approves; uint16 rejects;
    (total, approves, rejects) = getExaminerDecisions();

    return approves >= neededApprovals;
  }

  function hasBeenRejected() private returns (bool) {
    uint16 total; uint16 approves; uint16 rejects;
    (total, approves, rejects) = getExaminerDecisions();

    return total - rejects < neededApprovals;
  }

  function getExaminerDecisions() private constant returns (uint16 _totalExaminers, uint16 _approvals, uint16 _rejections) {
    _totalExaminers = totalExaminers;
    for (uint16 i = 0; i < totalExaminers; i++) {
      ExaminerDecision decision = examinerDecision[i];
      if (decision == ExaminerDecision.Approve) {
        _approvals += 1;
      }
      if (decision == ExaminerDecision.Reject) {
        _rejections += 1;
      }
    }
    return;
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
      if (state == uint(ClaimStates.Accepted) && newState == uint(ClaimStates.Payed)) { return true; }
    }

    if (isOriginatorType(Originator.Examiner)) {
      if (state == uint(ClaimStates.Review) && newState == uint(ClaimStates.Accepted)) {
        return hasBeenApproved();
      }
      if (state == uint(ClaimStates.Review) && newState == uint(ClaimStates.Rejected)) {
        return hasBeenRejected();
      }
    }

    return false;
  }
}
