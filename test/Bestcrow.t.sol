// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Bestcrow} from "../src/Bestcrow.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

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

    Bestcrow public bestcrow;
    MockERC20 public token;

    address public depositor = makeAddr("depositor");
    address public receiver = makeAddr("receiver");
    uint256 public constant AMOUNT = 1 ether;
    uint256 public constant DAYS_TO_EXPIRY = 30;
    uint256 public constant ADMIN_FEE_BASIS_POINTS = 50; // 0.5% = 50 basis points
    uint256 public constant COLLATERAL_PERCENTAGE = 50; // 50%

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

    function test_requestAndApproveRelease() public {
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

    function test_refundExpiredEscrow() public {
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

    function test_withdrawFees() public {
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

    // Add failure cases
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

    // Add more failure cases for each function...

    // CreateEscrow failure cases
    function testFail_createEscrowWithZeroAmount() public {
        vm.prank(depositor);
        bestcrow.createEscrow{value: 0}(address(0), 0, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver);
    }

    function testFail_createEscrowWithPastExpiry() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        bestcrow.createEscrow{value: totalAmount}(address(0), AMOUNT, block.timestamp - 1, receiver);
    }

    function testFail_createEscrowWithIncorrectEthAmount() public {
        vm.prank(depositor);
        bestcrow.createEscrow{value: AMOUNT}( // Missing admin fee
        address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver);
    }

    function testFail_createEscrowWithSelfAsReceiver() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        bestcrow.createEscrow{value: totalAmount}(
            address(0), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, depositor
        );
    }

    // AcceptEscrow failure cases
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
    function testFail_withdrawFeesUnauthorized() public {
        address unauthorized = makeAddr("unauthorized");
        vm.prank(unauthorized);
        bestcrow.withdrawFees(address(0));
    }

    function testFail_withdrawFeesWithNoBalance() public {
        vm.prank(bestcrow.owner());
        bestcrow.withdrawFees(address(0));
    }

    // ERC20 specific tests
    function test_createAndCompleteEscrowWithERC20() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        uint256 escrowId =
            bestcrow.createEscrow(address(token), AMOUNT, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver);

        uint256 collateralAmount = (AMOUNT * COLLATERAL_PERCENTAGE) / 100;

        vm.prank(receiver);
        bestcrow.acceptEscrow(escrowId);

        vm.prank(receiver);
        bestcrow.requestRelease(escrowId);

        uint256 receiverBalanceBefore = token.balanceOf(receiver);

        vm.prank(depositor);
        bestcrow.approveRelease(escrowId);

        assertEq(token.balanceOf(receiver) - receiverBalanceBefore, AMOUNT + collateralAmount);
    }

    // Additional ERC20 Token Tests
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

    function test_withdrawFeesERC20() public {
        uint256 amount = 1 ether;
        uint256 adminFee = (amount * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = amount + adminFee;

        // Create escrow with amount (not totalAmount)
        vm.prank(depositor);
        bestcrow.createEscrow(
            address(token),
            amount, // Use amount instead of totalAmount
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver
        );

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

    // Edge Cases Around Expiry Dates
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

    // Add at the contract level
    receive() external payable {}
}
