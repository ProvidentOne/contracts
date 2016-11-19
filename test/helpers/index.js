exports.getBalance = (address) => {
  return new Promise((fullfil, reject) => {
    web3.eth.getBalance(address, (err, balance) => {
      if (err) { return reject(err) }
      return fullfil(balance);
    })
  })
}
