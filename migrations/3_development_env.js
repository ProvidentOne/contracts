module.exports = function(deployer) {
  InsuranceFund.deployed().buyInsuranceToken(0, {value: web3.toWei(1, 'ether')})
};
