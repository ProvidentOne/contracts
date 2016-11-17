#!/bin/sh

killall node
nohup sh start_testrpc.sh &
truffle test
