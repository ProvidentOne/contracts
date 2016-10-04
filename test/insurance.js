finneyToWei = function (finney) {
  return finney * Math.pow(10, 15);
}

contract('Insurance', function(accounts) {
  it("should have all tokens", function() {
    var insurance = InsuranceFund.deployed();

    var supply;

    return insurance.totalSupply.call().then(function(s) {
      supply = s.valueOf();
      return insurance.balanceOf.call(insurance.address)
    }).then(function(balance) {
      assert.isAbove(balance.valueOf(), 0, "Contract should own tokens");
      assert.equal(balance.valueOf(), supply, "Contract doesnt own all tokens");
    });
  });

  it("should be able to buy insurance tokens", function() {
    var insurance = InsuranceFund.deployed();
    var amount = finneyToWei(1000);
    return insurance.buyInsuranceToken(0, {from: accounts[0], value: amount}).then(function(v) {
      return insurance.balanceOf.call(accounts[0]);
    }).then(function(balance) {
      assert.isAbove(balance.valueOf(), 0, "Token balance should have increased");
      assert.equal(web3.eth.getBalance(insurance.address).toString(), amount.toString(), "Contract balance should have increased");
    });
  });

  it("should fail if doesn't pay enough", function() {
    var insurance = InsuranceFund.deployed();

    return insurance.buyInsuranceToken(0, {from: accounts[1], value: finneyToWei(500)})
      .then(function(o) { assert.fail('shouldnt have succeeded') })
      .catch(function(e) {
        assert.typeOf(e, 'Error')
    })
  });
});
