# TideBitSWAP-Contract
v1.0.0 is forked from [Uniswap V2](https://github.com/Uniswap/v2-core)

## Prepare Environment
```shell
sudo npm i -g truffle
git clone https://github.com/CAFECA-IO/TideBitSWAP-Contract/
cd TideBitSWAP-Contract
npm i
```

## Create Wallet, Compile and Deploy
```shell
mkdir private
echo 'module.exports = "your mnemonic phrase here ...";' > private/wallet.js
truffle migrate
```