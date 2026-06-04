// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InscriptionFactory} from "../src/InscriptionFactory.sol";
import {InscriptionToken} from "../src/InscriptionToken.sol";

contract InscriptionFactoryTest is Test {
    InscriptionFactory public factory;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    uint256 constant TOTAL_SUPPLY = 10_000;
    uint256 constant PER_MINT = 1_000;

    event InscriptionDeployed(
        address indexed token, string symbol, uint256 totalSupply, uint256 perMint, address indexed deployer
    );
    event InscriptionMinted(address indexed token, address indexed minter, uint256 amount);

    function setUp() public {
        factory = new InscriptionFactory();
    }

    function test_DeployInscription() public {
        address tokenAddr = factory.deployInscription("MEME", TOTAL_SUPPLY, PER_MINT);

        assertTrue(factory.isInscription(tokenAddr));
        assertEq(InscriptionToken(tokenAddr).cap(), TOTAL_SUPPLY);
        assertEq(InscriptionToken(tokenAddr).perMint(), PER_MINT);
        assertEq(InscriptionToken(tokenAddr).symbol(), "MEME");
        assertEq(InscriptionToken(tokenAddr).name(), "Inscription MEME");
        assertEq(InscriptionToken(tokenAddr).decimals(), 0);
        assertEq(InscriptionToken(tokenAddr).totalSupply(), 0);
        assertEq(InscriptionToken(tokenAddr).factory(), address(factory));
    }

    function test_EmitInscriptionDeployed() public {
        vm.expectEmit(false, true, false, true);
        emit InscriptionDeployed(address(0), "MEME", TOTAL_SUPPLY, PER_MINT, address(this));

        address tokenAddr = factory.deployInscription("MEME", TOTAL_SUPPLY, PER_MINT);
        assertTrue(tokenAddr != address(0));
    }

    function test_MultipleDeploymentsAreUnique() public {
        address tokenA = factory.deployInscription("MEME", TOTAL_SUPPLY, PER_MINT);
        address tokenB = factory.deployInscription("PEPE", TOTAL_SUPPLY, PER_MINT);

        assertTrue(tokenA != tokenB);
        assertTrue(factory.isInscription(tokenA));
        assertTrue(factory.isInscription(tokenB));
        assertEq(InscriptionToken(tokenA).symbol(), "MEME");
        assertEq(InscriptionToken(tokenB).symbol(), "PEPE");
    }

    function test_MintInscription() public {
        address tokenAddr = factory.deployInscription("MEME", TOTAL_SUPPLY, PER_MINT);

        vm.expectEmit(true, true, false, true);
        emit InscriptionMinted(tokenAddr, alice, PER_MINT);

        vm.prank(alice);
        factory.mintInscription(tokenAddr);

        assertEq(InscriptionToken(tokenAddr).balanceOf(alice), PER_MINT);
        assertEq(InscriptionToken(tokenAddr).totalSupply(), PER_MINT);
    }

    function test_MintUntilCap() public {
        address tokenAddr = factory.deployInscription("MEME", TOTAL_SUPPLY, PER_MINT);

        for (uint256 i; i < TOTAL_SUPPLY / PER_MINT; i++) {
            vm.prank(i % 2 == 0 ? alice : bob);
            factory.mintInscription(tokenAddr);
        }

        assertEq(InscriptionToken(tokenAddr).totalSupply(), TOTAL_SUPPLY);
        assertEq(InscriptionToken(tokenAddr).balanceOf(alice), 5 * PER_MINT);
        assertEq(InscriptionToken(tokenAddr).balanceOf(bob), 5 * PER_MINT);

        vm.expectRevert(InscriptionToken.InscriptionToken__SupplyExceeded.selector);
        factory.mintInscription(tokenAddr);
    }

    function test_TransferAfterMint() public {
        address tokenAddr = factory.deployInscription("MEME", TOTAL_SUPPLY, PER_MINT);

        vm.prank(alice);
        factory.mintInscription(tokenAddr);

        vm.prank(alice);
        assertTrue(InscriptionToken(tokenAddr).transfer(bob, 500));

        assertEq(InscriptionToken(tokenAddr).balanceOf(alice), PER_MINT - 500);
        assertEq(InscriptionToken(tokenAddr).balanceOf(bob), 500);
    }

    function test_CloneIsMinimalProxy() public {
        address tokenAddr = factory.deployInscription("MEME", TOTAL_SUPPLY, PER_MINT);

        assertTrue(tokenAddr.code.length > 0);
        assertTrue(tokenAddr.code.length < 100);
        assertTrue(factory.implementation().code.length > 100);
    }

    function test_FuzzDeployAndMint(uint256 totalSupply, uint256 perMint) public {
        totalSupply = bound(totalSupply, 1, 1_000_000_000);
        perMint = bound(perMint, 1, totalSupply);

        address tokenAddr = factory.deployInscription("FUZZ", totalSupply, perMint);

        vm.prank(alice);
        factory.mintInscription(tokenAddr);

        assertEq(InscriptionToken(tokenAddr).balanceOf(alice), perMint);
        assertEq(InscriptionToken(tokenAddr).totalSupply(), perMint);
    }

    function test_RevertWhenMintUnknownToken() public {
        vm.expectRevert(InscriptionFactory.InscriptionFactory__UnknownToken.selector);
        factory.mintInscription(makeAddr("fake"));
    }

    function test_RevertWhenDirectMint() public {
        address tokenAddr = factory.deployInscription("MEME", TOTAL_SUPPLY, PER_MINT);

        vm.expectRevert(InscriptionToken.InscriptionToken__NotFactory.selector);
        InscriptionToken(tokenAddr).mint(alice);
    }

    function test_RevertWhenEmptySymbol() public {
        vm.expectRevert(InscriptionFactory.InscriptionFactory__EmptySymbol.selector);
        factory.deployInscription("", TOTAL_SUPPLY, PER_MINT);
    }

    function test_RevertWhenZeroTotalSupply() public {
        vm.expectRevert(InscriptionFactory.InscriptionFactory__InvalidSupply.selector);
        factory.deployInscription("MEME", 0, PER_MINT);
    }

    function test_RevertWhenZeroPerMint() public {
        vm.expectRevert(InscriptionFactory.InscriptionFactory__InvalidPerMint.selector);
        factory.deployInscription("MEME", TOTAL_SUPPLY, 0);
    }

    function test_RevertWhenPerMintExceedsTotalSupply() public {
        vm.expectRevert(InscriptionFactory.InscriptionFactory__InvalidPerMint.selector);
        factory.deployInscription("MEME", TOTAL_SUPPLY, TOTAL_SUPPLY + 1);
    }

    function test_RevertWhenDoubleInitializeClone() public {
        address tokenAddr = factory.deployInscription("MEME", TOTAL_SUPPLY, PER_MINT);

        vm.expectRevert(InscriptionToken.InscriptionToken__AlreadyInitialized.selector);
        InscriptionToken(tokenAddr).initialize(address(this), "HACK", 1, 1);
    }
}
