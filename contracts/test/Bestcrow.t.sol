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
    event EscrowRejected(uint256 indexed escrowId, address indexed receiver);

    /// @dev Allow the contract to receive ETH
    receive() external payable {}

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
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Test ETH Escrow",
            "This is a test escrow with ETH"
        );

        (
            address depositor_,
            address receiver_,
            address token_,
            uint256 amount_,
            uint256 expiryDate_,
            uint256 createdAt_,
            bool isActive_,
            bool isCompleted_,
            bool isEth_,
            bool releaseRequested_,
            string memory title_,
            string memory description_
        ) = bestcrow.escrowDetails(escrowId);

        assertEq(depositor_, depositor);
        assertEq(receiver_, receiver);
        assertEq(token_, address(0));
        assertEq(amount_, AMOUNT);
        assertEq(expiryDate_, block.timestamp + DAYS_TO_EXPIRY * 1 days);
        assertEq(createdAt_, block.timestamp);
        assertFalse(isActive_);
        assertFalse(isCompleted_);
        assertTrue(isEth_);
        assertFalse(releaseRequested_);
        assertEq(title_, "Test ETH Escrow");
        assertEq(description_, "This is a test escrow with ETH");
    }

    /// @notice Test creating an escrow with empty title
    /// @dev Should revert when title is empty
    function test_RevertWhen_CreatingEscrowWithEmptyTitle() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        vm.expectRevert("Title cannot be empty");
        bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver, "", "This is a test escrow"
        );
    }

    /// @notice Test creating an escrow with empty description
    /// @dev Should succeed when description is empty
    function test_createEscrowWithEmptyDescription() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver, "Test ETH Escrow", ""
        );

        string memory description_;
        (,,,,,,,,,,, description_) = bestcrow.escrowDetails(escrowId);
        assertEq(description_, "");
    }

    /// @notice Test creating an escrow with long title and description
    /// @dev Should succeed with long strings
    function test_createEscrowWithLongTitleAndDescription() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        string memory longTitle =
            "This is a very long title for testing purposes that should still work fine with the escrow contract";
        string memory longDescription =
            "This is an extremely long description that contains multiple sentences. It should test the contract's ability to handle longer strings. This could be a detailed explanation of the escrow terms and conditions. The contract should handle this without any issues.";

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver, longTitle, longDescription
        );

        string memory title_;
        string memory description_;
        (,,,,,,,,,, title_, description_) = bestcrow.escrowDetails(escrowId);
        assertEq(title_, longTitle);
        assertEq(description_, longDescription);
    }

    /// @notice Test accepting an ETH escrow
    /// @dev Verifies escrow activation and collateral handling
    function test_acceptEscrowWithEth() public {
        // Create escrow first
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Test ETH Escrow",
            "Test escrow for ETH acceptance"
        );

        // Calculate collateral
        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;

        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);

        bool isActive_;
        (,,,,,, isActive_,,,,,) = bestcrow.escrowDetails(escrowId);
        assertTrue(isActive_);
    }

    /// @notice Test the complete flow of requesting and approving release for ETH escrow
    /// @dev Verifies proper transfer of funds and escrow completion
    function test_requestAndApproveReleaseETH() public {
        // Setup escrow and accept it first
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Test ETH Escrow",
            "Test escrow for ETH release"
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
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Test ETH Escrow",
            "Test escrow for ETH refund"
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

        // Store initial contract balance
        uint256 initialContractBalance = address(bestcrow).balance;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Test ETH Escrow",
            "Test escrow for ETH fees"
        );

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;

        // Accept escrow
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);

        // Request release
        vm.prank(receiver);
        bestcrow.requestRelease(escrowId);

        // Approve release to complete the escrow
        vm.prank(depositor);
        bestcrow.approveRelease(escrowId);

        // Verify the escrow is completed and fees are available
        bool isCompleted_;
        (,,,,,,, isCompleted_,,,,) = bestcrow.escrowDetails(escrowId);
        assertTrue(isCompleted_, "Escrow should be completed before withdrawing fees");

        // Verify the contract balance increased by the admin fee
        assertEq(
            address(bestcrow).balance - initialContractBalance,
            adminFee,
            "Contract balance should increase by admin fee"
        );

        // Verify that fees were accrued
        assertEq(bestcrow.accruedFeesETH(), adminFee, "Fees should be accrued before withdrawal");

        // Store owner's balance before withdrawal
        uint256 ownerBalanceBefore = bestcrow.owner().balance;

        // Withdraw fees
        vm.prank(bestcrow.owner());
        bestcrow.withdrawFees(address(0));

        // Verify the fees were withdrawn correctly
        assertEq(bestcrow.owner().balance - ownerBalanceBefore, adminFee, "Owner should receive the correct admin fee");

        // Verify the contract balance decreased by the admin fee
        assertEq(address(bestcrow).balance, initialContractBalance, "Contract balance should return to initial amount");

        // Verify that fees were reset to zero
        assertEq(bestcrow.accruedFeesETH(), 0, "Fees should be zero after withdrawal");
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
            receiver,
            "Test ERC20 Escrow",
            "Test escrow for ERC20 completion"
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
        uint256 escrowId = bestcrow.createEscrow(
            address(token),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Test ERC20 Refund",
            "Testing ERC20 refund functionality"
        );

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

        // First approve the total amount (escrow + fee)
        vm.prank(depositor);
        token.approve(address(bestcrow), totalAmount);

        // Create escrow with AMOUNT as the escrow amount
        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow(
            address(token),
            amount,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "ERC20 Fee Withdrawal Test",
            "Testing ERC20 fee withdrawal functionality"
        );

        // Accept escrow
        vm.prank(receiver);
        bestcrow.acceptEscrow(escrowId);

        // Complete escrow flow
        vm.prank(receiver);
        bestcrow.requestRelease(escrowId);

        vm.prank(depositor);
        bestcrow.approveRelease(escrowId);

        // Withdraw fees
        vm.prank(bestcrow.owner());
        bestcrow.withdrawFees(address(token));

        assertEq(token.balanceOf(bestcrow.owner()), adminFee);
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
            address(0), // Invalid receiver
            "Invalid Receiver Test",
            "Testing invalid receiver address"
        );
    }

    /// @notice Test failure when creating escrow with zero amount
    /// @dev Should revert when escrow amount is zero
    function testFail_createEscrowWithZeroAmount() public {
        vm.prank(depositor);
        bestcrow.createEscrow{value: 0}(
            address(0),
            0,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Zero Amount Test",
            "Testing zero amount validation"
        );
    }

    /// @notice Test failure when creating escrow with past expiry date
    /// @dev Should revert when expiry date is in the past
    function testFail_createEscrowWithPastExpiry() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp - 1, receiver, "Past Expiry Test", "Testing past expiry date validation"
        );
    }

    /// @notice Test failure when creating ETH escrow with incorrect amount
    /// @dev Should revert when sent ETH doesn't match amount plus admin fee
    function testFail_createEscrowWithIncorrectEthAmount() public {
        vm.prank(depositor);
        bestcrow.createEscrow{value: AMOUNT}( // Missing admin fee
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Incorrect Amount Test",
            "Testing incorrect ETH amount validation"
        );
    }

    /// @notice Test failure when creating escrow with self as receiver
    /// @dev Should revert when depositor tries to set themselves as receiver
    function testFail_createEscrowWithSelfAsReceiver() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        bestcrow.createEscrow{value: totalAmount}(
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            depositor,
            "Self Receiver Test",
            "Testing self as receiver validation"
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
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Double Accept Test",
            "Testing double acceptance validation"
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
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Expired Accept Test",
            "Testing expired escrow acceptance"
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
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Unauthorized Accept Test",
            "Testing unauthorized acceptance"
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
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Insufficient Collateral Test",
            "Testing insufficient collateral validation"
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
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Early Release Test",
            "Testing early release request validation"
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
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Unauthorized Release Test",
            "Testing unauthorized release request"
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
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Double Release Test",
            "Testing double release request validation"
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
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Early Approve Test",
            "Testing early approval validation"
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
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Unauthorized Approve Test",
            "Testing unauthorized approval"
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
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Just Before Expiry Test",
            "Testing acceptance just before expiry"
        );

        // Warp to just before expiry
        vm.warp(block.timestamp + DAYS_TO_EXPIRY * 1 days - 1);

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);

        bool isActive_;
        (,,,,,, isActive_,,,,,) = bestcrow.escrowDetails(escrowId);
        assertTrue(isActive_);
    }

    /// @notice Test failure when accepting escrow exactly at expiry
    /// @dev Should revert when accepting at exact expiry timestamp
    function testFail_acceptEscrowExactlyAtExpiry() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "At Expiry Test",
            "Testing acceptance at expiry"
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
            address(0),
            minAmount,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Minimum Amount Test",
            "Testing minimum amount escrow"
        );

        uint256 amount_;
        (,,, amount_,,,,,,,,) = bestcrow.escrowDetails(escrowId);
        assertEq(amount_, minAmount);
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
            address(0),
            largeAmount,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Large Amount Test",
            "Testing large amount escrow"
        );

        uint256 amount_;
        (,,, amount_,,,,,,,,) = bestcrow.escrowDetails(escrowId);
        assertEq(amount_, largeAmount);
    }

    // Multiple Escrows Test

    /// @notice Test multiple escrows between same parties
    /// @dev Verifies independent handling of multiple escrows
    function test_multipleEscrowsBetweenSameParties() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        // Create first escrow
        vm.prank(depositor);
        uint256 escrowId1 = bestcrow.createEscrow{value: totalAmount}(
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Multiple Escrow Test 1",
            "Testing multiple escrows - first"
        );

        // Create second escrow
        vm.prank(depositor);
        uint256 escrowId2 = bestcrow.createEscrow{value: totalAmount}(
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Multiple Escrow Test 2",
            "Testing multiple escrows - second"
        );

        assertEq(escrowId2, escrowId1 + 1);

        // Verify both escrows are independent
        address depositor1_;
        address depositor2_;
        (depositor1_,,,,,,,,,,,) = bestcrow.escrowDetails(escrowId1);
        (depositor2_,,,,,,,,,,,) = bestcrow.escrowDetails(escrowId2);

        assertEq(depositor1_, depositor);
        assertEq(depositor2_, depositor);
    }

    // Helper function to log escrow state
    function logEscrowState(string memory stage, uint256 escrowId) internal view {
        address depositor_;
        address receiver_;
        address token_;
        uint256 amount_;
        uint256 expiryDate_;
        uint256 createdAt_;
        bool isActive_;
        bool isCompleted_;
        bool isEth_;
        bool releaseRequested_;
        string memory title_;
        string memory description_;

        (
            depositor_,
            receiver_,
            token_,
            amount_,
            expiryDate_,
            createdAt_,
            isActive_,
            isCompleted_,
            isEth_,
            releaseRequested_,
            title_,
            description_
        ) = bestcrow.escrowDetails(escrowId);

        console.log("\n=== Escrow State: %s ===", stage);
        console.log("Depositor:", depositor_);
        console.log("Receiver:", receiver_);
        console.log("Token:", token_);
        console.log("Amount:", amount_);
        console.log("Expiry Date:", expiryDate_);
        console.log("Created At:", createdAt_);
        console.log("Is Active:", isActive_);
        console.log("Is Completed:", isCompleted_);
        console.log("Is ETH:", isEth_);
        console.log("Release Requested:", releaseRequested_);
        console.log("Title:", title_);
        console.log("Description:", description_);
        console.log("============================\n");
    }

    /// @notice Test successful rejection of an ETH escrow
    /// @dev Verifies funds are returned and state is updated correctly
    function test_rejectEscrowWithEth() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        // Create escrow
        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Test ETH Escrow",
            "Testing escrow rejection"
        );

        // Record depositor's balance before rejection
        uint256 depositorBalanceBefore = depositor.balance;

        // Reject escrow
        vm.prank(receiver);
        vm.expectEmit(true, true, false, false);
        emit EscrowRejected(escrowId, receiver);
        bestcrow.rejectEscrow(escrowId);

        // Verify escrow state
        (,,,,,, bool isActive, bool isCompleted,, bool releaseRequested,,) = bestcrow.escrowDetails(escrowId);

        assertFalse(isActive, "Escrow should not be active");
        assertTrue(isCompleted, "Escrow should be completed");
        assertFalse(releaseRequested, "Release should not be requested");

        // Verify funds returned
        assertEq(depositor.balance - depositorBalanceBefore, totalAmount, "Full amount should be returned to depositor");
    }

    /// @notice Test successful rejection of an ERC20 escrow
    /// @dev Verifies tokens are returned and state is updated correctly
    function test_rejectEscrowWithERC20() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        // Create escrow
        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow(
            address(token),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Test ERC20 Escrow",
            "Testing ERC20 escrow rejection"
        );

        // Record depositor's token balance before rejection
        uint256 depositorBalanceBefore = token.balanceOf(depositor);

        // Reject escrow
        vm.prank(receiver);
        vm.expectEmit(true, true, false, false);
        emit EscrowRejected(escrowId, receiver);
        bestcrow.rejectEscrow(escrowId);

        // Verify escrow state
        (,,,,,, bool isActive, bool isCompleted,, bool releaseRequested,,) = bestcrow.escrowDetails(escrowId);

        assertFalse(isActive, "Escrow should not be active");
        assertTrue(isCompleted, "Escrow should be completed");
        assertFalse(releaseRequested, "Release should not be requested");

        // Verify tokens returned
        assertEq(
            token.balanceOf(depositor) - depositorBalanceBefore,
            totalAmount,
            "Full amount should be returned to depositor"
        );
    }

    /// @notice Test failure when non-receiver tries to reject escrow
    /// @dev Should revert when unauthorized address attempts rejection
    function testFail_rejectEscrowUnauthorized() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        // Create escrow
        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Unauthorized Reject Test",
            "Testing unauthorized rejection"
        );

        // Attempt to reject from unauthorized address
        vm.prank(depositor); // Wrong address trying to reject
        bestcrow.rejectEscrow(escrowId);
    }

    /// @notice Test failure when rejecting an expired escrow
    /// @dev Should revert when trying to reject after expiry
    function testFail_rejectExpiredEscrow() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        // Create escrow
        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Expired Reject Test",
            "Testing expired escrow rejection"
        );

        // Fast forward past expiry
        vm.warp(block.timestamp + DAYS_TO_EXPIRY * 1 days + 1);

        // Attempt to reject expired escrow
        vm.prank(receiver);
        bestcrow.rejectEscrow(escrowId);
    }

    /// @notice Test failure when rejecting an already active escrow
    /// @dev Should revert when trying to reject after acceptance
    function testFail_rejectActiveEscrow() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        // Create escrow
        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Active Reject Test",
            "Testing active escrow rejection"
        );

        // Accept escrow
        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);

        // Attempt to reject active escrow
        vm.prank(receiver);
        bestcrow.rejectEscrow(escrowId);
    }

    /// @notice Test failure when rejecting an already completed escrow
    /// @dev Should revert when trying to reject completed escrow
    function testFail_rejectCompletedEscrow() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        // Create escrow
        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0),
            AMOUNT,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Completed Reject Test",
            "Testing completed escrow rejection"
        );

        // Reject escrow once
        vm.prank(receiver);
        bestcrow.rejectEscrow(escrowId);

        // Attempt to reject again
        vm.prank(receiver);
        bestcrow.rejectEscrow(escrowId);
    }
}
