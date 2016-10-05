const helpers = require('./helpers');

contract('InvestmentFund', (accounts) => {
  it("should have all tokens", function() {
    var investment = InvestmentFund.deployed();

    var supply;

    return investment.totalSupply.call().then(function(s) {
      supply = s.valueOf();
      return investment.balanceOf.call(investment.address)
    }).then(function(balance) {
      assert.isAbove(balance.valueOf(), 0, "Contract should own tokens");
      assert.equal(balance.valueOf(), supply, "Contract doesnt own all tokens");
    });
  });
});
