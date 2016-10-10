const helpers = require('./helpers');

contract('InvestmentFund', (accounts) => {
  it("contract should own 80% of all tokens", () => {
    var investment = InvestmentFund.deployed();
    var supply;
    return investment.totalSupply.call().then(function(s) {
      supply = s.valueOf();
      return investment.balanceOf.call(investment.address);
    }).then(function(balance) {
      assert.equal(balance.valueOf(), supply * 0.8, "Contract doesnt own 80% tokens");
    });
  });

  it("owner should not be able to mint tokens", () => {
    var investment = InvestmentFund.deployed();
    var mintAmount = 1000;
    return investment.mintTokens(mintAmount, {from:accounts[0]})
    .then(function(o) { assert.fail('shouldnt have succeeded') })
    .catch(function(e) {
      assert.typeOf(e, 'Error')
    });
  });

  it("not owners cannot mint tokens", () => {
    var investment = InvestmentFund.deployed();
    return investment.mintTokens(1002, {from:accounts[1]})
      .then(function(o) { assert.fail('shouldnt have succeeded') })
      .catch(function(e) {
        assert.typeOf(e, 'Error')
    });
  });

  it("investors should be able to buy tokens", () => {
    var investment = InvestmentFund.deployed();
    var buyingTokens = 3;
    var tokenPrice = web3.toWei(buyingTokens + 0.9, 'ether');
    return investment.buyTokens({from: accounts[2], value: tokenPrice})
      .then(() => {
        return investment.balanceOf.call(accounts[2], {from:accounts[1]})
      })
      .then((balance) => {
        assert.equal(balance.valueOf(), buyingTokens, "Should own payed for tokens");
      });
  });

  it("shouldn't issue tokens if not enough money is sent", () => {
    var investment = InvestmentFund.deployed();
    return investment.buyTokens({from: accounts[2], value: web3.toWei(0.9, 'ether')})
      .then(function(o) { assert.fail('shouldnt have succeeded') })
      .catch(function(e) {
        assert.typeOf(e, 'Error');
    });
  });

  it("should split dividends proporcionally", () => {
    var investment = InvestmentFund.deployed();
    return investment.sendProfitsToInvestors({from: accounts[0], value: web3.toWei(10, 'ether')})
      .then(() => {
        return investment.dividends.call(accounts[2]);
      })
      .then((d) => {
        assert.isAbove(d.valueOf(), 0);
      });
  });

  it("should be able to withdraw", () => {
    var investment = InvestmentFund.deployed();
    var initialBalance;
    var dividendAmount;
    return investment.dividends.call(accounts[2])
      .then((d) => {
        dividendAmount = d;
        assert.isAbove(dividendAmount.valueOf(), 0, "should have something to cash out");
        return helpers.getBalance(accounts[2]);
      }).then((i) => {
        initialBalance = i;
        return investment.withdraw({from: accounts[2]})
      }).then(() => {
        return helpers.getBalance(accounts[2])
      }).then((currentBalance) => {
        var dif = currentBalance.minus(initialBalance);
        assert.isAbove(currentBalance.valueOf(), initialBalance.valueOf(), "Should have more money");
        assert.isBelow(dividendAmount.minus(dif).valueOf(), web3.toWei(0.05, 'finney'), "Should have dividend money (minus reasonable gas)");
      })
  });
});
