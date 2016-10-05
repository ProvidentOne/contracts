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
    var amount =  web3.toWei(1000, 'finney');
    return insurance.buyInsuranceToken(0, {from: accounts[0], value: amount}).then(function(v) {
      return insurance.balanceOf.call(accounts[0]);
    }).then(function(balance) {
      assert.isAbove(balance.valueOf(), 0, "Token balance should have increased");
      assert.equal(web3.eth.getBalance(insurance.address).toString(), amount.toString(), "Contract balance should have increased");
    });
  });

  it("should fail if doesn't pay enough", function() {
    var insurance = InsuranceFund.deployed();

    return insurance.buyInsuranceToken(0, {from: accounts[1], value: web3.toWei(500, 'finney')})
      .then(function(o) { assert.fail('shouldnt have succeeded') })
      .catch(function(e) {
        assert.typeOf(e, 'Error')
    })
  });

  it("should create token type", function() {
    var insurance = InsuranceFund.deployed();

    var initialTypes;

    return insurance.tokenTypes.call().then((t) => {
      initialTypes = t;
      return insurance.addTokenType(1000, 1000, {from: accounts[0]})
    }).then(() => {
      return insurance.tokenTypes.call()
    }).then((t) => {
        assert.equal(t.valueOf(), initialTypes.plus(1).valueOf(), "Should have added a token type")
    })
  });

  it("should be able to claim if it is token holder", function(){
    var insurance = InsuranceFund.deployed();
    var amount = web3.toWei(1000, 'finney');
    var claimAmount = web3.toWei(10, 'finney');
    var tokenPlan = web3.toBigNumber(0);

    return insurance.buyInsuranceToken(tokenPlan, {from: accounts[1], value: amount}).then(function(v) {
      return insurance.transferForClaim(claimAmount, tokenPlan, accounts[1], accounts[0], {from: accounts[0], value: web3.toWei(1, 'finney')})
    }).then(function (){
        console.log('got the lol')
        assert.equal(web3.eth.getBalance(insurance.address).toString(), claimAmount, "Should have gotten money for claim");
    })
  })
});
