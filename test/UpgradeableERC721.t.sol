// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UpgradeableERC721} from "../src/UpgradeableERC721.sol";
import {UpgradeableERC721V2} from "../src/UpgradeableERC721V2.sol";

contract UpgradeableERC721Test is Test {
    UpgradeableERC721 public implementation;
    ERC1967Proxy public proxy;
    UpgradeableERC721 public nft;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() public {
        implementation = new UpgradeableERC721();

        bytes memory initData = abi.encodeCall(
            UpgradeableERC721.initialize, ("UpgradeableNFT", "UNFT", owner)
        );
        proxy = new ERC1967Proxy(address(implementation), initData);
        nft = UpgradeableERC721(address(proxy));
    }

    function test_Initialize() public view {
        assertEq(nft.name(), "UpgradeableNFT");
        assertEq(nft.symbol(), "UNFT");
        assertEq(nft.owner(), owner);
        assertEq(nft.version(), "1.0.0");
    }

    function test_Mint() public {
        vm.prank(owner);
        uint256 tokenId = nft.mint(user, "ipfs://meta/0");

        assertEq(tokenId, 0);
        assertEq(nft.ownerOf(0), user);
        assertEq(nft.tokenURI(0), "ipfs://meta/0");
    }

    function test_SetBaseURI() public {
        vm.prank(owner);
        nft.setBaseURI("ipfs://base/");

        vm.prank(owner);
        nft.mint(user, "0.json");

        assertEq(nft.tokenURI(0), "ipfs://base/0.json");
    }

    function test_UpgradeToV2() public {
        UpgradeableERC721V2 v2 = new UpgradeableERC721V2();

        vm.prank(owner);
        nft.upgradeToAndCall(address(v2), "");

        assertEq(nft.version(), "2.0.0");

        vm.prank(owner);
        uint256 tokenId = nft.mint(user, "ipfs://after-upgrade/1");
        assertEq(nft.ownerOf(tokenId), user);
    }

    function test_RevertWhenMintNotOwner() public {
        vm.prank(user);
        vm.expectRevert();
        nft.mint(user, "ipfs://x");
    }
}
