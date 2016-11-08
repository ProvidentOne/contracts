const helpers = require('./helpers');

deployedFactory = (account) => {
  var factory;
  return new Promise((fullfil, reject) => {
    FundFactory.new({from: account}).then((contract) => {
      factory = contract;
      return contract.deployContracts({from: account});
    }).then(() => {
      fullfil(factory);
    }).catch(reject);
  })
}

contract('FundFactory', (accounts) => {
  it("deploys insurance contract", (done) => {
    var factory;
    deployedFactory(accounts[0]).then((contract) => {
      factory = contract;
      return factory.insuranceService.call();
    }).then((insuranceAddress) => {
      return InsuranceService.at(insuranceAddress).owner.call({from: accounts[1]})
    }).then((owner) => {
      assert.equal(owner, accounts[0]);
      done();
    }).catch(done);
  });

  it("deploys investment contract", (done) => {
    var factory;
    deployedFactory(accounts[0])
      .then((contract) => {
      factory = contract;
      return factory.investmentService.call();
    }).then((investmentAddress) => {
      return InvestmentService.at(investmentAddress).owner.call({from: accounts[1]})
    }).then((owner) => {
      assert.equal(owner, accounts[0]);
      done();
    }).catch(done);
  });

  it("investment fund sends money to insurance fund on token sell", (done) => {
    var factory;
    var investmentService;

    var investmentAmount = web3.toWei(3, 'ether');
    deployedFactory(accounts[0]).then((contract) => {
      factory = contract;
      return factory.investmentService.call();
    }).then((investmentAddress) => {
      investmentService = InvestmentService.at(investmentAddress);
      return investmentService.buyTokens({from: accounts[1], value: investmentAmount});
    }).then(() => {
      return factory.insuranceService.call();
    }).then((insuranceAddress) => {
      return helpers.getBalance(insuranceAddress);
    }).then((balance) => {
      assert.equal(investmentAmount, balance, "Funds should go to insurance fund");
      done();
    }).catch(done);
  });

  it("insurance fund should send money to investment fund when period ends", (done) => {
    var factory;
    var insuranceService;
    var investmentService;

    deployedFactory(accounts[0]).then((contract) => {
      factory = contract;
      return factory.investmentService.call();
    }).then((investmentAddress) => {
      investmentService = InvestmentService.at(investmentAddress);
      return investmentService.buyTokens({from: accounts[1], value: web3.toWei(3, 'ether')});
    }).then(() => {
      return factory.insuranceService.call();
    }).then((insuranceAddress) => {
      insuranceService = InsuranceService.at(insuranceAddress)
      return insuranceService.buyInsuranceToken(0, {value: web3.toWei(1, 'ether'), from: accounts[2]})
    }).then(() => {
      return insuranceService.performFundAccounting();
    }).then(() => {
      return factory.investmentService.call();
    }).then((investmentAddress) => {
      return investmentService.dividends.call(accounts[1]);
    }).then((dividend) => {
      assert.isAbove(dividend.valueOf(), 0);
      return helpers.getBalance(investmentService.address);
    }).then((balance) => {
      assert.equal(web3.toWei(1, 'ether'), balance.valueOf());
      done();
    }).catch(done);
  });
});
