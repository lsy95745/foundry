// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {MyToken2612} from "../src/MyToken2612.sol";
import {TokenBank} from "../src/TokenBank.sol";
import {MockPermit2} from "../test/mocks/MockPermit2.sol";

/// @notice 本地一键部署 MyToken2612 + MockPermit2 + TokenBank（适合 Anvil）
contract DeployTokenBankAllScript is Script {
    MyToken2612 public token;
    MockPermit2 public permit2;
    TokenBank public bank;

    function setUp() public {}

    function run() public {
        uint256 initialSupply = vm.envOr("INITIAL_SUPPLY", uint256(1_000_000));

        vm.startBroadcast();

        token = new MyToken2612(initialSupply);
        permit2 = new MockPermit2();
        bank = new TokenBank(address(token), address(permit2));

        vm.stopBroadcast();

        console2.log("MyToken2612", address(token));
        console2.log("MockPermit2", address(permit2));
        console2.log("TokenBank", address(bank));
    }
}
