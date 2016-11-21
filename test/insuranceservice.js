const helpers = require('./helpers');

contract('InsuranceService', (accounts) => {
  it("should deploy fund and service", function(done) {
    var fund;
    deployInsContract()
      .then((f) => {
        fund = f;
        return f.addressFor('InsuranceService');
      })
      .then((s) => {
        assert.notEqual(s, '0x', false, "insurance service isn't properly linked");
        done();
      });
  });

  it("should be able to buy insurance plans", function(done) {
    var fund;
    var price;

    deployInsContract()
      .then((f) => {
        fund = f;
        return buyLastInsurancePlan(fund);
      })
      .then(([payed]) => {
        price = payed;
        return fund.getInsuredProfile.call();
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
    deployInsContract()
      .then((f) => {
        return f.buyInsurancePlan(0, {value: web3.toWei(1, 'wei')});
      })
      .then(() => {
        assert.fail('should have failed because not enough money was sent');
        done();
      })
      .catch(function(e) {
        assert.typeOf(e, 'Error');
        done();
      });
  });

  it("should be able to claim if it is token holder", function(done){
    var fund;
    deployInsContract()
      .then((f) => {
        fund = f;
        return buyLastInsurancePlan(fund);
      })
      .then(([price, plan]) => {
        return fund.createClaim(plan, 'test evidence', accounts[0]);
      })
      .then(() => {
        return fund.addressFor.call('InsuranceService').then((a) => { return Promise.resolve(InsuranceService.at(a)) });
      })
      .then((service) => {
        return service.getInsuranceProfile.call(accounts[0]);
      })
      .then(([plan, startDate, endDate, subscribedClaims]) => {
        assert.equal(subscribedClaims.valueOf(), 1, 'should be susbcribed to one claim')
        done();
      })
      .catch(assert.fail)
  });
});

deployInsContract = () => {
  var fund;
  var service;
  return InsuranceFund.new({gas: 10000000}).then((f) => {
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

buyLastInsurancePlan = (fund) => {
  var price;
  var buyingPlan;
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
      return Promise.resolve([price, buyingPlan]);
    });
}
