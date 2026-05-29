// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ISignatureTransfer} from "./interfaces/ISignatureTransfer.sol";

/// @title TokenBank
/// @dev Deposit and withdraw ERC-20; supports EIP-2612 permit and Uniswap Permit2
contract TokenBank is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @dev Canonical Permit2 on Ethereum mainnet and most networks
    address public constant PERMIT2_CANONICAL = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    IERC20 public immutable token;
    ISignatureTransfer public immutable permit2;

    mapping(address account => uint256 balance) public balances;

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    error TokenBank__ZeroAmount();
    error TokenBank__InvalidToken();
    error TokenBank__InvalidRecipient();

    /// @param token_ ERC-20 held by this bank
    /// @param permit2_ Permit2 contract; pass `address(0)` to use {PERMIT2_CANONICAL}
    constructor(address token_, address permit2_) {
        token = IERC20(token_);
        permit2 = ISignatureTransfer(permit2_ == address(0) ? PERMIT2_CANONICAL : permit2_);
    }

    /// @notice Deposit tokens (caller must have approved this contract)
    function deposit(uint256 amount) external nonReentrant {
        _deposit(msg.sender, amount);
    }

    /// @notice Deposit using an offline EIP-2612 permit signature
    function permitDeposit(
        address owner,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        IERC20Permit(address(token)).permit(owner, address(this), amount, deadline, v, r, s);
        _deposit(owner, amount);
    }

    /// @notice Deposit via Uniswap Permit2 offline signature (user approves Permit2 on the token first)
    /// @param permit Signed permit (token, max amount, nonce, deadline)
    /// @param transferDetails Recipient must be this bank; `requestedAmount` is the deposit amount
    /// @param owner Token owner who signed the permit
    /// @param signature EIP-712 signature over the permit
    function depositWithPermit2(
        ISignatureTransfer.PermitTransferFrom calldata permit,
        ISignatureTransfer.SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external nonReentrant {
        if (permit.permitted.token != address(token)) revert TokenBank__InvalidToken();
        if (transferDetails.to != address(this)) revert TokenBank__InvalidRecipient();

        uint256 amount = transferDetails.requestedAmount;
        if (amount == 0) revert TokenBank__ZeroAmount();

        permit2.permitTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({
                    token: permit.permitted.token,
                    amount: permit.permitted.amount
                }),
                nonce: permit.nonce,
                deadline: permit.deadline
            }),
            transferDetails,
            owner,
            signature
        );

        balances[owner] += amount;
        emit Deposited(owner, amount);
    }

    /// @notice Withdraw deposited balance
    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert TokenBank__ZeroAmount();
        balances[msg.sender] -= amount;
        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function _deposit(address from, uint256 amount) internal {
        if (amount == 0) revert TokenBank__ZeroAmount();
        token.safeTransferFrom(from, address(this), amount);
        balances[from] += amount;
        emit Deposited(from, amount);
    }
}
