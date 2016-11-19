#!/bin/sh

killall node
nohup sh testchain.sh &
truffle test
