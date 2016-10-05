module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.autolink();
  deployer.deploy(InsuranceFund, "Insurance Fund", "InsT", [web3.toWei(1, 'ether'), web3.toWei(2, 'ether')]);
};
