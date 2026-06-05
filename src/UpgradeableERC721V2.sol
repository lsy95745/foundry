// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {UpgradeableERC721} from "./UpgradeableERC721.sol";

/// @title UpgradeableERC721V2
/// @dev 示例升级版本：仅变更 version，storage 布局与 V1 兼容
contract UpgradeableERC721V2 is UpgradeableERC721 {
    function version() external pure override returns (string memory) {
        return "2.0.0";
    }
}
