// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {UpgradeableERC721} from "../src/UpgradeableERC721.sol";
import {UpgradeableERC721V2} from "../src/UpgradeableERC721V2.sol";

/// @notice 将已部署的 UUPS Proxy 升级到 UpgradeableERC721V2
/// @dev 环境变量：
///   UPGRADEABLE_ERC721_PROXY - V1 部署时打印的 Proxy 地址（必填）
/// @dev 调用者须为 Proxy 的 owner（initialize 时设置的 NFT_OWNER）
contract UpgradeableERC721V2Script is Script {
    UpgradeableERC721V2 public implementationV2;

    function setUp() public {}

    function run() public {
        address proxyAddr = vm.envAddress("UPGRADEABLE_ERC721_PROXY");
        UpgradeableERC721 proxy = UpgradeableERC721(proxyAddr);

        string memory versionBefore = proxy.version();
        address ownerBefore = proxy.owner();

        vm.startBroadcast();

        implementationV2 = new UpgradeableERC721V2();
        proxy.upgradeToAndCall(address(implementationV2), "");

        vm.stopBroadcast();

        console2.log("Proxy", proxyAddr);
        console2.log("Owner", ownerBefore);
        console2.log("Version before", versionBefore);
        console2.log("V2 Implementation", address(implementationV2));
        console2.log("Version after", proxy.version());
    }
}
