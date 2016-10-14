const helpers = require('./helpers');

deployedFactory = (account) => {
  var factory;
  return new Promise((fullfil, reject) => {
    FundFactory.new({from: account}).then((contract) => {
      factory = contract;
      return contract.deployContracts({from: account});
    }).then(() => {
      fullfil(factory);
    })
    .catch(reject);
  })
}

contract('FundFactory', (accounts) => {
  it("deploys insurance contract", (done) => {
    var factory;
    deployedFactory(accounts[0]).then((contract) => {
      factory = contract;
      return factory.insuranceFund.call();
    }).then((insuranceAddress) => {
      return InsuranceFund.at(insuranceAddress).owner.call({from: accounts[1]})
    }).then((owner) => {
      assert.equal(owner, accounts[0]);
      done();
    }).catch(done);
  });

  it("deploys investment contract", (done) => {
    var factory;
    deployedFactory(accounts[0]).then((contract) => {
      factory = contract;
      return factory.investmentFund.call();
    }).then((investmentAddress) => {
      return InvestmentFund.at(investmentAddress).owner.call({from: accounts[1]})
    }).then((owner) => {
      assert.equal(owner, accounts[0]);
      done();
    }).catch(done);
  });
});
