// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Hashes} from "@openzeppelin/contracts/utils/cryptography/Hashes.sol";
import {MyToken2612} from "../src/MyToken2612.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {AirdropMerkleNFTMarket} from "../src/AirdropMerkleNFTMarket.sol";

contract AirdropMerkleNFTMarketTest is Test {
    MyToken2612 public token;
    MyNFT public nft;
    AirdropMerkleNFTMarket public market;

    address public seller = makeAddr("seller");
    address public outsider = makeAddr("outsider");

    uint256 constant BUYER_PK = 0xB0B0;
    address public buyer;
    uint256 constant PRICE = 100 * 1e18;

    bytes32 public merkleRoot;

    function setUp() public {
        buyer = vm.addr(BUYER_PK);

        address[] memory accounts = new address[](2);
        accounts[0] = buyer;
        accounts[1] = outsider;
        merkleRoot = _buildRoot(accounts);

        token = new MyToken2612(1_000_000);
        nft = new MyNFT("MyNFT", "MNFT", address(this));
        market = new AirdropMerkleNFTMarket(address(nft), address(token), merkleRoot, address(this));

        token.transfer(seller, 10_000 * 1e18);
        token.transfer(buyer, 10_000 * 1e18);

        nft.mint(seller, "ipfs://seller/0");
    }

    function test_ListAndDelist() public {
        _list(0, PRICE);

        vm.prank(seller);
        market.delist(0);

        assertEq(nft.ownerOf(0), seller);
    }

    function test_ClaimNFT_WithMulticall_PermitAndClaim() public {
        _list(0, PRICE);
        uint256 payAmount = market.discountedPrice(PRICE);
        bytes32[] memory proof = _proofFor(buyer);

        uint256 deadline = block.timestamp + 1 hours;
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(buyer, payAmount, deadline, 0);

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(AirdropMerkleNFTMarket.permitPrePay, (buyer, uint256(0), deadline, v, r, s));
        calls[1] = abi.encodeCall(AirdropMerkleNFTMarket.claimNFT, (uint256(0), proof));

        vm.prank(buyer);
        market.multicall(calls);

        assertEq(nft.ownerOf(0), buyer);
        assertEq(token.balanceOf(seller), 10_000 * 1e18 + payAmount);
        assertEq(token.balanceOf(buyer), 10_000 * 1e18 - payAmount);
        (,, bool active) = market.prepays(buyer);
        assertFalse(active);
    }

    function test_ClaimNFT_RevertWhenNotInMerkleTree() public {
        address notWhitelisted = vm.addr(0xA11CE);
        token.transfer(notWhitelisted, 10_000 * 1e18);

        _list(0, PRICE);
        bytes32[] memory proof = _proofFor(buyer);

        uint256 deadline = block.timestamp + 1 hours;
        (uint8 v, bytes32 r, bytes32 s) =
            _signPermitWithPk(0xA11CE, notWhitelisted, market.discountedPrice(PRICE), deadline, 0);

        bytes[] memory calls = new bytes[](2);
        calls[0] =
            abi.encodeCall(AirdropMerkleNFTMarket.permitPrePay, (notWhitelisted, uint256(0), deadline, v, r, s));
        calls[1] = abi.encodeCall(AirdropMerkleNFTMarket.claimNFT, (uint256(0), proof));

        vm.prank(notWhitelisted);
        vm.expectRevert(AirdropMerkleNFTMarket.AirdropMerkleNFTMarket__NotWhitelisted.selector);
        market.multicall(calls);
    }

    function test_ClaimNFT_RevertWithoutPrepay() public {
        _list(0, PRICE);
        bytes32[] memory proof = _proofFor(buyer);

        vm.prank(buyer);
        vm.expectRevert(AirdropMerkleNFTMarket.AirdropMerkleNFTMarket__PrepayNotActive.selector);
        market.claimNFT(0, proof);
    }

    function test_DiscountedPriceIsHalf() public view {
        assertEq(market.discountedPrice(200), 100);
        assertEq(market.discountedPrice(PRICE), PRICE / 2);
    }

    function _list(uint256 tokenId, uint256 price) internal {
        vm.startPrank(seller);
        nft.approve(address(market), tokenId);
        market.list(tokenId, price);
        vm.stopPrank();
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(account))));
    }

    function _buildRoot(address[] memory accounts) internal pure returns (bytes32) {
        uint256 n = accounts.length;
        bytes32[] memory layer = new bytes32[](n);
        for (uint256 i = 0; i < n; i++) {
            layer[i] = _leaf(accounts[i]);
        }
        while (n > 1) {
            uint256 next = (n + 1) / 2;
            bytes32[] memory nextLayer = new bytes32[](next);
            for (uint256 i = 0; i < n; i += 2) {
                if (i + 1 < n) {
                    nextLayer[i / 2] = Hashes.commutativeKeccak256(layer[i], layer[i + 1]);
                } else {
                    nextLayer[i / 2] = layer[i];
                }
            }
            layer = nextLayer;
            n = next;
        }
        return layer[0];
    }

    function _proofFor(address account) internal view returns (bytes32[] memory) {
        bytes32 leafOutsider = _leaf(outsider);
        bytes32 leafBuyer = _leaf(buyer);
        if (account == buyer) {
            bytes32[] memory proof = new bytes32[](1);
            proof[0] = leafOutsider;
            return proof;
        }
        if (account == outsider) {
            bytes32[] memory proof = new bytes32[](1);
            proof[0] = leafBuyer;
            return proof;
        }
        revert("unknown account");
    }

    function _signPermit(address owner, uint256 value, uint256 deadline, uint256 nonce)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        return _signPermitWithPk(BUYER_PK, owner, value, deadline, nonce);
    }

    function _signPermitWithPk(uint256 pk, address owner, uint256 value, uint256 deadline, uint256 nonce)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                address(market),
                value,
                nonce,
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (v, r, s) = vm.sign(pk, digest);
    }
}
