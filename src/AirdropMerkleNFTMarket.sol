// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title AirdropMerkleNFTMarket
/// @notice NFT 市场：Merkle 白名单用户以挂牌价 50% 购买；通过 multicall(delegatecall) 一次完成 permit + claim
/// @dev 白名单 leaf 与 OpenZeppelin StandardMerkleTree 一致：keccak256(bytes.concat(keccak256(abi.encode(address))))
contract AirdropMerkleNFTMarket is Multicall, ReentrancyGuard, Ownable {
    IERC721 public immutable nft;
    IERC20Permit public immutable paymentToken;

    /// @dev 白名单 Merkle root（可用 setMerkleRoot 更新）
    bytes32 public merkleRoot;

    /// @dev 白名单折扣：5000 = 50%
    uint256 public constant DISCOUNT_BPS = 5000;
    uint256 public constant BPS_DENOMINATOR = 10_000;

    struct Listing {
        address seller;
        uint256 price;
    }

    /// @dev permitPrePay 后暂存，供同笔 multicall 内 claimNFT 使用
    struct PrepayState {
        uint256 tokenId;
        uint256 amount;
        bool active;
    }

    mapping(uint256 tokenId => Listing) public listings;
    mapping(address buyer => PrepayState) public prepays;

    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Sold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 pricePaid, uint256 listPrice);
    event Delisted(uint256 indexed tokenId, address indexed seller);
    event MerkleRootUpdated(bytes32 indexed oldRoot, bytes32 indexed newRoot);

    error AirdropMerkleNFTMarket__NotOwner();
    error AirdropMerkleNFTMarket__NotListed();
    error AirdropMerkleNFTMarket__ZeroPrice();
    error AirdropMerkleNFTMarket__NotWhitelisted();
    error AirdropMerkleNFTMarket__InvalidPermitOwner();
    error AirdropMerkleNFTMarket__PrepayNotActive();
    error AirdropMerkleNFTMarket__PrepayMismatch();
    error AirdropMerkleNFTMarket__TransferFailed();

    constructor(address nft_, address paymentToken_, bytes32 merkleRoot_, address initialOwner)
        Ownable(initialOwner)
    {
        nft = IERC721(nft_);
        paymentToken = IERC20Permit(paymentToken_);
        merkleRoot = merkleRoot_;
    }

    /// @notice 计算白名单 leaf（链下建树时请保持一致）
    function merkleLeaf(address account) public pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(account))));
    }

    /// @notice 白名单折后价
    function discountedPrice(uint256 listPrice) public pure returns (uint256) {
        return (listPrice * DISCOUNT_BPS) / BPS_DENOMINATOR;
    }

    /// @notice 更新 Merkle 白名单根
    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        bytes32 old = merkleRoot;
        merkleRoot = newRoot;
        emit MerkleRootUpdated(old, newRoot);
    }

    /// @notice 上架 NFT
    function list(uint256 tokenId, uint256 price) external nonReentrant {
        if (price == 0) revert AirdropMerkleNFTMarket__ZeroPrice();
        if (nft.ownerOf(tokenId) != msg.sender) revert AirdropMerkleNFTMarket__NotOwner();

        nft.transferFrom(msg.sender, address(this), tokenId);
        listings[tokenId] = Listing({seller: msg.sender, price: price});

        emit Listed(tokenId, msg.sender, price);
    }

    /// @notice 下架
    function delist(uint256 tokenId) external nonReentrant {
        Listing memory listing = listings[tokenId];
        if (listing.seller == address(0)) revert AirdropMerkleNFTMarket__NotListed();
        if (listing.seller != msg.sender) revert AirdropMerkleNFTMarket__NotOwner();

        delete listings[tokenId];
        nft.transferFrom(address(this), msg.sender, tokenId);

        emit Delisted(tokenId, msg.sender);
    }

    /// @notice EIP-2612 permit：授权市场扣取折后 TOKEN（通常与 claimNFT 一起 multicall）
    /// @param owner 须为 msg.sender
    /// @param tokenId 将要购买的 NFT
    function permitPrePay(address owner, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (owner != msg.sender) revert AirdropMerkleNFTMarket__InvalidPermitOwner();

        Listing memory listing = listings[tokenId];
        if (listing.seller == address(0)) revert AirdropMerkleNFTMarket__NotListed();

        uint256 amount = discountedPrice(listing.price);
        paymentToken.permit(owner, address(this), amount, deadline, v, r, s);

        prepays[msg.sender] = PrepayState({tokenId: tokenId, amount: amount, active: true});
    }

    /// @notice Merkle 验证白名单后，用 permit 授权扣款并交付 NFT（通常接在 permitPrePay 之后 multicall）
    /// @param tokenId NFT id
    /// @param proof Merkle 证明（leaf = merkleLeaf(msg.sender)）
    function claimNFT(uint256 tokenId, bytes32[] calldata proof) external nonReentrant {
        if (!MerkleProof.verify(proof, merkleRoot, merkleLeaf(msg.sender))) {
            revert AirdropMerkleNFTMarket__NotWhitelisted();
        }

        PrepayState memory prepay = prepays[msg.sender];
        if (!prepay.active) revert AirdropMerkleNFTMarket__PrepayNotActive();
        if (prepay.tokenId != tokenId) revert AirdropMerkleNFTMarket__PrepayMismatch();

        Listing memory listing = listings[tokenId];
        if (listing.seller == address(0)) revert AirdropMerkleNFTMarket__NotListed();

        uint256 expectedAmount = discountedPrice(listing.price);
        if (prepay.amount != expectedAmount) revert AirdropMerkleNFTMarket__PrepayMismatch();

        address seller = listing.seller;
        delete listings[tokenId];
        delete prepays[msg.sender];

        if (!IERC20(address(paymentToken)).transferFrom(msg.sender, seller, expectedAmount)) {
            revert AirdropMerkleNFTMarket__TransferFailed();
        }

        nft.transferFrom(address(this), msg.sender, tokenId);

        emit Sold(tokenId, seller, msg.sender, expectedAmount, listing.price);
    }
}
