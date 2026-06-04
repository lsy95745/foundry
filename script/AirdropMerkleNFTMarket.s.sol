// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {AirdropMerkleNFTMarket} from "../src/AirdropMerkleNFTMarket.sol";

/// @notice 部署 AirdropMerkleNFTMarket
/// @dev 环境变量：
///   NFT_ADDRESS    - MyNFT 地址（必填）
///   TOKEN_ADDRESS  - 支持 EIP-2612 permit 的 ERC-20，如 MyToken2612（必填）
///   MERKLE_ROOT    - 白名单 Merkle root，bytes32 十六进制（必填）
///   MARKET_OWNER   - Ownable owner，默认 msg.sender
contract AirdropMerkleNFTMarketScript is Script {
    AirdropMerkleNFTMarket public market;

    function setUp() public {}

    function run() public {
        address nftAddr = vm.envAddress("NFT_ADDRESS");
        address tokenAddr = vm.envAddress("TOKEN_ADDRESS");
        bytes32 root = vm.envBytes32("MERKLE_ROOT");
        address owner = vm.envOr("MARKET_OWNER", msg.sender);

        vm.startBroadcast();

        market = new AirdropMerkleNFTMarket(nftAddr, tokenAddr, root, owner);

        vm.stopBroadcast();

        console2.log("AirdropMerkleNFTMarket", address(market));
        console2.log("NFT", nftAddr);
        console2.log("Payment token", tokenAddr);
        console2.logBytes32(root);
        console2.log("Owner", owner);
    }
}
