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
    return insurance.buyInsuranceToken(0, {from: accounts[0], value: finneyToWei(1000)}).then(function(v) {
      return insurance.balanceOf.call(accounts[0]);
    }).then(function(balance) {
      assert.isAbove(balance.valueOf(), 0, "Balance should have increased");
    });
  });

  it("should fail if doesn't pay enough", function() {
    var insurance = InsuranceFund.deployed();

    return insurance.buyInsuranceToken(0, {from: accounts[1], value: finneyToWei(500)})
      .then(function(o) { assert.fail('shouldnt have succeeded') })
      .catch(function(e){
        assert.typeOf(e, 'Error')
    })
  });


  /*
  it("should call a function that depends on a linked library", function() {
    var meta = MetaCoin.deployed();
    var metaCoinBalance;
    var metaCoinEthBalance;

    return meta.getBalance.call(accounts[0]).then(function(outCoinBalance) {
      metaCoinBalance = outCoinBalance.toNumber();
      return meta.getBalanceInEth.call(accounts[0]);
    }).then(function(outCoinBalanceEth) {
      metaCoinEthBalance = outCoinBalanceEth.toNumber();
    }).then(function() {
      assert.equal(metaCoinEthBalance, 2 * metaCoinBalance, "Library function returned unexpeced function, linkage may be broken");
    });
  });
  it("should send coin correctly", function() {
    var meta = MetaCoin.deployed();

    // Get initial balances of first and second account.
    var account_one = accounts[0];
    var account_two = accounts[1];

    var account_one_starting_balance;
    var account_two_starting_balance;
    var account_one_ending_balance;
    var account_two_ending_balance;

    var amount = 10;

    return meta.getBalance.call(account_one).then(function(balance) {
      account_one_starting_balance = balance.toNumber();
      return meta.getBalance.call(account_two);
    }).then(function(balance) {
      account_two_starting_balance = balance.toNumber();
      return meta.sendCoin(account_two, amount, {from: account_one});
    }).then(function() {
      return meta.getBalance.call(account_one);
    }).then(function(balance) {
      account_one_ending_balance = balance.toNumber();
      return meta.getBalance.call(account_two);
    }).then(function(balance) {
      account_two_ending_balance = balance.toNumber();

      assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
    });
  });
  */
});
