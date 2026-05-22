// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @dev 扩展 ERC20 转账回调接收者接口
interface ITokenReceiver {
    /// @param from 付款方地址
    /// @param amount 转入的 TOKEN 数量
    /// @param data 附加数据（如 abi.encode(tokenId)）
    function tokensReceived(address from, uint256 amount, bytes calldata data) external;
}
