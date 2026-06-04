// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InscriptionToken} from "../src/InscriptionToken.sol";

contract InscriptionTokenTest is Test {
    InscriptionToken public implementation;

    function setUp() public {
        implementation = new InscriptionToken();
    }

    function test_ImplementationIsLocked() public {
        vm.expectRevert(InscriptionToken.InscriptionToken__AlreadyInitialized.selector);
        implementation.initialize(address(this), "MEME", 10_000, 1_000);
    }

    function test_ImplementationUsesDefaultMetadata() public view {
        assertEq(implementation.name(), "Inscription");
        assertEq(implementation.symbol(), "INS");
        assertEq(implementation.decimals(), 0);
    }
}
