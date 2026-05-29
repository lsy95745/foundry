// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {ITokenReceiver} from "./interfaces/ITokenReceiver.sol";

/// @title NFTMarket
/// @dev 使用 ERC20 Token 购买托管在市场的 NFT；`permitBuy` 需项目方对白名单地址的离线签名
contract NFTMarket is ITokenReceiver, ReentrancyGuard, EIP712, Nonces {
    IERC721 public immutable nft;
    IERC20 public immutable paymentToken;
    address public immutable whitelistSigner;

    bytes32 private constant PERMIT_BUY_TYPEHASH =
        keccak256("PermitBuy(address buyer,uint256 tokenId,uint256 nonce,uint256 deadline)");

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
    error NFTMarket__ExpiredSignature(uint256 deadline);
    error NFTMarket__InvalidWhitelistSignature(address signer);

    constructor(address nft_, address paymentToken_, address whitelistSigner_) EIP712("NFTMarket", "1") {
        nft = IERC721(nft_);
        paymentToken = IERC20(paymentToken_);
        whitelistSigner = whitelistSigner_;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
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

    /// @notice 白名单用户凭项目方离线签名购买 NFT
    /// @param tokenId 要购买的 NFT id
    /// @param amount 支付的 TOKEN 数量，须等于挂牌价
    /// @param deadline 签名过期时间
    /// @param v ECDSA 签名分量
    /// @param r ECDSA 签名分量
    /// @param s ECDSA 签名分量
    function permitBuy(uint256 tokenId, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        nonReentrant
    {
        if (block.timestamp > deadline) revert NFTMarket__ExpiredSignature(deadline);

        bytes32 structHash = keccak256(
            abi.encode(PERMIT_BUY_TYPEHASH, msg.sender, tokenId, _useNonce(msg.sender), deadline)
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, v, r, s);
        if (signer != whitelistSigner) revert NFTMarket__InvalidWhitelistSignature(signer);

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
