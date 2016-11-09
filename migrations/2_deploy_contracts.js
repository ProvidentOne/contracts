module.exports = (deployer) => {
  deployer.deploy(InsuranceFund, {gas: 4730000})
  .then(()=> {
    InsuranceFund.deployed().bootstrapInsurance({gas: 4700000})
  })
  .catch((e) => { console.log('FUCKKK', e) })
};
