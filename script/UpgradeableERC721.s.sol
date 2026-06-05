// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UpgradeableERC721} from "../src/UpgradeableERC721.sol";

/// @notice 部署 UUPS 可升级 ERC721（implementation + ERC1967Proxy）
/// @dev 可选环境变量：
///   NFT_NAME           - 默认 "UpgradeableNFT"
///   NFT_SYMBOL         - 默认 "UNFT"
///   NFT_OWNER          - Ownable owner，默认 msg.sender
contract UpgradeableERC721Script is Script {
    UpgradeableERC721 public implementation;
    ERC1967Proxy public proxy;

    function setUp() public {}

    function run() public {
        string memory name = vm.envOr("NFT_NAME", string("UpgradeableNFT"));
        string memory symbol = vm.envOr("NFT_SYMBOL", string("UNFT"));
        address nftOwner = vm.envOr("NFT_OWNER", msg.sender);

        vm.startBroadcast();

        implementation = new UpgradeableERC721();
        bytes memory initData = abi.encodeCall(UpgradeableERC721.initialize, (name, symbol, nftOwner));
        proxy = new ERC1967Proxy(address(implementation), initData);

        vm.stopBroadcast();

        console2.log("Implementation", address(implementation));
        console2.log("Proxy (use this address)", address(proxy));
        console2.log("Name", name);
        console2.log("Symbol", symbol);
        console2.log("Owner", nftOwner);
    }
}
