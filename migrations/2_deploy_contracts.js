module.exports = (deployer) => {
  deployer.deploy(InsuranceFund)
  .then(()=> {
    InsuranceFund.deployed().bootstrapInsurance({gas: 4700000})
  })
  .catch((e) => { console.log('FUCKKK', e) })
};
