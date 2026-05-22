// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MyNFT} from "../src/MyNFT.sol";

contract MyNFTScript is Script {
    MyNFT public myNFT;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // 部署 MyNFT，部署者为 initialOwner
        myNFT = new MyNFT("MyNFT", "MNFT", msg.sender);

        vm.stopBroadcast();
    }
}
