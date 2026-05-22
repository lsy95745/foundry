// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MyNFT} from "../src/MyNFT.sol";

contract MyNFTTest is Test {
    MyNFT public nft;
    address public owner = address(this);
    address public user = makeAddr("user");

    function setUp() public {
        nft = new MyNFT("MyNFT", "MNFT", owner);
    }

    function test_NameAndSymbol() public view {
        assertEq(nft.name(), "MyNFT");
        assertEq(nft.symbol(), "MNFT");
    }

    function test_Mint() public {
        string memory uri = "ipfs://QmExample/1";
        uint256 tokenId = nft.mint(user, uri);

        assertEq(tokenId, 0);
        assertEq(nft.ownerOf(0), user);
        assertEq(nft.balanceOf(user), 1);
        assertEq(nft.tokenURI(0), uri);
    }

    function test_Mint_RevertWhenNotOwner() public {
        vm.prank(user);
        vm.expectRevert();
        nft.mint(user, "ipfs://x");
    }

    function test_Transfer() public {
        nft.mint(owner, "ipfs://1");
        nft.transferFrom(owner, user, 0);
        assertEq(nft.ownerOf(0), user);
    }
}
