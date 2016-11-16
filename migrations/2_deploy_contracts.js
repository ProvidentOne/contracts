module.exports = (deployer) => {
  deployer.deploy([[InsuranceFund],[InsuranceService]])
  .then(() => {
    InsuranceService.deployed().transferManagement(InsuranceFund.deployed().address);
  })
  .then(() => {
    InsuranceFund.deployed().setInsuranceService(InsuranceService.deployed().address, true);
  })
  .catch((e) => { console.log('FUCKKK', e) })
};
