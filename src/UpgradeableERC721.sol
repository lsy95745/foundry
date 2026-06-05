// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721URIStorageUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title UpgradeableERC721
/// @notice 基于 OpenZeppelin Upgradeable 的 UUPS 可升级 ERC721（含 URI 存储）
/// @dev 部署流程：先部署本合约（implementation），再通过 ERC1967Proxy + initialize 使用
contract UpgradeableERC721 is
    Initializable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    uint256 private _nextTokenId;
    string private _baseTokenURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice 代理部署后调用一次，替代 constructor
    /// @param name_ NFT 名称
    /// @param symbol_ NFT 符号
    /// @param initialOwner 管理员（可 mint / 升级）
    function initialize(string memory name_, string memory symbol_, address initialOwner) external initializer {
        __ERC721_init(name_, symbol_);
        __ERC721URIStorage_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    /// @notice 合约版本标识（升级时可修改）
    function version() external pure virtual returns (string memory) {
        return "1.0.0";
    }

    /// @notice 铸造 NFT（仅 owner）
    function mint(address to, string memory uri) external onlyOwner returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /// @notice 设置 tokenURI 前缀
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev UUPS 升级授权：仅 owner 可升级 implementation
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
