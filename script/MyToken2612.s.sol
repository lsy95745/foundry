// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {MyToken2612} from "../src/MyToken2612.sol";

/// @notice 部署 MyToken2612（EIP-2612 permit）
/// @dev 可选环境变量 INITIAL_SUPPLY，默认 1_000_000（不含 decimals）
contract MyToken2612Script is Script {
    MyToken2612 public token;

    function setUp() public {}

    function run() public {
        uint256 initialSupply = vm.envOr("INITIAL_SUPPLY", uint256(1_000_000));

        vm.startBroadcast();

        token = new MyToken2612(initialSupply);

        vm.stopBroadcast();

        console2.log("MyToken2612", address(token));
        console2.log("Initial supply (whole tokens)", initialSupply);
    }
}
