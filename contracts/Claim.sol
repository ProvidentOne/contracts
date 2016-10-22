contract Claim {
  enum ClaimStates {
    Created,
    Review,
    PendingInfo,
    Accepted,
    Rejected,
    Withdrawn
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

  mapping (uint256 => mapping (uint256 => address)) private allowedTransitions;

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
    generateAllowedTransitions();
  }

  modifier onlyState(ClaimStates _state) {
    if (currentState != _state) {
      ActionNotAllowed(currentState, msg.sender);
      return;
    } else _
  }

  modifier onlyAddress(address _address) {
    if (msg.sender != _address) {
      ActionNotAllowed(currentState, msg.sender);
      return;
    } else _
  }

  function stateIdentifier(ClaimStates _state) private constant returns (uint256) {
    return uint256(_state) * 10 + 1; // Avoid 0s
  }

  function generateAllowedTransitions() private constant {
    allowedTransitions[stateIdentifier(ClaimStates.Created)][stateIdentifier(ClaimStates.Review)] = insuranceAddress;
    allowedTransitions[stateIdentifier(ClaimStates.Review)][stateIdentifier(ClaimStates.PendingInfo)] = insuranceAddress;
    allowedTransitions[stateIdentifier(ClaimStates.Review)][stateIdentifier(ClaimStates.Accepted)] = insuranceAddress;
    allowedTransitions[stateIdentifier(ClaimStates.Review)][stateIdentifier(ClaimStates.Rejected)] = insuranceAddress;

    allowedTransitions[stateIdentifier(ClaimStates.PendingInfo)][stateIdentifier(ClaimStates.Review)] = ownerAddress;
    allowedTransitions[stateIdentifier(ClaimStates.Review)][stateIdentifier(ClaimStates.Withdrawn)] = ownerAddress;
    allowedTransitions[stateIdentifier(ClaimStates.PendingInfo)][stateIdentifier(ClaimStates.Withdrawn)] = ownerAddress;
  }

  function submitNewEvidence(string newEvidence) onlyState(ClaimStates.PendingInfo) onlyAddress(ownerAddress) {
    claimEvidence = newEvidence;
    transitionState(ClaimStates.Review);
  }

  function withdrawClaim() onlyAddress(ownerAddress) {
    transitionState(ClaimStates.Withdrawn);
  }

  function transitionState(ClaimStates newState) {
    if (allowedTransitions[stateIdentifier(currentState)][stateIdentifier(newState)] != msg.sender) {
      StateTransitionNotAllowed(currentState, newState, msg.sender);
      return;
    }

    StateDidTransition(currentState, newState, msg.sender);
    currentState = newState;
  }
}
