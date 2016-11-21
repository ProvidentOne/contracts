module.exports = function(deployer) {
  InsuranceFund.deployed().buyInsurancePlan(0, {value: web3.toWei(3, 'ether')})
};
