// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MyToken2612} from "../src/MyToken2612.sol";
import {TokenBank} from "../src/TokenBank.sol";
import {ISignatureTransfer} from "../src/interfaces/ISignatureTransfer.sol";
import {MockPermit2} from "./mocks/MockPermit2.sol";

contract TokenBankTest is Test {
    MyToken2612 public token;
    TokenBank public bank;
    MockPermit2 public mockPermit2;

    uint256 constant DEPOSITOR_PK = 0xA11CE;
    address depositor;
    uint256 constant AMOUNT = 100 * 1e18;

    function setUp() public {
        depositor = vm.addr(DEPOSITOR_PK);
        token = new MyToken2612(1_000_000);
        mockPermit2 = new MockPermit2();
        bank = new TokenBank(address(token), address(mockPermit2));
        token.transfer(depositor, 10_000 * 1e18);
    }

    function test_DepositAndWithdraw() public {
        vm.startPrank(depositor);
        token.approve(address(bank), AMOUNT);
        bank.deposit(AMOUNT);
        assertEq(bank.balances(depositor), AMOUNT);
        bank.withdraw(AMOUNT);
        vm.stopPrank();

        assertEq(bank.balances(depositor), 0);
        assertEq(token.balanceOf(depositor), 10_000 * 1e18);
    }

    function test_PermitDeposit() public {
        uint256 deadline = block.timestamp + 1 hours;
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(depositor, address(bank), AMOUNT, deadline, 0);

        bank.permitDeposit(depositor, AMOUNT, deadline, v, r, s);

        assertEq(bank.balances(depositor), AMOUNT);
        assertEq(token.balanceOf(address(bank)), AMOUNT);
        assertEq(token.allowance(depositor, address(bank)), 0);
    }

    function test_DepositWithPermit2() public {
        vm.startPrank(depositor);
        token.approve(address(mockPermit2), type(uint256).max);
        vm.stopPrank();

        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(token), amount: AMOUNT}),
            nonce: 0,
            deadline: block.timestamp + 1 hours
        });
        ISignatureTransfer.SignatureTransferDetails memory details =
            ISignatureTransfer.SignatureTransferDetails({to: address(bank), requestedAmount: AMOUNT});

        bank.depositWithPermit2(permit, details, depositor, "");

        assertEq(bank.balances(depositor), AMOUNT);
        assertEq(token.balanceOf(address(bank)), AMOUNT);
    }

    function test_DepositWithPermit2_RevertWhenWrongRecipient() public {
        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(token), amount: AMOUNT}),
            nonce: 0,
            deadline: block.timestamp + 1 hours
        });
        ISignatureTransfer.SignatureTransferDetails memory details =
            ISignatureTransfer.SignatureTransferDetails({to: makeAddr("other"), requestedAmount: AMOUNT});

        vm.expectRevert(TokenBank.TokenBank__InvalidRecipient.selector);
        bank.depositWithPermit2(permit, details, depositor, "");
    }

    function _signPermit(address owner, address spender, uint256 value, uint256 deadline, uint256 nonce)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (v, r, s) = vm.sign(DEPOSITOR_PK, digest);
    }
}
