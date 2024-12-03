// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {Bestcrow} from "../src/Bestcrow.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {console} from "lib/forge-std/src/console.sol";

/// @title Bestcrow Test Suite
/// @author @0xLisanAlGaib
/// @notice Comprehensive test suite for the Bestcrow escrow contract
/// @dev Tests cover ETH and ERC20 functionality, edge cases, and failure scenarios
contract BestcrowTest is Test {
    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed depositor,
        address indexed receiver,
        address token,
        uint256 amount,
        uint256 expiryDate
    );
    event EscrowAccepted(uint256 indexed escrowId, address indexed receiver);
    event ReleaseRequested(uint256 indexed escrowId);
    event EscrowCompleted(uint256 indexed escrowId, address indexed receiver, uint256 amount);
    event EscrowRefunded(uint256 indexed escrowId, address indexed depositor);
    event FeesWithdrawn(address token, uint256 amount);

    /// @dev Core contract instances
    Bestcrow public bestcrow;
    MockERC20 public token;

    /// @dev Test addresses and constants
    address public depositor = makeAddr("depositor");
    address public receiver = makeAddr("receiver");
    uint256 public constant AMOUNT = 1 ether;
    uint256 public constant DAYS_TO_EXPIRY = 30;
    uint256 public constant ADMIN_FEE_BASIS_POINTS = 50; // 0.5% = 50 basis points
    uint256 public constant COLLATERAL_PERCENTAGE = 50; // 50%

    /// @notice Set up the test environment
    /// @dev Deploys contracts, mints tokens, and sets up approvals
    function setUp() public {
        // Deploy contracts
        bestcrow = new Bestcrow();
        token = new MockERC20("Test Token", "TEST");

        // Setup accounts with ETH and tokens
        vm.deal(depositor, 10 ether);
        vm.deal(receiver, 10 ether);
        token.mint(depositor, 10 ether);
        token.mint(receiver, 10 ether);

        // Approve tokens
        vm.prank(depositor);
        token.approve(address(bestcrow), type(uint256).max);
        vm.prank(receiver);
        token.approve(address(bestcrow), type(uint256).max);
    }

    // ETH Specific Tests

    /// @notice Test creating an escrow with ETH
    /// @dev Verifies all escrow parameters are set correctly
    function test_createEscrowWithEth() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        (
            address _depositor,
            address _receiver,
            address _token,
            uint256 _amount,
            uint256 _expiryDate,
            bool _isActive,
            bool _isCompleted,
            bool _isEth,
            bool _releaseRequested
        ) = bestcrow.escrows(escrowId);

        assertEq(_depositor, depositor);
        assertEq(_receiver, receiver);
        assertEq(_token, address(0));
        assertEq(_amount, AMOUNT);
        assertEq(_expiryDate, block.timestamp + DAYS_TO_EXPIRY * 1 days);
        assertFalse(_isActive);
        assertFalse(_isCompleted);
        assertTrue(_isEth);
        assertFalse(_releaseRequested);
    }

    /// @notice Test accepting an ETH escrow
    /// @dev Verifies escrow activation and collateral handling
    function test_acceptEscrowWithEth() public {
        // Create escrow first
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        // Calculate collateral
        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;

        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);

        (,,,,, bool isActive,,,) = bestcrow.escrows(escrowId);
        assertTrue(isActive);
    }

    /// @notice Test the complete flow of requesting and approving release for ETH escrow
    /// @dev Verifies proper transfer of funds and escrow completion
    function test_requestAndApproveReleaseETH() public {
        // Setup escrow and accept it first
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;

        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);

        // Request release
        vm.prank(receiver);
        bestcrow.requestRelease(escrowId);

        // Approve release
        uint256 receiverBalanceBefore = receiver.balance;

        vm.prank(depositor);
        bestcrow.approveRelease(escrowId);

        uint256 expectedTotal = AMOUNT + collateralAmount;
        assertEq(receiver.balance - receiverBalanceBefore, expectedTotal);
    }

    /// @notice Test refunding an expired ETH escrow
    /// @dev Verifies proper refund mechanics after expiry
    function test_refundExpiredEscrowETH() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        // Fast forward past expiry
        vm.warp(block.timestamp + DAYS_TO_EXPIRY * 1 days + 1);

        uint256 depositorBalanceBefore = depositor.balance;

        vm.prank(depositor);
        bestcrow.refundExpiredEscrow(escrowId);

        assertEq(depositor.balance - depositorBalanceBefore, totalAmount);
    }

    /// @notice Test withdrawal of accumulated ETH fees
    /// @dev Verifies proper fee calculation and transfer to owner
    function test_withdrawFeesETH() public {
        // Setup and complete an escrow to generate fees
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;

        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);

        vm.prank(receiver);
        bestcrow.requestRelease(escrowId);

        vm.prank(depositor);
        bestcrow.approveRelease(escrowId);

        // Withdraw fees
        uint256 ownerBalanceBefore = bestcrow.owner().balance;

        vm.prank(bestcrow.owner());
        bestcrow.withdrawFees(address(0));

        assertEq(bestcrow.owner().balance - ownerBalanceBefore, adminFee);
    }

    // ERC20 specific tests

    /// @notice Test complete flow of ERC20 escrow from creation to completion
    /// @dev Verifies token transfers and balance updates
    function test_createAndCompleteEscrowWithERC20() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        // Print values for debugging
        console.log("Escrow amount:", AMOUNT);
        console.log("Admin fee:", adminFee);
        console.log("Total amount:", totalAmount);
        console.log("Collateral:", (AMOUNT * COLLATERAL_PERCENTAGE) / 100);

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow(
            address(token),
            AMOUNT, // Escrow amount (1 ETH)
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver
        );

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;

        vm.prank(receiver);
        bestcrow.acceptEscrow(escrowId);

        vm.prank(receiver);
        bestcrow.requestRelease(escrowId);

        uint256 receiverBalanceBefore = token.balanceOf(receiver);

        vm.prank(depositor);
        bestcrow.approveRelease(escrowId);

        uint256 receiverBalanceAfter = token.balanceOf(receiver);
        console.log("Amount received:", receiverBalanceAfter - receiverBalanceBefore);

        assertEq(
            receiverBalanceAfter - receiverBalanceBefore,
            AMOUNT + collateralAmount // Should be 1.5 ETH (1 ETH + 0.5 ETH)
        );
    }

    /// @notice Test refunding expired ERC20 escrow
    /// @dev Verifies proper token refund mechanics after escrow expiration
    function test_refundExpiredEscrowERC20() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId =
            bestcrow.createEscrow(address(token), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver);

        vm.warp(block.timestamp + DAYS_TO_EXPIRY * 1 days + 1);

        uint256 depositorBalanceBefore = token.balanceOf(depositor);

        vm.prank(depositor);
        bestcrow.refundExpiredEscrow(escrowId);

        assertEq(token.balanceOf(depositor) - depositorBalanceBefore, totalAmount);
    }

    /// @notice Test withdrawal of accumulated ERC20 fees
    /// @dev Verifies proper fee calculation and token transfer to owner
    function test_withdrawFeesERC20() public {
        uint256 amount = 1 ether;
        uint256 adminFee = (amount * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = amount + adminFee;

        vm.prank(depositor);
        bestcrow.createEscrow(address(token), totalAmount, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver);

        // Accept escrow
        vm.prank(receiver);
        bestcrow.acceptEscrow(0);

        // Complete escrow flow
        vm.prank(receiver);
        bestcrow.requestRelease(0);
        vm.prank(depositor);
        bestcrow.approveRelease(0);

        // Withdraw fees
        vm.prank(bestcrow.owner());
        bestcrow.withdrawFees(address(token));

        assertEq(token.balanceOf(bestcrow.owner()), adminFee); // Use the calculated adminFee
    }

    // CreateEscrow failure cases

    /// @notice Test failure when creating escrow with invalid receiver address
    /// @dev Should revert when receiver address is zero
    function testFail_createEscrowWithInvalidReceiver() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        bestcrow.createEscrow{value: totalAmount}(
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            address(0) // Invalid receiver
        );
    }

    /// @notice Test failure when creating escrow with zero amount
    /// @dev Should revert when escrow amount is zero
    function testFail_createEscrowWithZeroAmount() public {
        vm.prank(depositor);
        bestcrow.createEscrow{value: 0}(address(0), 0, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver);
    }

    /// @notice Test failure when creating escrow with past expiry date
    /// @dev Should revert when expiry date is in the past
    function testFail_createEscrowWithPastExpiry() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        bestcrow.createEscrow{value: totalAmount}(address(0), AMOUNT, block.timestamp - 1, receiver);
    }

    /// @notice Test failure when creating ETH escrow with incorrect amount
    /// @dev Should revert when sent ETH doesn't match amount plus admin fee
    function testFail_createEscrowWithIncorrectEthAmount() public {
        vm.prank(depositor);
        bestcrow.createEscrow{value: AMOUNT}( // Missing admin fee
        address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver);
    }

    /// @notice Test failure when creating escrow with self as receiver
    /// @dev Should revert when depositor tries to set themselves as receiver
    function testFail_createEscrowWithSelfAsReceiver() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, depositor
        );
    }

    // AcceptEscrow failure cases

    /// @notice Test failure when accepting an escrow twice
    /// @dev Should revert on second acceptance attempt
    function testFail_acceptEscrowTwice() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;

        vm.startPrank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId); // Should fail
        vm.stopPrank();
    }

    /// @notice Test failure when accepting an expired escrow
    /// @dev Should revert when trying to accept after expiry date
    function testFail_acceptExpiredEscrow() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        vm.warp(block.timestamp + DAYS_TO_EXPIRY * 1 days + 1);

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);
    }

    /// @notice Test failure when unauthorized address tries to accept escrow
    /// @dev Should revert when non-receiver tries to accept
    function testFail_acceptEscrowUnauthorized() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;
        address unauthorized = makeAddr("unauthorized");
        vm.deal(unauthorized, collateralAmount);

        vm.prank(unauthorized);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);
    }

    /// @notice Test failure when accepting with insufficient collateral
    /// @dev Should revert when collateral amount is less than required
    function testFail_acceptEscrowInsufficientCollateral() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount - 0.1 ether}(escrowId);
    }

    // RequestRelease failure cases

    /// @notice Test failure when requesting release before acceptance
    /// @dev Should revert when trying to request release on unaccepted escrow
    function testFail_requestReleaseBeforeAcceptance() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        vm.prank(receiver);
        bestcrow.requestRelease(escrowId);
    }

    /// @notice Test failure when unauthorized address requests release
    /// @dev Should revert when non-receiver requests release
    function testFail_requestReleaseUnauthorized() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        vm.prank(depositor); // Wrong person requesting
        bestcrow.requestRelease(escrowId);
    }

    /// @notice Test failure when requesting release twice
    /// @dev Should revert on second release request
    function testFail_requestReleaseTwice() public {
        // Setup escrow and accept it first
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);

        vm.startPrank(receiver);
        bestcrow.requestRelease(escrowId);
        bestcrow.requestRelease(escrowId); // Should fail
        vm.stopPrank();
    }

    // ApproveRelease failure cases

    /// @notice Test failure when approving release without request
    /// @dev Should revert when trying to approve unrequested release
    function testFail_approveReleaseWithoutRequest() public {
        // Setup escrow and accept it first
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);

        vm.prank(depositor);
        bestcrow.approveRelease(escrowId); // Should fail without request
    }

    /// @notice Test failure when unauthorized address approves release
    /// @dev Should revert when non-depositor tries to approve release
    function testFail_approveReleaseUnauthorized() public {
        // Setup escrow and accept it first
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);

        vm.prank(receiver);
        bestcrow.requestRelease(escrowId);

        vm.prank(receiver); // Wrong person approving
        bestcrow.approveRelease(escrowId);
    }

    // WithdrawFees failure cases

    /// @notice Test failure when unauthorized address tries to withdraw fees
    /// @dev Should revert when non-owner attempts fee withdrawal
    function testFail_withdrawFeesUnauthorized() public {
        address unauthorized = makeAddr("unauthorized");
        vm.prank(unauthorized);
        bestcrow.withdrawFees(address(0));
    }

    /// @notice Test failure when withdrawing fees with zero balance
    /// @dev Should revert when trying to withdraw non-existent fees
    function testFail_withdrawFeesWithNoBalance() public {
        vm.prank(bestcrow.owner());
        bestcrow.withdrawFees(address(0));
    }

    // Edge Cases Around Expiry Dates

    /// @notice Test accepting escrow just before expiry
    /// @dev Verifies escrow can be accepted up until exact expiry time
    function test_acceptEscrowJustBeforeExpiry() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        // Warp to just before expiry
        vm.warp(block.timestamp + DAYS_TO_EXPIRY * 1 days - 1);

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);

        (,,,,, bool isActive,,,) = bestcrow.escrows(escrowId);
        assertTrue(isActive);
    }

    /// @notice Test failure when accepting escrow exactly at expiry
    /// @dev Should revert when accepting at exact expiry timestamp
    function testFail_acceptEscrowExactlyAtExpiry() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        // Warp to exact expiry
        vm.warp(block.timestamp + DAYS_TO_EXPIRY * 1 days);

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);
    }

    // Fee Calculation Edge Cases

    /// @notice Test creating escrow with minimum possible amount
    /// @dev Verifies correct fee calculation for small amounts
    function test_createEscrowWithMinimumAmount() public {
        uint256 minAmount = 1000; // Small amount to test minimum fees
        uint256 adminFee = (minAmount * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = minAmount + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), minAmount, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        (,,, uint256 amount,,,,,) = bestcrow.escrows(escrowId);
        assertEq(amount, minAmount);
    }

    /// @notice Test creating escrow with large amount
    /// @dev Verifies correct fee calculation for large amounts
    function test_createEscrowWithLargeAmount() public {
        uint256 largeAmount = 1000000 ether;
        uint256 adminFee = (largeAmount * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = largeAmount + adminFee;

        vm.deal(depositor, totalAmount);

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), largeAmount, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        (,,, uint256 amount,,,,,) = bestcrow.escrows(escrowId);
        assertEq(amount, largeAmount);
    }

    // Gas Optimization Tests

    /// @notice Test gas usage for escrow creation
    /// @dev Verifies gas usage is within acceptable limits
    function test_gasCreateEscrow() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 gasBefore = gasleft();
        bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );
        uint256 gasUsed = gasBefore - gasleft();
        assertTrue(gasUsed < 200000); // Increased threshold to a more realistic value
    }

    /// @notice Test gas usage for escrow acceptance
    /// @dev Verifies gas usage is within acceptable limits
    function test_gasAcceptEscrow() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;

        vm.prank(receiver);
        uint256 gasBefore = gasleft();
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);
        uint256 gasUsed = gasBefore - gasleft();
        assertTrue(gasUsed < 100000); // Adjust threshold as needed
    }

    /// @notice Test gas usage for complete escrow flow
    /// @dev Verifies total gas usage for full escrow lifecycle
    function test_gasCompleteEscrowFlow() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;

        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);

        uint256 gasBefore = gasleft();

        vm.prank(receiver);
        bestcrow.requestRelease(escrowId);

        vm.prank(depositor);
        bestcrow.approveRelease(escrowId);

        uint256 gasUsed = gasBefore - gasleft();
        assertTrue(gasUsed < 200000); // Adjust threshold as needed
    }

    /// @notice Fallback function to receive ETH
    /// @dev Required for contract to receive ETH in tests
    receive() external payable {}

    // Edge Cases for Escrow Status

    /// @notice Test that completed escrow cannot be released again
    /// @dev Verifies proper completion state handling
    function test_cannotReleaseCompletedEscrow() public {
        // Setup and complete an escrow
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);

        vm.prank(receiver);
        bestcrow.requestRelease(escrowId);

        vm.prank(depositor);
        bestcrow.approveRelease(escrowId);

        // Try to request release again
        vm.expectRevert("Escrow not active");
        vm.prank(receiver);
        bestcrow.requestRelease(escrowId);
    }

    /// @notice Test multiple escrows between same parties
    /// @dev Verifies independent handling of multiple escrows
    function test_multipleEscrowsBetweenSameParties() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        // Create first escrow
        vm.prank(depositor);
        uint256 escrowId1 = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        // Create second escrow
        vm.prank(depositor);
        uint256 escrowId2 = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        assertEq(escrowId2, escrowId1 + 1);

        // Verify both escrows are independent
        (address depositor1,,,,,,,,) = bestcrow.escrows(escrowId1);
        (address depositor2,,,,,,,,) = bestcrow.escrows(escrowId2);

        assertEq(depositor1, depositor);
        assertEq(depositor2, depositor);
    }

    /// @notice Test escrowDetails for ETH escrow
    /// @dev Verifies all fields are correctly returned for ETH escrow
    function test_escrowDetailsForEth() public {
        // Create ETH escrow
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        // Get escrow details
        (
            address _depositor,
            address _receiver,
            address _token,
            uint256 _amount,
            uint256 _expiryDate,
            bool _isActive,
            bool _isCompleted,
            bool _isEth,
            bool _releaseRequested
        ) = bestcrow.escrowDetails(escrowId);

        // Verify all fields
        assertEq(_depositor, depositor);
        assertEq(_receiver, receiver);
        assertEq(_token, address(0));
        assertEq(_amount, AMOUNT);
        assertEq(_expiryDate, block.timestamp + DAYS_TO_EXPIRY * 1 days);
        assertFalse(_isActive);
        assertFalse(_isCompleted);
        assertTrue(_isEth);
        assertFalse(_releaseRequested);
    }

    /// @notice Test escrowDetails for ERC20 escrow
    /// @dev Verifies all fields are correctly returned for ERC20 escrow
    function test_escrowDetailsForERC20() public {
        // Create ERC20 escrow
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        // First approve the total amount (escrow + fee)
        vm.prank(depositor);
        token.approve(address(bestcrow), totalAmount);

        // Create escrow with AMOUNT as the escrow amount, but the contract will transfer totalAmount
        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow(
            address(token),
            AMOUNT, // The escrow amount (without fee)
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver
        );

        // Get escrow details
        (
            address _depositor,
            address _receiver,
            address _token,
            uint256 _amount,
            uint256 _expiryDate,
            bool _isActive,
            bool _isCompleted,
            bool _isEth,
            bool _releaseRequested
        ) = bestcrow.escrowDetails(escrowId);

        // Verify all fields
        assertEq(_depositor, depositor);
        assertEq(_receiver, receiver);
        assertEq(_token, address(token));
        assertEq(_amount, AMOUNT); // This should now pass as we're storing the base amount
        assertEq(_expiryDate, block.timestamp + DAYS_TO_EXPIRY * 1 days);
        assertFalse(_isActive);
        assertFalse(_isCompleted);
        assertFalse(_isEth);
        assertFalse(_releaseRequested);

        console.log("Escrow details for ERC20:");
        console.log("Depositor:", _depositor);
        console.log("Receiver:", _receiver);
        console.log("Token:", _token);
        console.log("Amount:", _amount);
        console.log("Expiry date:", _expiryDate);
        console.log("Is active:", _isActive);
        console.log("Is completed:", _isCompleted);
        console.log("Is ETH:", _isEth);
        console.log("Release requested:", _releaseRequested);
    }

    /// @notice Test escrowDetails for non-existent escrow
    /// @dev Verifies default values are returned for non-existent escrow ID
    function test_escrowDetailsForNonExistentEscrow() public view {
        uint256 nonExistentEscrowId = 999;

        (
            address _depositor,
            address _receiver,
            address _token,
            uint256 _amount,
            uint256 _expiryDate,
            bool _isActive,
            bool _isCompleted,
            bool _isEth,
            bool _releaseRequested
        ) = bestcrow.escrowDetails(nonExistentEscrowId);

        // Verify all fields are default values
        assertEq(_depositor, address(0));
        assertEq(_receiver, address(0));
        assertEq(_token, address(0));
        assertEq(_amount, 0);
        assertEq(_expiryDate, 0);
        assertFalse(_isActive);
        assertFalse(_isCompleted);
        assertFalse(_isEth);
        assertFalse(_releaseRequested);
    }

    /// @notice Test escrowDetails after state changes
    /// @dev Verifies details are updated correctly after escrow state changes
    function test_escrowDetailsAfterStateChanges() public {
        // Create and setup ETH escrow
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );

        logEscrowState("After creation", escrowId);

        // Accept escrow
        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);

        logEscrowState("After acceptance", escrowId);

        // Request release
        vm.prank(receiver);
        bestcrow.requestRelease(escrowId);

        logEscrowState("After release request", escrowId);

        // Complete escrow
        vm.prank(depositor);
        bestcrow.approveRelease(escrowId);

        logEscrowState("After completion", escrowId);

        // Get final state
        (,,,,, bool _isActiveFinal, bool _isCompletedFinal,,) = bestcrow.escrowDetails(escrowId);

        // Verify final states
        assertFalse(_isActiveFinal);
        assertTrue(_isCompletedFinal);
    }

    // Helper function to log escrow state
    function logEscrowState(string memory stage, uint256 escrowId) internal view {
        (
            address _depositor,
            address _receiver,
            address _token,
            uint256 _amount,
            uint256 _expiryDate,
            bool _isActive,
            bool _isCompleted,
            bool _isEth,
            bool _releaseRequested
        ) = bestcrow.escrowDetails(escrowId);

        console.log("\n=== Escrow State: %s ===", stage);
        console.log("Depositor:", _depositor);
        console.log("Receiver:", _receiver);
        console.log("Token:", _token);
        console.log("Amount:", _amount);
        console.log("Expiry Date:", _expiryDate);
        console.log("Is Active:", _isActive);
        console.log("Is Completed:", _isCompleted);
        console.log("Is ETH:", _isEth);
        console.log("Release Requested:", _releaseRequested);
        console.log("============================\n");
    }
}
