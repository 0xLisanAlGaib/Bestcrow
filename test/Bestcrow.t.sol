// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Bestcrow} from "../src/Bestcrow.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract BestcrowTest is Test {
    event EscrowAccepted(uint256 indexed escrowId, address indexed receiver);
    event EscrowCompleted(uint256 indexed escrowId, address indexed receiver, uint256 totalAmount);

    Bestcrow public bestcrow;
    MockERC20 public token;

    address public depositor = makeAddr("depositor");
    uint256 public constant AMOUNT = 1 ether;
    uint256 public constant MILESTONES = 4;
    uint256 public constant DAYS_TO_EXPIRY = 30;

    address public receiver = makeAddr("receiver");
    uint256 public escrowId; // We'll use this for setup

    address public adminFeeReceiver = makeAddr("adminFeeReceiver");
    uint256 public constant ADMIN_FEE_BASIS_POINTS = 50; // 0.5%

    function setUp() public {
        // Deploy contracts
        bestcrow = new Bestcrow(adminFeeReceiver);
        token = new MockERC20("Test Token", "TEST");

        // Setup depositor with ETH and tokens
        vm.deal(depositor, 10 ether);
        vm.deal(receiver, 10 ether); // Give receiver some ETH too
        token.mint(depositor, 10 ether);
        token.mint(receiver, 10 ether); // Give receiver some tokens too

        // Approve tokens for depositor
        vm.prank(depositor);
        token.approve(address(bestcrow), type(uint256).max);

        // Approve tokens for receiver
        vm.prank(receiver);
        token.approve(address(bestcrow), type(uint256).max);
    }

    function _createEthEscrow() internal returns (uint256) {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;
        
        vm.prank(depositor);
        return bestcrow.createEscrow{value: totalAmount}(address(0), AMOUNT, MILESTONES, DAYS_TO_EXPIRY);
    }

    function _createTokenEscrow() internal returns (uint256) {
        vm.prank(depositor);
        return bestcrow.createEscrow(address(token), AMOUNT, MILESTONES, DAYS_TO_EXPIRY);
    }

    function test_createEscrowWithEth() public {
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;
        
        vm.prank(depositor);
        escrowId = bestcrow.createEscrow{value: totalAmount}(address(0), AMOUNT, MILESTONES, DAYS_TO_EXPIRY);

        // Get the created escrow
        (
            address _depositor,
            address _receiver,
            address _token,
            uint256 _amount,
            uint256 _milestones,
            uint256 _completedMilestones,
            uint256 _expiryDate,
            bool _isActive,
            bool _isCompleted,
        ) = bestcrow.escrows(escrowId);

        // Assert all values are correct
        assertEq(_depositor, depositor);
        assertEq(_receiver, address(0));
        assertEq(_token, address(0));
        assertEq(_amount, AMOUNT);
        assertEq(_milestones, MILESTONES);
        assertEq(_completedMilestones, 0);
        assertEq(_expiryDate, block.timestamp + (DAYS_TO_EXPIRY * 1 days));
        assertTrue(_isActive);
        assertTrue(_isCompleted);
        assertEq(address(bestcrow).balance, totalAmount);
    }

    function test_createEscrowWithToken() public {
        // Calculate admin fee
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;
        
        vm.prank(depositor);
        escrowId = bestcrow.createEscrow(address(token), AMOUNT, MILESTONES, DAYS_TO_EXPIRY);

        // Get the created escrow
        (
            address _depositor,
            address _receiver,
            address _token,
            uint256 _amount,
            uint256 _milestones,
            uint256 _completedMilestones,
            uint256 _expiryDate,
            bool _isActive,
            bool _isEth,
            bool _isCompleted
        ) = bestcrow.escrows(escrowId);

        // Assert all values are correct
        assertEq(_depositor, depositor);
        assertEq(_receiver, address(0));
        assertEq(_token, address(token));
        assertEq(_amount, AMOUNT);
        assertEq(_milestones, MILESTONES);
        assertEq(_completedMilestones, 0);
        assertEq(_expiryDate, block.timestamp + (DAYS_TO_EXPIRY * 1 days));
        assertTrue(_isActive);
        assertFalse(_isEth);
        assertFalse(_isCompleted);
        assertEq(token.balanceOf(address(bestcrow)), totalAmount);
    }

    function testFail_createEscrowWithInvalidMilestones() public {
        vm.prank(depositor);
        bestcrow.createEscrow{value: AMOUNT}(
            address(0),
            AMOUNT,
            0, // Invalid milestone count
            DAYS_TO_EXPIRY
        );
    }

    function testFail_createEscrowWithInvalidAmount() public {
        vm.prank(depositor);
        bestcrow.createEscrow{value: AMOUNT}(
            address(0),
            0, // Invalid amount
            MILESTONES,
            DAYS_TO_EXPIRY
        );
    }

    function testFail_createEscrowWithIncorrectEthAmount() public {
        vm.prank(depositor);
        bestcrow.createEscrow{value: 0.5 ether}( // Sending wrong amount
        address(0), AMOUNT, MILESTONES, DAYS_TO_EXPIRY);
    }

    function test_acceptEscrowWithEth() public {
        uint256 _escrowId = _createEthEscrow();
        uint256 receiverInitialBalance = receiver.balance;
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(receiver);
        bestcrow.acceptEscrow{value: totalAmount}(_escrowId);

        // Get the escrow details
        (address _depositor, address _receiver,,,,,,,,) = bestcrow.escrows(_escrowId);

        // Assert the escrow state
        assertEq(_receiver, receiver);
        assertEq(_depositor, depositor);

        // Assert balances
        assertEq(address(bestcrow).balance, (totalAmount * 2)); // Original deposit + collateral (both including admin fee)
        assertEq(receiver.balance, receiverInitialBalance - totalAmount); // Should have sent collateral + admin fee
    }

    function test_acceptEscrowWithToken() public {
        escrowId = _createTokenEscrow();
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = (2 * AMOUNT) + adminFee;
        uint256 receiverInitialBalance = token.balanceOf(receiver);

        vm.prank(receiver);
        bestcrow.acceptEscrow(escrowId);

        // Get the escrow details
        (address _depositor, address _receiver,,,,,,,,) = bestcrow.escrows(escrowId);

        // Assert the escrow state
        assertEq(_receiver, receiver);
        assertEq(_depositor, depositor);

        // Assert balances with corrected calculation
        assertEq(token.balanceOf(address(bestcrow)), totalAmount);
        assertEq(token.balanceOf(receiver), receiverInitialBalance - AMOUNT);
    }

    function testFail_acceptExpiredEscrow() public {
        uint256 _escrowId = _createEthEscrow();
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        // Fast forward past expiry
        vm.warp(block.timestamp + (DAYS_TO_EXPIRY * 1 days) + 1);

        vm.prank(receiver);
        bestcrow.acceptEscrow{value: totalAmount}(_escrowId);
    }

    function testFail_acceptAlreadyAcceptedEscrow() public {
        escrowId = _createEthEscrow();
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        // First acceptance
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: totalAmount}(escrowId);

        // Create another receiver
        address receiver2 = makeAddr("receiver2");
        vm.deal(receiver2, totalAmount);  // Give enough ETH including admin fee

        // Try to accept again
        vm.prank(receiver2);
        bestcrow.acceptEscrow{value: totalAmount}(escrowId);
    }

    function testFail_acceptEscrowAsDepositor() public {
        escrowId = _createEthEscrow();
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(depositor);
        bestcrow.acceptEscrow{value: totalAmount}(escrowId);
    }

    function testFail_acceptEscrowWithIncorrectEthAmount() public {
        escrowId = _createEthEscrow();
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        vm.prank(receiver);
        bestcrow.acceptEscrow{value: totalAmount - 0.1 ether}(escrowId);
    }

    function testFail_acceptInactiveEscrow() public {
        escrowId = _createEthEscrow();
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = AMOUNT + adminFee;

        // Complete the escrow somehow (you might need to add a function for this in your contract)
        // For now, let's assume it's expired and refunded
        vm.warp(block.timestamp + (DAYS_TO_EXPIRY * 1 days) + 1);
        bestcrow.refundExpiredEscrow(escrowId);

        vm.prank(receiver);
        bestcrow.acceptEscrow{value: totalAmount}(escrowId);
    }

    function test_acceptEscrowEmitsEvent() public {
        escrowId = _createEthEscrow();

        vm.prank(receiver);

        vm.expectEmit(true, true, false, false);
        emit EscrowAccepted(escrowId, receiver);

        bestcrow.acceptEscrow{value: AMOUNT}(escrowId);
    }

    function test_escrowCompletionWithEth() public {
        // Setup escrow
        uint256 _escrowId = _createEthEscrow();

        // Accept escrow
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: AMOUNT}(_escrowId);

        // Complete all milestones
        for (uint256 i = 0; i < MILESTONES; i++) {
            vm.prank(receiver);

            // For the last milestone, expect completion event
            if (i == MILESTONES - 1) {
                vm.expectEmit(true, true, false, true);
                emit EscrowCompleted(_escrowId, receiver, AMOUNT * 2);
            }

            bestcrow.requestMilestoneCompletion(_escrowId);
        }

        // Check final state
        assertTrue(bestcrow.isEscrowCompleted(_escrowId));
        (,,,,,,, bool isActive,,) = bestcrow.escrows(_escrowId);
        assertFalse(isActive);
        assertEq(address(bestcrow).balance, 0); // All funds should be released
    }

    function test_escrowCompletionWithToken() public {
        // Setup escrow
        uint256 _escrowId = _createTokenEscrow();

        // Accept escrow
        vm.prank(receiver);
        bestcrow.acceptEscrow(_escrowId);

        // Complete all milestones
        for (uint256 i = 0; i < MILESTONES; i++) {
            vm.prank(receiver);

            // For the last milestone, expect completion event
            if (i == MILESTONES - 1) {
                vm.expectEmit(true, true, false, true);
                emit EscrowCompleted(_escrowId, receiver, AMOUNT * 2);
            }

            bestcrow.requestMilestoneCompletion(_escrowId);
        }

        // Check final state
        assertTrue(bestcrow.isEscrowCompleted(_escrowId));
        (,,,,,,,, bool isActive,) = bestcrow.escrows(_escrowId);
        assertFalse(isActive);
        assertEq(token.balanceOf(address(bestcrow)), 0); // All funds should be released
    }

    function test_refundExpiredEscrowWithEth() public {
        uint256 _escrowId = _createEthEscrow();
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 depositorInitialBalance = depositor.balance;
        
        // Fast forward past expiry
        vm.warp(block.timestamp + (DAYS_TO_EXPIRY * 1 days) + 1);
        
        vm.prank(depositor);
        bestcrow.refundExpiredEscrow(_escrowId);
        
        // Check balances
        assertEq(depositor.balance, depositorInitialBalance + AMOUNT + adminFee);
        assertEq(address(bestcrow).balance, 0);
        
        // Check escrow state
        (,,,,,,,bool isActive,,) = bestcrow.escrows(_escrowId);
        assertFalse(isActive);
    }
    
    function test_refundExpiredEscrowWithToken() public {
        uint256 _escrowId = _createTokenEscrow();
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 depositorInitialBalance = token.balanceOf(depositor);
        
        // Fast forward past expiry
        vm.warp(block.timestamp + (DAYS_TO_EXPIRY * 1 days) + 1);
        
        vm.prank(depositor);
        bestcrow.refundExpiredEscrow(_escrowId);
        
        // Check balances
        assertEq(token.balanceOf(depositor), depositorInitialBalance + AMOUNT + adminFee);
        assertEq(token.balanceOf(address(bestcrow)), 0);
        
        // Check escrow state
        (,,,,,,,bool isActive,,) = bestcrow.escrows(_escrowId);
        assertFalse(isActive);
    }
    
    function testFail_refundNonExpiredEscrow() public {
        uint256 _escrowId = _createEthEscrow();
        
        vm.prank(depositor);
        bestcrow.refundExpiredEscrow(_escrowId); // Should fail as not expired
    }
    
    function testFail_refundAcceptedEscrow() public {
        uint256 _escrowId = _createEthEscrow();
        
        // Accept the escrow
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: AMOUNT}(_escrowId);
        
        // Fast forward past expiry
        vm.warp(block.timestamp + (DAYS_TO_EXPIRY * 1 days) + 1);
        
        vm.prank(depositor);
        bestcrow.refundExpiredEscrow(_escrowId); // Should fail as escrow was accepted
    }
    
    function testFail_refundByNonDepositor() public {
        uint256 _escrowId = _createEthEscrow();
        
        // Fast forward past expiry
        vm.warp(block.timestamp + (DAYS_TO_EXPIRY * 1 days) + 1);
        
        vm.prank(receiver);
        bestcrow.refundExpiredEscrow(_escrowId); // Should fail as caller is not depositor
    }

    function test_adminFeeTransferOnCompletion() public {
        uint256 _escrowId = _createEthEscrow();
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 adminInitialBalance = adminFeeReceiver.balance;
        
        // Accept escrow
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: AMOUNT}(_escrowId);
        
        // Complete all milestones
        for (uint256 i = 0; i < MILESTONES; i++) {
            vm.prank(receiver);
            bestcrow.requestMilestoneCompletion(_escrowId);
        }
        
        // Check admin fee was transferred
        assertEq(adminFeeReceiver.balance, adminInitialBalance + adminFee);
    }
    
    function test_adminFeeTransferOnTokenCompletion() public {
        uint256 _escrowId = _createTokenEscrow();
        uint256 adminFee = (AMOUNT * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 adminInitialBalance = token.balanceOf(adminFeeReceiver);
        
        // Accept escrow
        vm.prank(receiver);
        bestcrow.acceptEscrow(_escrowId);
        
        // Complete all milestones
        for (uint256 i = 0; i < MILESTONES; i++) {
            vm.prank(receiver);
            bestcrow.requestMilestoneCompletion(_escrowId);
        }
        
        // Check admin fee was transferred
        assertEq(token.balanceOf(adminFeeReceiver), adminInitialBalance + adminFee);
    }

    function _calculateAdminFee(uint256 amount) internal pure returns (uint256) {
        return (amount * ADMIN_FEE_BASIS_POINTS) / 10000;
    }
}
