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