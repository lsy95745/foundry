// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {TokenBank} from "../src/TokenBank.sol";

/// @notice 部署 TokenBank
/// @dev 环境变量：
///   TOKEN_ADDRESS  - MyToken2612 等 ERC-20 地址（必填）
///   PERMIT2_ADDRESS - Permit2 地址；本地 Anvil 可部署 MockPermit2；主网传 address(0) 使用 canonical
contract TokenBankScript is Script {
    TokenBank public bank;

    function setUp() public {}

    function run() public {
        address tokenAddr = vm.envAddress("TOKEN2612_ADDRESS");
        address permit2Addr = vm.envOr("PERMIT2_ADDRESS", address(0));

        vm.startBroadcast();

        bank = new TokenBank(tokenAddr, permit2Addr);

        vm.stopBroadcast();

        console2.log("TokenBank", address(bank));
        console2.log("Token", tokenAddr);
        console2.log("Permit2", address(bank.permit2()));
    }
}
