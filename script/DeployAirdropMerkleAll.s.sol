// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Hashes} from "@openzeppelin/contracts/utils/cryptography/Hashes.sol";
import {MyToken2612} from "../src/MyToken2612.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {AirdropMerkleNFTMarket} from "../src/AirdropMerkleNFTMarket.sol";

/// @notice 本地一键部署 MyToken2612 + MyNFT + AirdropMerkleNFTMarket（含示例 Merkle root）
/// @dev 可选环境变量：
///   WHITELIST_ADDRESS_0 / WHITELIST_ADDRESS_1 - 白名单地址，默认 Anvil 账户 1、2
contract DeployAirdropMerkleAllScript is Script {
    MyToken2612 public token;
    MyNFT public nft;
    AirdropMerkleNFTMarket public market;

    function setUp() public {}

    function run() public {
        address w0 = vm.envOr("WHITELIST_ADDRESS_0", address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8));
        address w1 = vm.envOr("WHITELIST_ADDRESS_1", address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));
        bytes32 root = _merkleRootTwo(w0, w1);

        vm.startBroadcast();

        token = new MyToken2612(1_000_000);
        nft = new MyNFT("MyNFT", "MNFT", msg.sender);
        market = new AirdropMerkleNFTMarket(address(nft), address(token), root, msg.sender);

        vm.stopBroadcast();

        console2.log("MyToken2612", address(token));
        console2.log("MyNFT", address(nft));
        console2.log("AirdropMerkleNFTMarket", address(market));
        console2.log("Whitelist 0", w0);
        console2.log("Whitelist 1", w1);
        console2.logBytes32(root);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(account))));
    }

    function _merkleRootTwo(address a, address b) internal pure returns (bytes32) {
        bytes32 leafA = _leaf(a);
        bytes32 leafB = _leaf(b);
        return Hashes.commutativeKeccak256(leafA, leafB);
    }
}
