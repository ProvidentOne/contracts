#!/bin/sh

nohup sh -c testrpc -p 8811 &
truffle test --network testing
