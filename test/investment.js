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
    return investment.mintToken(mintAmount, {from:accounts[0]}).then(() => {
      return investment.balanceOf.call(accounts[0], {from:accounts[1]})
    }).then((balance) => {
      assert.equal(balance.valueOf(), mintAmount, "Should own minted tokens");
    });
  });

  it("not owners cannot mint tokens", () => {
    var investment = InvestmentFund.deployed();
    return investment.mintToken(1002, {from:accounts[1]})
      .then(function(o) { assert.fail('shouldnt have succeeded') })
      .catch(function(e) {
        assert.typeOf(e, 'Error')
    })
  });
});
