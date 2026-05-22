// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {NFTMarket} from "../src/NFTMarket.sol";

contract NFTMarketTest is Test {
    MyToken public token;
    MyNFT public nft;
    NFTMarket public market;

    address public seller = makeAddr("seller");
    address public buyer = makeAddr("buyer");

    uint256 constant INITIAL_SUPPLY = 1_000_000;
    uint256 constant PRICE = 100 * 1e18;

    function setUp() public {
        token = new MyToken(INITIAL_SUPPLY);
        nft = new MyNFT("MyNFT", "MNFT", address(this));
        market = new NFTMarket(address(nft), address(token));

        token.transfer(seller, 10_000 * 1e18);
        token.transfer(buyer, 10_000 * 1e18);

        nft.mint(seller, "ipfs://seller/0");
    }

    function test_List() public {
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(0, PRICE);
        vm.stopPrank();

        (address listedSeller, uint256 price) = market.listings(0);
        assertEq(listedSeller, seller);
        assertEq(price, PRICE);
        assertEq(nft.ownerOf(0), address(market));
    }

    function test_BuyNFT() public {
        _listNFT(0, PRICE);

        vm.startPrank(buyer);
        token.approve(address(market), PRICE);
        market.buyNFT(0, PRICE);
        vm.stopPrank();

        assertEq(nft.ownerOf(0), buyer);
        assertEq(token.balanceOf(seller), 10_000 * 1e18 + PRICE);
        assertEq(token.balanceOf(buyer), 10_000 * 1e18 - PRICE);
        (address listedSeller,) = market.listings(0);
        assertEq(listedSeller, address(0));
    }

    function test_BuyNFT_RevertWhenWrongAmount() public {
        _listNFT(0, PRICE);

        vm.startPrank(buyer);
        token.approve(address(market), PRICE);
        vm.expectRevert(NFTMarket.NFTMarket__WrongAmount.selector);
        market.buyNFT(0, PRICE - 1);
        vm.stopPrank();
    }

    function test_TokensReceived_BuyViaTransferWithData() public {
        _listNFT(0, PRICE);

        vm.startPrank(buyer);
        token.transferWithData(address(market), PRICE, abi.encode(uint256(0)));
        vm.stopPrank();

        assertEq(nft.ownerOf(0), buyer);
        assertEq(token.balanceOf(seller), 10_000 * 1e18 + PRICE);
        assertEq(token.balanceOf(address(market)), 0);
    }

    function test_Delist() public {
        _listNFT(0, PRICE);

        vm.prank(seller);
        market.delist(0);

        assertEq(nft.ownerOf(0), seller);
        (address listedSeller,) = market.listings(0);
        assertEq(listedSeller, address(0));
    }

    function _listNFT(uint256 tokenId, uint256 price) internal {
        vm.startPrank(seller);
        nft.approve(address(market), tokenId);
        market.list(tokenId, price);
        vm.stopPrank();
    }
}
