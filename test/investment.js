const helpers = require('./helpers');

contract('InvestmentFund', (accounts) => {
  it("contract should own all tokens", () => {
    var investment = InvestmentFund.deployed();
    var supply;
    return investment.totalSupply.call().then(function(s) {
      supply = s.valueOf();
      return investment.balanceOf.call(investment.address);
    }).then(function(balance) {
      assert.isAbove(balance.valueOf(), 0, "Contract should own tokens");
      assert.equal(balance.valueOf(), supply, "Contract doesnt own all tokens");
    });
  });

  it("owner should be able to mint tokens", () => {
    var investment = InvestmentFund.deployed();
    var mintAmount = 1000;
    return investment.mintToken(mintAmount, {from:accounts[0]})
      .then(() => {
        return investment.balanceOf.call(accounts[0], {from:accounts[1]})
      })
      .then((balance) => {
        assert.equal(balance.valueOf(), mintAmount, "Should own minted tokens");
      });
  });

  it("not owners cannot mint tokens", () => {
    var investment = InvestmentFund.deployed();
    return investment.mintToken(1002, {from:accounts[1]})
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
        assert.typeOf(e, 'Error')
    });
  });

  it("should split dividends proporcionally", () => {
    var investment = InvestmentFund.deployed();
    return investment.sendProfitsToHolders({from: accounts[0], value: web3.toWei(10, 'ether')})
      .then(() => {
        return investment.dividends.call(accounts[2])
      })
      .then((d) => {
        assert.isAbove(d.valueOf(), 0);
      });
  });
});
