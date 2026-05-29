// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {NFTMarket} from "../src/NFTMarket.sol";

/// @notice 部署 NFTMarket
/// @dev 环境变量：
///   NFT_ADDRESS       - MyNFT 合约地址（必填）
///   TOKEN_ADDRESS     - 支付用 ERC-20 地址（必填）
///   WHITELIST_SIGNER  - permitBuy 白名单签名地址，默认 msg.sender
contract NFTMarketScript is Script {
    NFTMarket public market;

    function setUp() public {}

    function run() public {
        address nftAddr = vm.envAddress("NFT_ADDRESS");
        address tokenAddr = vm.envAddress("TOKEN_ADDRESS");
        address whitelistSigner = vm.envOr("WHITELIST_SIGNER", msg.sender);

        vm.startBroadcast();

        market = new NFTMarket(nftAddr, tokenAddr, whitelistSigner);

        vm.stopBroadcast();

        console2.log("NFTMarket", address(market));
        console2.log("NFT", nftAddr);
        console2.log("Payment token", tokenAddr);
        console2.log("Whitelist signer", whitelistSigner);
    }
}
