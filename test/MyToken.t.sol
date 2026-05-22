// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken public token;
    address public owner = address(this);
    address public user = makeAddr("user");

    uint256 constant INITIAL_SUPPLY = 1_000_000;

    function setUp() public {
        token = new MyToken(INITIAL_SUPPLY);
    }

    function test_NameAndSymbol() public view {
        assertEq(token.name(), "MyToken");
        assertEq(token.symbol(), "MTK");
    }

    function test_Decimals() public view {
        assertEq(token.decimals(), 18);
    }

    function test_InitialSupplyMintedToDeployer() public view {
        uint256 expected = INITIAL_SUPPLY * 10 ** token.decimals();
        assertEq(token.totalSupply(), expected);
        assertEq(token.balanceOf(owner), expected);
    }

    function test_Transfer() public {
        uint256 amount = 1000 * 10 ** token.decimals();
        token.transfer(user, amount);
        assertEq(token.balanceOf(user), amount);
        assertEq(token.balanceOf(owner), token.totalSupply() - amount);
    }

    function test_Transfer_RevertWhenInsufficientBalance() public {
        uint256 balance = token.balanceOf(owner);
        vm.expectRevert();
        token.transfer(user, balance + 1);
    }

    function testFuzz_Transfer(uint256 amount) public {
        amount = bound(amount, 0, token.balanceOf(owner));
        token.transfer(user, amount);
        assertEq(token.balanceOf(user), amount);
        assertEq(token.balanceOf(owner), token.totalSupply() - amount);
    }
}
