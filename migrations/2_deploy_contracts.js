insuranceFund = () => {
  return [
    InsuranceFund, // Contract
    "Insurance Fund", // Contract name
    "INS", // Token name
    [web3.toWei(1, 'ether'), web3.toWei(2, 'ether')] // Insurance prices
  ];
}

investmentFund = (insFund) => {
  return [
    InvestmentFund, // Contract
    "Investment Fund", // Contract name
    "INV", // Token name
    1000000, // Supply
    web3.toWei(1, 'ether'), // Initial price,
    insFund // Insurance fund address
  ];
}

module.exports = (deployer) => {
  deployer.deploy([insuranceFund()]).then(() => {
    return deployer.deploy([investmentFund(InsuranceFund.address)]);
  }).then(() => {
    console.log("Contract deployment finished");
  });
};
