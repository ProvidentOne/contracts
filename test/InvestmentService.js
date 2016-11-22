const helpers = require('./helpers');

contract('InvestmentService', (accounts) => {
  it("should deploy fund and service", function(done) {
    var fund;
    deployInvContract()
      .then((f) => {
        fund = f;
        return f.addressFor.call('InvestmentService');
      })
      .then((s) => {
        assert.notEqual(s, '0x', false, "investment service isn't properly linked");
        done();
      });
  });

  it("holder should receive tokens from minting", function(done) {
    var fund;
    var service;
    deployInvContract()
      .then((f) => {
        fund = f;
        service = InvestmentService.at(fund.investmentServiceAddress);
        return Promise.all([service.balanceOf(accounts[0]), service.holderTokensPct(), service.initialSupply()]);
      })
      .then(([tokenBalance, holderPct, initialSupply]) => {
        assert.equal(tokenBalance.valueOf(), holderPct.valueOf() * initialSupply.valueOf() / 100, 'should own portion of the minted tokens');
        done();
      });
  });

  it("should be able to buy tokens", function(done) {
    var fund;
    var buyingTokens = 10;
    var payingAmount;
    deployInvContract()
      .then((f) => {
        fund = f;
        return fund.getCurrentTokenOffer.call();
      })
      .then(([price, availableTokens]) => {
        assert.isAbove(availableTokens.valueOf(), 0, false, "should be available tokens");
        assert.isAbove(price.valueOf(), 0, false, "should have a price above 0");
        payingAmount = price.valueOf() * buyingTokens;
        // From 2nd account becuase first is holder and receives free tokens on minting.
        return fund.buyTokens({value: payingAmount, from: accounts[1]});
      })
      .then(() => {
        return helpers.getBalance(fund.address);
      })
      .then((fundBalance) => {
        assert.equal(fundBalance.valueOf(), payingAmount, 'fund should have token sell funds');
        return InvestmentService.at(fund.investmentServiceAddress).balanceOf(accounts[1]);
      })
      .then((tokenBalance) => {
        assert.equal(tokenBalance.valueOf(), buyingTokens, 'should own the bought tokens');
        done();
      });
  });

  it("should split dividends evenly", function(done) {
    var fund;
    var premiumAmount = web3.toWei(10, 'ether');
    var claimAmount = web3.toWei(5, 'ether');
    var dividends = premiumAmount.valueOf() - claimAmount.valueOf();
    deployInvContract()
      .then((f) => {
        fund = f;
        service = InvestmentService.at(fund.investmentServiceAddress);
        return mockAccountingPersistance(fund, premiumAmount, claimAmount);
      })
      .then(() => {
        console.log('performing accounting');
        return service.performFundAccounting({gas: 9990000, from: accounts[0]});
      })
      .then(() => {
        return service.dividendOf(accounts[0]);
      })
      .then((dividend) => {
        assert.isAbove(dividend.valueOf(), 0, 'should have dividends');
        done();
      });
  });
});

deployInvContract = () => {
  var fund;
  var service;
  return InsuranceFund.new({gas: 10000000}).then((f) => {
    fund = f;
    return InvestmentService.new();
  })
  .then((s) => {
    service = s;
    return service.transferManagement(fund.address);
  })
  .then(() => {
    fund.investmentServiceAddress = service.address;
    return fund.setInvestmentService(service.address, true);
  })
  .then(() => {
    return Promise.resolve(fund);
  });
}

mockAccountingPersistance = (fund, premiums, claims) => {
  var accounting;
  return AccountingPersistance.new().then((a) => {
    accounting = a;
    return fund.addPersistance(accounting.address);
  }).then(() => {
    return accounting.saveTransaction(1, claims, fund.address, fund.address, 'p', false);
  }).then(() => {
    return accounting.saveTransaction(0, premiums, fund.address, fund.address, 'c', false);
  }).then(() => {
    return accounting.transferManagement(fund.address);
  });
}
