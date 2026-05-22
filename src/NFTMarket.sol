// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ITokenReceiver} from "./interfaces/ITokenReceiver.sol";

/// @title NFTMarket
/// @dev 使用 ERC20 Token 购买托管在市场的 NFT
contract NFTMarket is ITokenReceiver, ReentrancyGuard {
    IERC721 public immutable nft;
    IERC20 public immutable paymentToken;

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(uint256 tokenId => Listing) public listings;

    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Sold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event Delisted(uint256 indexed tokenId, address indexed seller);

    error NFTMarket__NotOwner();
    error NFTMarket__NotListed();
    error NFTMarket__ZeroPrice();
    error NFTMarket__WrongAmount();
    error NFTMarket__OnlyPaymentToken();
    error NFTMarket__TransferFailed();

    constructor(address nft_, address paymentToken_) {
        nft = IERC721(nft_);
        paymentToken = IERC20(paymentToken_);
    }

    /// @notice 上架 NFT，NFT 转入市场托管
    /// @param tokenId NFT id
    /// @param price 售价（TOKEN 数量）
    function list(uint256 tokenId, uint256 price) external nonReentrant {
        if (price == 0) revert NFTMarket__ZeroPrice();
        if (nft.ownerOf(tokenId) != msg.sender) revert NFTMarket__NotOwner();

        nft.transferFrom(msg.sender, address(this), tokenId);
        listings[tokenId] = Listing({seller: msg.sender, price: price});

        emit Listed(tokenId, msg.sender, price);
    }

    /// @notice 使用 TOKEN 购买 NFT（需先 approve 给市场）
    /// @param tokenId NFT id
    /// @param amount 支付的 TOKEN 数量，须等于挂牌价
    function buyNFT(uint256 tokenId, uint256 amount) external nonReentrant {
        _purchase(tokenId, amount, msg.sender, false);
    }

    /// @notice 扩展 ERC20 转账回调：买家调用 token.transferWithData(market, amount, abi.encode(tokenId))
    function tokensReceived(address from, uint256 amount, bytes calldata data) external nonReentrant {
        if (msg.sender != address(paymentToken)) revert NFTMarket__OnlyPaymentToken();
        uint256 tokenId = abi.decode(data, (uint256));
        _purchase(tokenId, amount, from, true);
    }

    /// @notice 卖家下架并取回 NFT
    function delist(uint256 tokenId) external nonReentrant {
        Listing memory listing = listings[tokenId];
        if (listing.seller == address(0)) revert NFTMarket__NotListed();
        if (listing.seller != msg.sender) revert NFTMarket__NotOwner();

        delete listings[tokenId];
        nft.transferFrom(address(this), msg.sender, tokenId);

        emit Delisted(tokenId, msg.sender);
    }

    function _purchase(uint256 tokenId, uint256 amount, address buyer, bool paidToMarket) internal {
        Listing memory listing = listings[tokenId];
        if (listing.seller == address(0)) revert NFTMarket__NotListed();
        if (amount != listing.price) revert NFTMarket__WrongAmount();

        address seller = listing.seller;
        delete listings[tokenId];

        if (paidToMarket) {
            if (!paymentToken.transfer(seller, listing.price)) revert NFTMarket__TransferFailed();
        } else {
            if (!paymentToken.transferFrom(buyer, seller, listing.price)) revert NFTMarket__TransferFailed();
        }

        nft.transferFrom(address(this), buyer, tokenId);

        emit Sold(tokenId, seller, buyer, listing.price);
    }
}
