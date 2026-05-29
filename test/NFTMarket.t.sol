// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MyToken} from "../src/MyToken.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {NFTMarket} from "../src/NFTMarket.sol";

contract NFTMarketTest is Test {
    MyToken public token;
    MyNFT public nft;
    NFTMarket public market;

    address public seller = makeAddr("seller");
    address public buyer = makeAddr("buyer");

    uint256 constant WHITELIST_SIGNER_PK = 0xBEEF;
    address whitelistSigner;

    uint256 constant INITIAL_SUPPLY = 1_000_000;
    uint256 constant PRICE = 100 * 1e18;

    bytes32 private constant PERMIT_BUY_TYPEHASH =
        keccak256("PermitBuy(address buyer,uint256 tokenId,uint256 nonce,uint256 deadline)");

    function setUp() public {
        whitelistSigner = vm.addr(WHITELIST_SIGNER_PK);
        token = new MyToken(INITIAL_SUPPLY);
        nft = new MyNFT("MyNFT", "MNFT", address(this));
        market = new NFTMarket(address(nft), address(token), whitelistSigner);

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

    function test_PermitBuy() public {
        _listNFT(0, PRICE);
        uint256 deadline = block.timestamp + 1 hours;
        (uint8 v, bytes32 r, bytes32 s) = _signPermitBuy(buyer, 0, 0, deadline);

        vm.startPrank(buyer);
        token.approve(address(market), PRICE);
        market.permitBuy(0, PRICE, deadline, v, r, s);
        vm.stopPrank();

        assertEq(nft.ownerOf(0), buyer);
        assertEq(token.balanceOf(seller), 10_000 * 1e18 + PRICE);
    }

    function test_PermitBuy_RevertWhenInvalidSigner() public {
        _listNFT(0, PRICE);
        uint256 deadline = block.timestamp + 1 hours;
        (uint8 v, bytes32 r, bytes32 s) = _signPermitBuy(buyer, 0, 0, deadline);

        address notWhitelisted = makeAddr("notWhitelisted");
        address recovered = _recoveredSigner(notWhitelisted, 0, 0, deadline, v, r, s);
        vm.startPrank(notWhitelisted);
        token.approve(address(market), PRICE);
        vm.expectRevert(abi.encodeWithSelector(NFTMarket.NFTMarket__InvalidWhitelistSignature.selector, recovered));
        market.permitBuy(0, PRICE, deadline, v, r, s);
        vm.stopPrank();
    }

    function test_PermitBuy_RevertWithoutWhitelistSignature() public {
        _listNFT(0, PRICE);
        uint256 deadline = block.timestamp + 1 hours;
        (uint8 v, bytes32 r, bytes32 s) = _signPermitBuy(makeAddr("other"), 0, 0, deadline);

        address recovered = _recoveredSigner(buyer, 0, 0, deadline, v, r, s);
        vm.startPrank(buyer);
        token.approve(address(market), PRICE);
        vm.expectRevert(abi.encodeWithSelector(NFTMarket.NFTMarket__InvalidWhitelistSignature.selector, recovered));
        market.permitBuy(0, PRICE, deadline, v, r, s);
        vm.stopPrank();
    }

    function _recoveredSigner(address buyerAddr, uint256 tokenId, uint256 nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (address)
    {
        bytes32 structHash = keccak256(abi.encode(PERMIT_BUY_TYPEHASH, buyerAddr, tokenId, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", market.DOMAIN_SEPARATOR(), structHash));
        return ECDSA.recover(digest, v, r, s);
    }

    function _signPermitBuy(address buyerAddr, uint256 tokenId, uint256 nonce, uint256 deadline)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        bytes32 structHash = keccak256(abi.encode(PERMIT_BUY_TYPEHASH, buyerAddr, tokenId, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", market.DOMAIN_SEPARATOR(), structHash));
        (v, r, s) = vm.sign(WHITELIST_SIGNER_PK, digest);
    }

    function _listNFT(uint256 tokenId, uint256 price) internal {
        vm.startPrank(seller);
        nft.approve(address(market), tokenId);
        market.list(tokenId, price);
        vm.stopPrank();
    }
}
