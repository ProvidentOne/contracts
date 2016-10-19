contract Claim {
  enum ClaimStates {
    Created,
    Review,
    PendingInfo,
    Accepted,
    Rejected
  }

  uint256 public createDate;
  uint256 public modifiedDate;
  ClaimStates public claimState;

  uint16 public claimType;
  string public claimEvidence;
  address public beneficiaryAddress;

  function Claim(
    uint16 _type,
    string _evidence
  ) {
    createDate = now;
    modifiedDate = now;

    claimType = _type;
    claimEvidence = _evidence;
    claimState = ClaimStates.Created;
  }
}
