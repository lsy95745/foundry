## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```




forge script script/MyNFT.s.sol --account lsy --rpc-url sepolia --broadcast --verify



export NFT=0xbe5b554e68847ab94a606791df3f242bbe637203
cast call $NFT "owner()(address)" --rpc-url sepolia

export Account=0xb68A961890C2d6d0F87E2114b75887e0eA3801E6


cast send $NFT \
  "mint(address,string)" \
  $Account \
  "ipfs://QmSRg6Fwe7NTHLp7qzu4wmzKgGEmPU269Yw9BZ5DevtSAE" \
  --rpc-url sepolia \
  --account lsy


forge script script/NFTMarket.s.sol --account lsy --rpc-url sepolia --broadcast --verify


forge verify-contract \
  0x2049114d411189a2c1710a8514dadeaf66943939 \
  src/NFTMarket.sol:NFTMarket \
  --chain sepolia \
  --rpc-url sepolia \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address)" \
    0xbe5b554e68847ab94a606791df3f242bbe637203 \
    0xfa8021606b9ee9555a64142ff0b81b31ec15ea82) \
  --watch


  1. 在foundry文件中创建一个使用 EIP2612 标准（基于 Openzepplin 库）的 MyToken2612 合约
  2. 创建一个TokenBank 存款取款合约 并支持 permitDeposit函数 以支持离线签名授权（permit）进行存款
  3. NFTMarket.sol合约 添加功能 permitBuy() 实现只有离线授权的白名单地址才可以购买 NFT
  白名单具体实现逻辑为：项目方给白名单地址签名，白名单用户拿到签名信息后，传给 permitBuy() 函数，在permitBuy()中判断时候是经过许可的白名单用户，如果是，才可以进行后续购买，否则 revert 。

  给TokenBank.sol合约添加一个方法 depositWithPermit2()， 这个方式使用 permit2 进行签名授权转账来进行存款

  web3-web项目里调用 TokenBank合约进行 permitDeposit 以支持离线签名授权的方式存款
  MyToken2612



