// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Uniswap Permit2 signature transfer (subset used by TokenBank)
/// @dev User must approve the Permit2 contract for the token before signing
interface ISignatureTransfer {
    struct TokenPermissions {
        address token;
        uint256 amount;
    }

    struct PermitTransferFrom {
        TokenPermissions permitted;
        uint256 nonce;
        uint256 deadline;
    }

    struct SignatureTransferDetails {
        address to;
        uint256 requestedAmount;
    }

    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;
}
