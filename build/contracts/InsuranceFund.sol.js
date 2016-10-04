var Web3 = require("web3");
var SolidityEvent = require("web3/lib/web3/event.js");

(function() {
  // Planned for future features, logging, etc.
  function Provider(provider) {
    this.provider = provider;
  }

  Provider.prototype.send = function() {
    this.provider.send.apply(this.provider, arguments);
  };

  Provider.prototype.sendAsync = function() {
    this.provider.sendAsync.apply(this.provider, arguments);
  };

  var BigNumber = (new Web3()).toBigNumber(0).constructor;

  var Utils = {
    is_object: function(val) {
      return typeof val == "object" && !Array.isArray(val);
    },
    is_big_number: function(val) {
      if (typeof val != "object") return false;

      // Instanceof won't work because we have multiple versions of Web3.
      try {
        new BigNumber(val);
        return true;
      } catch (e) {
        return false;
      }
    },
    merge: function() {
      var merged = {};
      var args = Array.prototype.slice.call(arguments);

      for (var i = 0; i < args.length; i++) {
        var object = args[i];
        var keys = Object.keys(object);
        for (var j = 0; j < keys.length; j++) {
          var key = keys[j];
          var value = object[key];
          merged[key] = value;
        }
      }

      return merged;
    },
    promisifyFunction: function(fn, C) {
      var self = this;
      return function() {
        var instance = this;

        var args = Array.prototype.slice.call(arguments);
        var tx_params = {};
        var last_arg = args[args.length - 1];

        // It's only tx_params if it's an object and not a BigNumber.
        if (Utils.is_object(last_arg) && !Utils.is_big_number(last_arg)) {
          tx_params = args.pop();
        }

        tx_params = Utils.merge(C.class_defaults, tx_params);

        return new Promise(function(accept, reject) {
          var callback = function(error, result) {
            if (error != null) {
              reject(error);
            } else {
              accept(result);
            }
          };
          args.push(tx_params, callback);
          fn.apply(instance.contract, args);
        });
      };
    },
    synchronizeFunction: function(fn, instance, C) {
      var self = this;
      return function() {
        var args = Array.prototype.slice.call(arguments);
        var tx_params = {};
        var last_arg = args[args.length - 1];

        // It's only tx_params if it's an object and not a BigNumber.
        if (Utils.is_object(last_arg) && !Utils.is_big_number(last_arg)) {
          tx_params = args.pop();
        }

        tx_params = Utils.merge(C.class_defaults, tx_params);

        return new Promise(function(accept, reject) {

          var decodeLogs = function(logs) {
            return logs.map(function(log) {
              var logABI = C.events[log.topics[0]];

              if (logABI == null) {
                return null;
              }

              var decoder = new SolidityEvent(null, logABI, instance.address);
              return decoder.decode(log);
            }).filter(function(log) {
              return log != null;
            });
          };

          var callback = function(error, tx) {
            if (error != null) {
              reject(error);
              return;
            }

            var timeout = C.synchronization_timeout || 240000;
            var start = new Date().getTime();

            var make_attempt = function() {
              C.web3.eth.getTransactionReceipt(tx, function(err, receipt) {
                if (err) return reject(err);

                if (receipt != null) {
                  // If they've opted into next gen, return more information.
                  if (C.next_gen == true) {
                    return accept({
                      tx: tx,
                      receipt: receipt,
                      logs: decodeLogs(receipt.logs)
                    });
                  } else {
                    return accept(tx);
                  }
                }

                if (timeout > 0 && new Date().getTime() - start > timeout) {
                  return reject(new Error("Transaction " + tx + " wasn't processed in " + (timeout / 1000) + " seconds!"));
                }

                setTimeout(make_attempt, 1000);
              });
            };

            make_attempt();
          };

          args.push(tx_params, callback);
          fn.apply(self, args);
        });
      };
    }
  };

  function instantiate(instance, contract) {
    instance.contract = contract;
    var constructor = instance.constructor;

    // Provision our functions.
    for (var i = 0; i < instance.abi.length; i++) {
      var item = instance.abi[i];
      if (item.type == "function") {
        if (item.constant == true) {
          instance[item.name] = Utils.promisifyFunction(contract[item.name], constructor);
        } else {
          instance[item.name] = Utils.synchronizeFunction(contract[item.name], instance, constructor);
        }

        instance[item.name].call = Utils.promisifyFunction(contract[item.name].call, constructor);
        instance[item.name].sendTransaction = Utils.promisifyFunction(contract[item.name].sendTransaction, constructor);
        instance[item.name].request = contract[item.name].request;
        instance[item.name].estimateGas = Utils.promisifyFunction(contract[item.name].estimateGas, constructor);
      }

      if (item.type == "event") {
        instance[item.name] = contract[item.name];
      }
    }

    instance.allEvents = contract.allEvents;
    instance.address = contract.address;
    instance.transactionHash = contract.transactionHash;
  };

  // Use inheritance to create a clone of this contract,
  // and copy over contract's static functions.
  function mutate(fn) {
    var temp = function Clone() { return fn.apply(this, arguments); };

    Object.keys(fn).forEach(function(key) {
      temp[key] = fn[key];
    });

    temp.prototype = Object.create(fn.prototype);
    bootstrap(temp);
    return temp;
  };

  function bootstrap(fn) {
    fn.web3 = new Web3();
    fn.class_defaults  = fn.prototype.defaults || {};

    // Set the network iniitally to make default data available and re-use code.
    // Then remove the saved network id so the network will be auto-detected on first use.
    fn.setNetwork("default");
    fn.network_id = null;
    return fn;
  };

  // Accepts a contract object created with web3.eth.contract.
  // Optionally, if called without `new`, accepts a network_id and will
  // create a new version of the contract abstraction with that network_id set.
  function Contract() {
    if (this instanceof Contract) {
      instantiate(this, arguments[0]);
    } else {
      var C = mutate(Contract);
      var network_id = arguments.length > 0 ? arguments[0] : "default";
      C.setNetwork(network_id);
      return C;
    }
  };

  Contract.currentProvider = null;

  Contract.setProvider = function(provider) {
    var wrapped = new Provider(provider);
    this.web3.setProvider(wrapped);
    this.currentProvider = provider;
  };

  Contract.new = function() {
    if (this.currentProvider == null) {
      throw new Error("InsuranceFund error: Please call setProvider() first before calling new().");
    }

    var args = Array.prototype.slice.call(arguments);

    if (!this.unlinked_binary) {
      throw new Error("InsuranceFund error: contract binary not set. Can't deploy new instance.");
    }

    var regex = /__[^_]+_+/g;
    var unlinked_libraries = this.binary.match(regex);

    if (unlinked_libraries != null) {
      unlinked_libraries = unlinked_libraries.map(function(name) {
        // Remove underscores
        return name.replace(/_/g, "");
      }).sort().filter(function(name, index, arr) {
        // Remove duplicates
        if (index + 1 >= arr.length) {
          return true;
        }

        return name != arr[index + 1];
      }).join(", ");

      throw new Error("InsuranceFund contains unresolved libraries. You must deploy and link the following libraries before you can deploy a new version of InsuranceFund: " + unlinked_libraries);
    }

    var self = this;

    return new Promise(function(accept, reject) {
      var contract_class = self.web3.eth.contract(self.abi);
      var tx_params = {};
      var last_arg = args[args.length - 1];

      // It's only tx_params if it's an object and not a BigNumber.
      if (Utils.is_object(last_arg) && !Utils.is_big_number(last_arg)) {
        tx_params = args.pop();
      }

      tx_params = Utils.merge(self.class_defaults, tx_params);

      if (tx_params.data == null) {
        tx_params.data = self.binary;
      }

      // web3 0.9.0 and above calls new twice this callback twice.
      // Why, I have no idea...
      var intermediary = function(err, web3_instance) {
        if (err != null) {
          reject(err);
          return;
        }

        if (err == null && web3_instance != null && web3_instance.address != null) {
          accept(new self(web3_instance));
        }
      };

      args.push(tx_params, intermediary);
      contract_class.new.apply(contract_class, args);
    });
  };

  Contract.at = function(address) {
    if (address == null || typeof address != "string" || address.length != 42) {
      throw new Error("Invalid address passed to InsuranceFund.at(): " + address);
    }

    var contract_class = this.web3.eth.contract(this.abi);
    var contract = contract_class.at(address);

    return new this(contract);
  };

  Contract.deployed = function() {
    if (!this.address) {
      throw new Error("Cannot find deployed address: InsuranceFund not deployed or address not set.");
    }

    return this.at(this.address);
  };

  Contract.defaults = function(class_defaults) {
    if (this.class_defaults == null) {
      this.class_defaults = {};
    }

    if (class_defaults == null) {
      class_defaults = {};
    }

    var self = this;
    Object.keys(class_defaults).forEach(function(key) {
      var value = class_defaults[key];
      self.class_defaults[key] = value;
    });

    return this.class_defaults;
  };

  Contract.extend = function() {
    var args = Array.prototype.slice.call(arguments);

    for (var i = 0; i < arguments.length; i++) {
      var object = arguments[i];
      var keys = Object.keys(object);
      for (var j = 0; j < keys.length; j++) {
        var key = keys[j];
        var value = object[key];
        this.prototype[key] = value;
      }
    }
  };

  Contract.all_networks = {
  "default": {
    "abi": [
      {
        "constant": true,
        "inputs": [],
        "name": "name",
        "outputs": [
          {
            "name": "",
            "type": "string"
          }
        ],
        "type": "function"
      },
      {
        "constant": false,
        "inputs": [],
        "name": "getBalance",
        "outputs": [
          {
            "name": "",
            "type": "uint256"
          }
        ],
        "type": "function"
      },
      {
        "constant": false,
        "inputs": [],
        "name": "calculatePremiums",
        "outputs": [
          {
            "name": "premiums",
            "type": "uint256"
          }
        ],
        "type": "function"
      },
      {
        "constant": true,
        "inputs": [],
        "name": "totalSupply",
        "outputs": [
          {
            "name": "",
            "type": "uint256"
          }
        ],
        "type": "function"
      },
      {
        "constant": true,
        "inputs": [
          {
            "name": "",
            "type": "uint16"
          }
        ],
        "name": "tokenPrices",
        "outputs": [
          {
            "name": "",
            "type": "uint256"
          }
        ],
        "type": "function"
      },
      {
        "constant": true,
        "inputs": [
          {
            "name": "",
            "type": "uint16"
          }
        ],
        "name": "soldPremiums",
        "outputs": [
          {
            "name": "",
            "type": "uint256"
          }
        ],
        "type": "function"
      },
      {
        "constant": false,
        "inputs": [],
        "name": "equilibrateFunds",
        "outputs": [],
        "type": "function"
      },
      {
        "constant": false,
        "inputs": [
          {
            "name": "newTokenPriceFinney",
            "type": "uint256"
          },
          {
            "name": "mintAmount",
            "type": "uint256"
          }
        ],
        "name": "addTokenType",
        "outputs": [],
        "type": "function"
      },
      {
        "constant": true,
        "inputs": [],
        "name": "standard",
        "outputs": [
          {
            "name": "",
            "type": "string"
          }
        ],
        "type": "function"
      },
      {
        "constant": true,
        "inputs": [
          {
            "name": "_owner",
            "type": "address"
          }
        ],
        "name": "balanceOf",
        "outputs": [
          {
            "name": "b",
            "type": "uint256"
          }
        ],
        "type": "function"
      },
      {
        "constant": true,
        "inputs": [],
        "name": "owner",
        "outputs": [
          {
            "name": "",
            "type": "address"
          }
        ],
        "type": "function"
      },
      {
        "constant": true,
        "inputs": [],
        "name": "symbol",
        "outputs": [
          {
            "name": "",
            "type": "string"
          }
        ],
        "type": "function"
      },
      {
        "constant": true,
        "inputs": [
          {
            "name": "",
            "type": "uint16"
          },
          {
            "name": "",
            "type": "address"
          }
        ],
        "name": "balance",
        "outputs": [
          {
            "name": "",
            "type": "uint256"
          }
        ],
        "type": "function"
      },
      {
        "constant": false,
        "inputs": [],
        "name": "sendInvestmentInjection",
        "outputs": [],
        "type": "function"
      },
      {
        "constant": true,
        "inputs": [],
        "name": "tokenTypes",
        "outputs": [
          {
            "name": "",
            "type": "uint16"
          }
        ],
        "type": "function"
      },
      {
        "constant": false,
        "inputs": [
          {
            "name": "claim",
            "type": "uint256"
          },
          {
            "name": "claimType",
            "type": "uint16"
          },
          {
            "name": "claimer",
            "type": "address"
          },
          {
            "name": "beneficiaryAddress",
            "type": "address"
          }
        ],
        "name": "transferForClaim",
        "outputs": [],
        "type": "function"
      },
      {
        "constant": false,
        "inputs": [
          {
            "name": "newAddress",
            "type": "address"
          }
        ],
        "name": "setInvestmentFundAddress",
        "outputs": [],
        "type": "function"
      },
      {
        "constant": false,
        "inputs": [
          {
            "name": "tokenType",
            "type": "uint16"
          }
        ],
        "name": "buyInsuranceToken",
        "outputs": [
          {
            "name": "n",
            "type": "uint16"
          }
        ],
        "type": "function"
      },
      {
        "constant": false,
        "inputs": [
          {
            "name": "mintAmount",
            "type": "uint256"
          }
        ],
        "name": "mintToken",
        "outputs": [],
        "type": "function"
      },
      {
        "constant": false,
        "inputs": [],
        "name": "owned",
        "outputs": [],
        "type": "function"
      },
      {
        "constant": true,
        "inputs": [],
        "name": "investmentFund",
        "outputs": [
          {
            "name": "",
            "type": "address"
          }
        ],
        "type": "function"
      },
      {
        "constant": false,
        "inputs": [
          {
            "name": "newOwner",
            "type": "address"
          }
        ],
        "name": "transferOwnership",
        "outputs": [],
        "type": "function"
      },
      {
        "inputs": [
          {
            "name": "initialSupplyPerToken",
            "type": "uint256"
          },
          {
            "name": "tokenName",
            "type": "string"
          },
          {
            "name": "tokenSymbol",
            "type": "string"
          },
          {
            "name": "initialTokenPricesFinney",
            "type": "uint256[]"
          }
        ],
        "type": "constructor"
      },
      {
        "anonymous": false,
        "inputs": [
          {
            "indexed": true,
            "name": "from",
            "type": "address"
          },
          {
            "indexed": true,
            "name": "to",
            "type": "address"
          },
          {
            "indexed": false,
            "name": "value",
            "type": "uint256"
          }
        ],
        "name": "Transfer",
        "type": "event"
      }
    ],
    "unlinked_binary": "0x60a060405260126060527f496e737572616e6365546f6b656e20302e3100000000000000000000000000006080526002805460008290527f496e737572616e6365546f6b656e20302e31000000000000000000000000002482556100b2907f405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ace602060018316156101000260001901909216849004601f01919091048101905b808211156101db576000815560010161009e565b50506005805461ffff19166003179055604051610d0a388190039081908339810160405280805190602001909190805182019190602001805182019190602001805182019190602001505060005b81518161ffff1610156101df5761ffff81166000818152600a60209081526040808320600160a060020a03301684529091529020869055825173__ConvertLib____________________________9163f9794660918591908110156100025790602001906020020151604051827c0100000000000000000000000000000000000000000000000000000000028152600401808281526020019150506020604051808303818660325a03f415610002575050604080515161ffff8416600090815260096020529190912055506006805486019055600101610100565b5090565b6000805433600160a060020a031990911617815584516003805492819052917fc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b602060026001841615610100026000190190931692909204601f9081018390048201939289019083901061026657805160ff19168380011785555b5061029692915061009e565b8280016001018555821561025a579182015b8281111561025a578251826000505591602001919060010190610278565b50508260046000509080519060200190828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f106102ef57805160ff19168380011785555b5061031f92915061009e565b828001600101855582156102e3579182015b828111156102e3578251826000505591602001919060010190610301565b505050505050506109d6806103346000396000f3606060405236156101065760e060020a600035046306fdde03811461010857806312065fe01461016657806312f652061461017c57806318160ddd146101b25780631c5a9b50146101bb5780633deb28d6146101d357806343a155c8146101eb578063473b13d8146101fc5780635a3b7e42146102eb57806370a08231146103465780638da5cb5b1461038d57806395d89b411461039f578063a3618524146103fd578063abdac57e14610422578063b2951e0914610428578063c01fd5b214610435578063c09c52f91461046b578063c51ff935146104a0578063c634d032146104c9578063df32754b1461053a578063f20ec9c214610551578063f2fde38b14610563575b005b6040805160038054602060026001831615610100026000190190921691909104601f810182900482028401820190945283835261059593908301828280156106755780601f1061064a57610100808354040283529160200191610675565b6106035b30600160a060020a03811631905b5090565b6106035b6000805b60055461ffff168110156101785761ffff811660009081526008602052604090205490910190600101610184565b61060360065481565b61060360043560096020526000908152604090205481565b61060360043560086020526000908152604090205481565b61010661042661068e6106ed61016a565b610106600435602435600054600160a060020a039081163390911614156102e7576005805461ffff811660010161ffff19909116179055604080517ff979466000000000000000000000000000000000000000000000000000000000815260048101849052905173__ConvertLib____________________________9163f979466091602482810192602092919082900301818660325a03f41561000257505060408051516005805461ffff908116600090815260096020908152858220949094559154168152600a825282812030600160a060020a03168252909152208290555060068054820190555b5050565b6040805160028054602060018216156101000260001901909116829004601f810182900482028401820190945283835261059593908301828280156106755780601f1061064a57610100808354040283529160200191610675565b6106036004356000805b60038110156106f75761ffff81166000908152600a60209081526040808320600160a060020a038716845290915290205490910190600101610350565b610615600054600160a060020a031681565b6040805160048054602060026001831615610100026000190190921691909104601f810182900482028401820190945283835261059593908301828280156106755780601f1061064a57610100808354040283529160200191610675565b600a602090815260043560009081526040808220909252602435815220546106039081565b6101065b565b61063260055461ffff1681565b610106600435602435604435606435600080548190600160a060020a03908116339091161415610846578561067d6106ed61016a565b610106600435600054600160a060020a039081163390911614156108615780600160a060020a03166000141561084e57610002565b61063260043561ffff811660009081526009602052604081205434038181101561086457610002565b6101066004356000805433600160a060020a03908116911614156102e7575060005b60055461ffff90811690821610156102e75761ffff81166000908152600a6020908152604080832030600160a060020a03168452909152902080548301905560068054830190556001016104eb565b61010660008054600160a060020a03191633179055565b610615600754600160a060020a031681565b61010660043560005433600160a060020a03908116911614156108615760008054600160a060020a0319168217905550565b60405180806020018281038252838181518152602001915080519060200190808383829060006004602084601f0104600302600f01f150905090810190601f1680156105f55780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b60408051918252519081900360200190f35b60408051600160a060020a03929092168252519081900360200190f35b6040805161ffff929092168252519081900360200190f35b820191906000526020600020905b81548152906001019060200180831161065857829003601f168201915b505050505081565b03915060008210156106fd576107f1825b600081111561096c57600760009054906101000a9004600160a060020a0316600160a060020a0316632b36a657826040518260e060020a02815260040180905060006040518083038185886185025a03f1156100025750505050610861565b6000610964610180565b50919050565b5061ffff84166000908152600a60209081526040808320600160a060020a03871684529091528120546001919011156107f1578061ffff16600a60005060008761ffff168152602001908152602001600020600050600086600160a060020a031681526020019081526020016000206000828282505403925050819055508061ffff16600a60005060008761ffff168152602001908152602001600020600050600030600160a060020a03168152602001908152602001600020600082828250540192505081905550604051600160a060020a03841690600090849082818181858883f1935050505015156107f657610002565b610002565b30600160a060020a031633600160a060020a03167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef83604051808261ffff16815260200191505060405180910390a35b505050505050565b60078054600160a060020a031916821790555b50565b600081118015610891575060405133600160a060020a031690600090839082818181858883f19350505050155b1561089b57610002565b61ffff83166000908152600a6020908152604080832030600160a060020a0316845290915290205460019250829010156108d457610002565b61ffff8381166000818152600a6020908152604080832030600160a060020a039081168086529184528285208054978a1697889003905533168085528285208054880190559484526008835292819020805486019055805194855251929391927fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef9281900390910190a350919050565b909103919050565b600754604080517f432747a5000000000000000000000000000000000000000000000000000000008152600084810360048301529151600160a060020a03939093169263432747a592602483810193919291829003018183876161da5a03f115610002575050505056",
    "events": {
      "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef": {
        "anonymous": false,
        "inputs": [
          {
            "indexed": true,
            "name": "from",
            "type": "address"
          },
          {
            "indexed": true,
            "name": "to",
            "type": "address"
          },
          {
            "indexed": false,
            "name": "value",
            "type": "uint256"
          }
        ],
        "name": "Transfer",
        "type": "event"
      }
    },
    "updated_at": 1475576814451
  }
};

  Contract.checkNetwork = function(callback) {
    var self = this;

    if (this.network_id != null) {
      return callback();
    }

    this.web3.version.network(function(err, result) {
      if (err) return callback(err);

      var network_id = result.toString();

      // If we have the main network,
      if (network_id == "1") {
        var possible_ids = ["1", "live", "default"];

        for (var i = 0; i < possible_ids.length; i++) {
          var id = possible_ids[i];
          if (Contract.all_networks[id] != null) {
            network_id = id;
            break;
          }
        }
      }

      if (self.all_networks[network_id] == null) {
        return callback(new Error(self.name + " error: Can't find artifacts for network id '" + network_id + "'"));
      }

      self.setNetwork(network_id);
      callback();
    })
  };

  Contract.setNetwork = function(network_id) {
    var network = this.all_networks[network_id] || {};

    this.abi             = this.prototype.abi             = network.abi;
    this.unlinked_binary = this.prototype.unlinked_binary = network.unlinked_binary;
    this.address         = this.prototype.address         = network.address;
    this.updated_at      = this.prototype.updated_at      = network.updated_at;
    this.links           = this.prototype.links           = network.links || {};
    this.events          = this.prototype.events          = network.events || {};

    this.network_id = network_id;
  };

  Contract.networks = function() {
    return Object.keys(this.all_networks);
  };

  Contract.link = function(name, address) {
    if (typeof name == "function") {
      var contract = name;

      if (contract.address == null) {
        throw new Error("Cannot link contract without an address.");
      }

      Contract.link(contract.contract_name, contract.address);

      // Merge events so this contract knows about library's events
      Object.keys(contract.events).forEach(function(topic) {
        Contract.events[topic] = contract.events[topic];
      });

      return;
    }

    if (typeof name == "object") {
      var obj = name;
      Object.keys(obj).forEach(function(name) {
        var a = obj[name];
        Contract.link(name, a);
      });
      return;
    }

    Contract.links[name] = address;
  };

  Contract.contract_name   = Contract.prototype.contract_name   = "InsuranceFund";
  Contract.generated_with  = Contract.prototype.generated_with  = "3.2.0";

  // Allow people to opt-in to breaking changes now.
  Contract.next_gen = false;

  var properties = {
    binary: function() {
      var binary = Contract.unlinked_binary;

      Object.keys(Contract.links).forEach(function(library_name) {
        var library_address = Contract.links[library_name];
        var regex = new RegExp("__" + library_name + "_*", "g");

        binary = binary.replace(regex, library_address.replace("0x", ""));
      });

      return binary;
    }
  };

  Object.keys(properties).forEach(function(key) {
    var getter = properties[key];

    var definition = {};
    definition.enumerable = true;
    definition.configurable = false;
    definition.get = getter;

    Object.defineProperty(Contract, key, definition);
    Object.defineProperty(Contract.prototype, key, definition);
  });

  bootstrap(Contract);

  if (typeof module != "undefined" && typeof module.exports != "undefined") {
    module.exports = Contract;
  } else {
    // There will only be one version of this contract in the browser,
    // and we can use that.
    window.InsuranceFund = Contract;
  }
})();
