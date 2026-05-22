// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenScript is Script {
    MyToken public myToken;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // 部署MyToken合约，初始供应量为1,000,000代币
        myToken = new MyToken(1_000_000);

        vm.stopBroadcast();
    }
}
