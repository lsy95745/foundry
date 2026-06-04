// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {InscriptionToken} from "./InscriptionToken.sol";

/// @title InscriptionFactory
/// @notice 铭文（Inscription）工厂：用 ERC-1167 最小代理批量部署 meme 风格 ERC-20，并统一入口 mint
/// @dev 架构说明：
///      - implementation：InscriptionToken 逻辑合约，只部署一次，所有 clone 通过 delegatecall 复用其代码
///      - clone：每次 deployInscription 生成的轻量代理（~45 bytes），各自拥有独立 storage（symbol/cap/余额等）
///      - 用户不直接调 clone.mint，而是调本工厂的 mintInscription，由工厂代发 mint（InscriptionToken 仅允许 factory 调用）
contract InscriptionFactory {
    using Clones for address;

    /// @dev InscriptionToken 逻辑合约地址；immutable 部署后不可变，clone 的 delegatecall 目标
    address public immutable implementation;

    /// @dev 本工厂创建过的 clone 白名单；防止对外部任意 ERC-20 调用 mintInscription
    mapping(address token => bool registered) public isInscription;

    /// @param token  新部署的 clone 地址
    /// @param symbol 铭文 ticker
    /// @param totalSupply 该铭文最大可 mint 总量（整数，decimals=0）
    /// @param perMint 每次 mintInscription 铸造数量
    /// @param deployer 调用 deployInscription 的地址
    event InscriptionDeployed(
        address indexed token, string symbol, uint256 totalSupply, uint256 perMint, address indexed deployer
    );

    /// @param token  clone 地址
    /// @param minter 收到代币的地址（即 mintInscription 调用者）
    /// @param amount 本次 mint 数量（等于该 token 的 perMint）
    event InscriptionMinted(address indexed token, address indexed minter, uint256 amount);

    error InscriptionFactory__EmptySymbol();
    error InscriptionFactory__InvalidSupply();
    error InscriptionFactory__InvalidPerMint();
    error InscriptionFactory__UnknownToken();

    /// @dev 部署唯一的 InscriptionToken 实现合约；工厂 constructor 内 new 会多出一个需 Etherscan 单独验证的合约
    constructor() {
        implementation = address(new InscriptionToken());
    }

    /// @notice 部署一个新的铭文 token（ERC-1167 minimal proxy + initialize）
    /// @param symbol 代币符号，如 "MEME"
    /// @param totalSupply 最大供应量 cap
    /// @param perMint 每次 mint 数量；需满足 totalSupply >= perMint，且通常 totalSupply % perMint == 0 才能刚好 mint 满
    /// @return tokenAddr 新 clone 的链上地址
    function deployInscription(string calldata symbol, uint256 totalSupply, uint256 perMint)
        external
        returns (address tokenAddr)
    {
        if (bytes(symbol).length == 0) revert InscriptionFactory__EmptySymbol();
        if (totalSupply == 0) revert InscriptionFactory__InvalidSupply();
        if (perMint == 0 || perMint > totalSupply) revert InscriptionFactory__InvalidPerMint();

        // ERC-1167：gas 远低于 new InscriptionToken()，适合批量发 meme
        tokenAddr = implementation.clone();
        // 每个 clone 独立初始化 symbol/cap/perMint；factory 写入自身地址以便后续代 mint
        InscriptionToken(tokenAddr).initialize(address(this), symbol, totalSupply, perMint);
        isInscription[tokenAddr] = true;

        emit InscriptionDeployed(tokenAddr, symbol, totalSupply, perMint, msg.sender);
    }

    /// @notice 从指定铭文 mint 一次（向 msg.sender 铸造 perMint 数量）
    /// @param tokenAddr 须为本工厂 deployInscription 返回的 clone 地址
    function mintInscription(address tokenAddr) external {
        if (!isInscription[tokenAddr]) revert InscriptionFactory__UnknownToken();

        InscriptionToken token = InscriptionToken(tokenAddr);
        // 仅 factory 可调用 token.mint；mint 给调用者而非 deployer
        token.mint(msg.sender);

        emit InscriptionMinted(tokenAddr, msg.sender, token.perMint());
    }
}
