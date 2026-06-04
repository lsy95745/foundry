// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title InscriptionToken
/// @dev ERC-20 logic contract deployed once; instances are cheap ERC-1167 minimal proxies.
contract InscriptionToken is ERC20 {
    address public factory;
    uint256 public cap;
    uint256 public perMint;

    string private _tokenName;
    string private _tokenSymbol;

    bool private _initialized;

    error InscriptionToken__AlreadyInitialized();
    error InscriptionToken__NotFactory();
    error InscriptionToken__InvalidCap();
    error InscriptionToken__InvalidPerMint();
    error InscriptionToken__SupplyExceeded();

    /// @dev Locks the implementation so only clones can be initialized.
    constructor() ERC20("Inscription", "INS") {
        _initialized = true;
    }

    /// @notice One-time setup for a clone instance
    /// @param factory_ Deployer factory allowed to mint
    /// @param symbol_ Token ticker
    /// @param totalSupply_ Maximum mintable supply
    /// @param perMint_ Amount minted per inscription call
    function initialize(address factory_, string memory symbol_, uint256 totalSupply_, uint256 perMint_)
        external
    {
        if (_initialized) revert InscriptionToken__AlreadyInitialized();
        if (totalSupply_ == 0) revert InscriptionToken__InvalidCap();
        if (perMint_ == 0 || perMint_ > totalSupply_) revert InscriptionToken__InvalidPerMint();

        _initialized = true;
        factory = factory_;
        cap = totalSupply_;
        perMint = perMint_;
        _tokenName = string.concat("Inscription ", symbol_);
        _tokenSymbol = symbol_;
    }

    /// @notice Mint one inscription unit to `to`
    function mint(address to) external {
        if (msg.sender != factory) revert InscriptionToken__NotFactory();
        if (totalSupply() + perMint > cap) revert InscriptionToken__SupplyExceeded();
        _mint(to, perMint);
    }

    function name() public view override returns (string memory) {
        return bytes(_tokenSymbol).length == 0 ? super.name() : _tokenName;
    }

    function symbol() public view override returns (string memory) {
        return bytes(_tokenSymbol).length == 0 ? super.symbol() : _tokenSymbol;
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}
