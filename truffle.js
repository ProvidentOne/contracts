module.exports = {
  "build": {},
  networks: {
    "live": {
      network_id: 1
    },
    "morden": {
      network_id: 2,        // Official Ethereum test network
      host: "178.25.19.88", // Random IP for example purposes (do not use)
      port: 80
    },
    "dev": {
      network_id: "default",
      host: "localhost",
      port: 8545,
      from: "0x456CDBb2a54f24d1BdCeA2603e23Aabf09d96f51"
    },
    "testing": {
      network_id: 2771,
      host: "localhost",
      port: 8811
    }
  }
};
