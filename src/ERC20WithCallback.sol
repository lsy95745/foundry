// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ITokenReceiver} from "./interfaces/ITokenReceiver.sol";

/// @dev 支持 transferWithData：转账后调用接收合约的 tokensReceived
abstract contract ERC20WithCallback is ERC20 {
    /// @notice 转账并在接收方为合约时触发 tokensReceived 回调
    /// @param to 接收地址（通常为 NFTMarket）
    /// @param value 转账数量
    /// @param data 传给接收者的附加数据
    function transferWithData(address to, uint256 value, bytes calldata data) public returns (bool) {
        address from = _msgSender();
        if (!transfer(to, value)) {
            revert("ERC20WithCallback: transfer failed");
        }
        if (to.code.length > 0) {
            ITokenReceiver(to).tokensReceived(from, value, data);
        }
        return true;
    }
}
