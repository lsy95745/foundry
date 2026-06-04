// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {InscriptionFactory} from "../src/InscriptionFactory.sol";

/// @notice 部署 InscriptionFactory（含 InscriptionToken implementation）
contract InscriptionFactoryScript is Script {
    InscriptionFactory public factory;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        factory = new InscriptionFactory();

        vm.stopBroadcast();

        console2.log("InscriptionFactory", address(factory));
        console2.log("Implementation", factory.implementation());
    }
}
