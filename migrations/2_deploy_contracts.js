module.exports = (deployer) => {
  deployer.deploy(InsuranceFund, {gas: 4700000})
  .then(()=> {
    InsuranceFund.deployed().bootstrapInsurance({gas: 4700000})
  })
  .catch((e) => { console.log('FUCKKK', e) })
};
