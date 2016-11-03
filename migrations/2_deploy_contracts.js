insuranceFund = () => {
  return [
    InsuranceFund, // Contract
    "Insurance Fund", // Contract name
    "INS", // Token name
    [web3.toWei(1, 'ether'), web3.toWei(2, 'ether')], // Insurance prices
  ];
}

investmentFund = (insFund) => {
  return [
    InvestmentFund, // Contract
    "Investment Fund", // Contract name
    "INV", // Token name
    10000, // Supply
    web3.toWei(1, 'ether'), // Initial price,
    insFund, // Insurance fund address,
    3, // 3% of tokens issued every time there are dividends,
    20, // 20% of minted tokens always go to holder
  ];
}

module.exports = (deployer) => {
    Promise.resolve()
      .then(() => {
      return deployer.deploy([insuranceFund()]);
    }).then(() => {
      return deployer.deploy([investmentFund(InsuranceFund.deployed().address)]);
    });
};
