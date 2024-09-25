#!/bin/bash

# VERSION='release/1.0.2-rc.5'
VERSION='release/1.1.3-rc.5'
# NETWORK='mainnet.g'
NETWORK='testnet-16200-pruned-mpt.g'
# Update and apt-get install build-essential
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get install -y build-essential

# Install golang
# wget https://dl.google.com/go/go1.15.10.linux-amd64.tar.gz
# sudo tar -xvf go1.15.10.linux-amd64.tar.gz -C /usr/local/
wget https://go.dev/dl/go1.19.3.linux-amd64.tar.gz
sudo tar -xvf go1.19.3.linux-amd64.tar.gz -C /usr/local/
# Setup golang environment variables
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
#export PATH=$GOPATH/bin:$GOROOT/bin:$PATH" >> ~/.bash_aliases
#source ~/.bash_aliases

# Checkout and build go-opera
git clone https://github.com/Fantom-foundation/go-opera.git
cd go-opera/
git checkout $VERSION
make
# Download the genesis file
cd build/
#wget https://opera.fantom.network/$NETWORK
wget https://files.fantom.network/$NETWORK
# Start a read-only node to join the selected network
# nohup ./opera --genesis $NETWORK &
nohup ./opera --genesis $NETWORK --nousb \
      --db.preset ldb-1 &
