// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title MyToken2612
/// @dev ERC-20 with EIP-2612 permit (offline approval signatures)
contract MyToken2612 is ERC20, ERC20Permit {
    constructor(uint256 initialSupply) ERC20("MyToken2612", "MTK2612") ERC20Permit("MyToken2612") {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }
}
