module.exports = (deployer) => {
  deployer.deploy(InsuranceFund)
    .then((fund) => {
      InsuranceFund.deployed().bootstrapInsurance({gas: 4500000});
    });
};
