module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.autolink();
  deployer.deploy(InsuranceFund, "Insurance Fund", "InsT", [1000, 2000, 3000]);
};
