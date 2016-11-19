pragma solidity ^0.4.4;

contract Provident {
  // Insurer related
  function getNumberOfInsurancePlans() constant public returns (uint16);
  function getInsurancePlanPrice(uint16 plan) constant public returns (uint256);
  function getInsuredProfile(address insured) constant public returns (int16 plan, uint256 startDate, uint256 finalDate);

  function buyInsurancePlan(uint16 plan) payable public;
  function createClaim(uint16 claimType, string evidence, address beneficiary) public returns (bool);

  // Investor related
  event TokenAddressChanged(address newTokenAddress);
  function getTokenAddress() constant public returns (address); // ERC20 Compliant Token
  function getCurrentTokenOffer() constant public returns (uint256 price, uint256 availableTokens);

  function buyTokens() payable public;
  function withdrawDividends() public;
}
