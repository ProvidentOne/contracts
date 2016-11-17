const helpers = require('./helpers');

deployContract = () => {
  var fund;
  var service;
  return InsuranceFund.new().then((f) => {
    fund = f;
    return InsuranceService.new();
  })
  .then((s) => {
    service = s;
    return service.transferManagement(fund.address);
  })
  .then(() => {
    return fund.setInsuranceService(service.address, true);
  })
  .then(() => {
    return Promise.resolve(fund);
  });
}

buyFirstInsurancePlan = (fund) => {
  var price;
  return fund.getNumberOfInsurancePlans()
    .then((n) => {
      buyingPlan = n.valueOf() - 1;
      return fund.getInsurancePlanPrice(buyingPlan);
    })
    .then((p) => {
      price = p.valueOf();
      return fund.buyInsurancePlan(buyingPlan, {value: price});
    })
    .then(() => {
      return Promise.resolve(price);
    });
}

contract('InsuranceFund', (accounts) => {
  it("should deploy fund and service", function(done) {
    var fund;
    deployContract()
      .then((f) => {
        fund = f;
        return f.addressFor('InsuranceService');
      })
      .then((s) => {
        assert.equal(s.startsWith('0x0000'), false, "insurance service isn't properly linked");
        done();
      });
  });

  it("should be able to buy insurance tokens", function(done) {
    var fund;
    var buyingPlan;
    var price;

    deployContract()
      .then((f) => {
        fund = f;
        return buyFirstInsurancePlan(fund);
      })
      .then((payed) => {
        price = payed;
        return fund.getInsuredProfile();
      })
      .then(([plan, startDate, endDate]) => {
        assert.isAbove(plan.valueOf(), 0, 'should be enrolled in a plan');
        return helpers.getBalance(fund.address);
      })
      .then((balance) => {
        assert.equal(price, balance.valueOf(), 'should have payed money in balance');
        done();
      });
  });

  it("should fail if doesn't pay enough", function(done) {
    deployContract()
      .then((f) => {
        return f.buyInsurancePlan(0, {value: web3.toWei(1, 'wei')});
      })
      .then(() => {
        assert.fail('shouldnt have failed because not enough money was sent');
        done();
      })
      .catch(function(e) {
        assert.typeOf(e, 'Error');
        done();
      });
  });

  /*

  it("should be able to claim if it is token holder", function(){
    var insurance = InsuranceService.deployed();
    var amount = web3.toWei(1000, 'finney');
    var claimAmount = web3.toWei(10, 'finney');
    var tokenPlan = web3.toBigNumber(0);
    var beneficiaryAddress = accounts[4];

    var initialBalance;

    return insurance.buyInsuranceToken(tokenPlan, {from: accounts[1], value: amount}).then(function(v) {
      return helpers.getBalance(beneficiaryAddress);
    }).then((balance) => {
      initialBalance = balance;
      return insurance.transferForClaim(claimAmount, tokenPlan, accounts[1], beneficiaryAddress, {from: accounts[0]})
    }).then(() => {
        return helpers.getBalance(beneficiaryAddress);
    }).then((balance) => {
      assert.equal(balance.valueOf(), initialBalance.plus(claimAmount).valueOf(), "Should have gotten money for claim");
    });
  });
  */
});
