// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {NFTMarket} from "../src/NFTMarket.sol";

/// @notice 单独部署 NFTMarket，需通过环境变量传入已部署合约地址：
///   NFT_ADDRESS  - MyNFT 合约地址
///   TOKEN_ADDRESS - MyToken 合约地址
contract NFTMarketScript is Script {
    NFTMarket public market;

    function setUp() public {}

    function run() public {
        address nftAddr = vm.envAddress("NFT_ADDRESS");
        address tokenAddr = vm.envAddress("TOKEN_ADDRESS");

        vm.startBroadcast();

        market = new NFTMarket(nftAddr, tokenAddr);

        vm.stopBroadcast();
    }
}
