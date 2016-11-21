module.exports = (deployer) => {
  deployer.deploy([[InsuranceFund, {gas: 10000000}],[InsuranceService], [InvestmentService]])
  .then(() => {
    InsuranceService.deployed().transferManagement(InsuranceFund.deployed().address);
  })
  .then(() => {
    InsuranceFund.deployed().setInsuranceService(InsuranceService.deployed().address, true);
  })
  .then(() => {
    InvestmentService.deployed().transferManagement(InsuranceFund.deployed().address);
  })
  .then(() => {
    InsuranceFund.deployed().setInvestmentService(InvestmentService.deployed().address, true);
  })
  .catch((e) => { console.log('deployment failed', e) });
};
