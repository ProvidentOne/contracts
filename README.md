<img src="logo.png" width="48">

Provident One contracts [![Build Status](https://travis-ci.org/ProvidentOne/contracts.svg?branch=master)](https://travis-ci.org/ProvidentOne/contracts) [![Slack badge](https://slackin-wbssstbuyk.now.sh/badge.svg)](https://provident.one/slack)
===
Provident One is a decentralized vehicle that runs on top of the Ethereum blockchain. It features insurance plans entities can subscribe to, a way for subscribers to claim to the insurance and a investment fund with a token that gives liquidity to the fund.

It uses [Truffle](https://github.com/ConsenSys/truffle) as a contract development framework.

Right now we a are participating in the [hack.ether.camp](https://hack.ether.camp/public/provident--blockchain-backed-insurance) hackathon, so if you like the project we would appreciate your support voting the project. See [Provident One](https://hack.ether.camp/public/provident--blockchain-backed-insurance) on [hack.ether.camp](https://hack.ether.camp).

## Architecture

If you glance over the `contracts/` directory, you will find a not very well known way of architecting Ethereum contracts. This architecture has been chosen to allow for code modularity and allowing good upgradability of certain parts of the system.

It is explained in more detail in the [whitepaper section 3](https://github.com/ProvidentOne/whitepaper/blob/master/whitepaper.md#3-implementation), Implementation.

## Development

The recommended workflow for developing and contributing to the contracts is using the `truffle console` for compiling, deploying and playing with contracts. In order to do that, just:

```sh
$ npm install -g truffle ethereumjs-testrpc

$ testrpc // leave process running
$ truffle console
> compile
Compiling InsuranceFund.sol
...
> migrate --reset
...
> InsuranceFund.deployed()
Insurance Fund deployed eth-pudding object
```

You need to be running a Ethereum node with RPC enabled for Truffle to connect. In this example, we are just running it with [testrpc](https://github.com/ethereumjs/testrpc), which is a in-memory RPC enabled node written in JS, that is very fast for development and testing. This can be run also on a private blockchain running with [geth](https://github.com/ethereum/go-ethereum), the Ethereum testnet or the mainnet. See [Truffle network configuration](http://truffleframework.com/docs/advanced/networks) for more info.


## Testing

We have been finding TDD to be a very good way to develop Solidity contracts, as it gives the peace of mind that you are not creating bugs as you continue developing.

For running in the CI, a Docker image has been created for the sake of simplicity. It starts a testrpc node and runs the tests against it.

Right now, there are lots of tests missing to cover the entire functionallity of the system. Help with tests is needed and apprecited.

No Pull Requests will be merged unless there is a test case for that functionallity and all tests are passing in the CI.


## Community [![Slack badge](https://slackin-wbssstbuyk.now.sh/badge.svg)](https://provident.one/slack)

We truly believe Provident One to be a community effort. If you are interested in its development, don't hesitate to join the community on [Slack](https://provident.one/slack)

## License

Provident One is licensed under the [GNU AGPLv3 license](https://github.com/ProvidentOne/contracts/blob/master/LICENSE.md)
