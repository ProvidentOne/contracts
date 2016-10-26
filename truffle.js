module.exports = {
  build: {
    "index.html": "index.html",
    "app.js": [
      "javascripts/app.js"
    ],
    "app.css": [
      "stylesheets/app.css"
    ],
    "images/": "images/"
  },

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
      host: "localhost",
      port: 8811
    }
  }
};
