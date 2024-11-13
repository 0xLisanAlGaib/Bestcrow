// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Bestcrow} from "../src/Bestcrow.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract BestcrowTest is Test {
    event EscrowAccepted(uint256 indexed escrowId, address indexed receiver);

    Bestcrow public bestcrow;
    MockERC20 public token;

    address public depositor = makeAddr("depositor");
    uint256 public constant AMOUNT = 1 ether;
    uint256 public constant MILESTONES = 4;
    uint256 public constant DAYS_TO_EXPIRY = 30;

    address public receiver = makeAddr("receiver");
    uint256 public escrowId; // We'll use this for setup

    function setUp() public {
        // Deploy contracts
        bestcrow = new Bestcrow();
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
        vm.prank(depositor);
        return bestcrow.createEscrow{value: AMOUNT}(address(0), AMOUNT, MILESTONES, DAYS_TO_EXPIRY);
    }

    function _createTokenEscrow() internal returns (uint256) {
        vm.prank(depositor);
        return bestcrow.createEscrow(address(token), AMOUNT, MILESTONES, DAYS_TO_EXPIRY);
    }

    function test_createEscrowWithEth() public {
        vm.prank(depositor);

        // Create escrow with ETH
        escrowId = bestcrow.createEscrow{value: AMOUNT}(address(0), AMOUNT, MILESTONES, DAYS_TO_EXPIRY);

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
            bool _isEth
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
        assertTrue(_isEth);
        assertEq(address(bestcrow).balance, AMOUNT);
    }

    function test_createEscrowWithToken() public {
        // Switch to depositor context
        vm.prank(depositor);

        // Create escrow with ERC20 token
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
            bool _isEth
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
        assertEq(token.balanceOf(address(bestcrow)), AMOUNT);
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

        vm.prank(receiver);
        bestcrow.acceptEscrow{value: AMOUNT}(_escrowId);

        // Get the escrow details
        (address _depositor, address _receiver,,,,,,,) = bestcrow.escrows(_escrowId);

        // Assert the escrow state
        assertEq(_receiver, receiver);
        assertEq(_depositor, depositor);

        // Assert balances
        assertEq(address(bestcrow).balance, AMOUNT * 2); // Original deposit + collateral
        assertEq(receiver.balance, receiverInitialBalance - AMOUNT); // Should have sent collateral
    }

    function test_acceptEscrowWithToken() public {
        escrowId = _createTokenEscrow();
        uint256 receiverInitialBalance = token.balanceOf(receiver);

        vm.prank(receiver);
        bestcrow.acceptEscrow(escrowId);

        // Get the escrow details
        (address _depositor, address _receiver,,,,,,,) = bestcrow.escrows(escrowId);

        // Assert the escrow state
        assertEq(_receiver, receiver);
        assertEq(_depositor, depositor);

        // Assert balances
        assertEq(token.balanceOf(address(bestcrow)), AMOUNT * 2); // Original deposit + collateral
        assertEq(token.balanceOf(receiver), receiverInitialBalance - AMOUNT); // Should have sent collateral
    }

    function testFail_acceptExpiredEscrow() public {
        uint256 _escrowId = _createEthEscrow();

        // Fast forward past expiry
        vm.warp(block.timestamp + (DAYS_TO_EXPIRY * 1 days) + 1);

        vm.prank(receiver);
        bestcrow.acceptEscrow{value: AMOUNT}(_escrowId);
    }

    function testFail_acceptAlreadyAcceptedEscrow() public {
        escrowId = _createEthEscrow();

        // First acceptance
        vm.prank(receiver);
        bestcrow.acceptEscrow{value: AMOUNT}(escrowId);

        // Create another receiver
        address receiver2 = makeAddr("receiver2");
        vm.deal(receiver2, AMOUNT);

        // Try to accept again
        vm.prank(receiver2);
        bestcrow.acceptEscrow{value: AMOUNT}(escrowId);
    }

    function testFail_acceptEscrowAsDepositor() public {
        escrowId = _createEthEscrow();

        vm.prank(depositor);
        bestcrow.acceptEscrow{value: AMOUNT}(escrowId);
    }

    function testFail_acceptEscrowWithIncorrectEthAmount() public {
        escrowId = _createEthEscrow();

        vm.prank(receiver);
        bestcrow.acceptEscrow{value: AMOUNT - 0.1 ether}(escrowId);
    }

    function testFail_acceptInactiveEscrow() public {
        escrowId = _createEthEscrow();

        // Complete the escrow somehow (you might need to add a function for this in your contract)
        // For now, let's assume it's expired and refunded
        vm.warp(block.timestamp + (DAYS_TO_EXPIRY * 1 days) + 1);
        bestcrow.refundExpiredEscrow(escrowId);

        vm.prank(receiver);
        bestcrow.acceptEscrow{value: AMOUNT}(escrowId);
    }

    function test_acceptEscrowEmitsEvent() public {
        escrowId = _createEthEscrow();

        vm.prank(receiver);

        vm.expectEmit(true, true, false, false);
        emit EscrowAccepted(escrowId, receiver);

        bestcrow.acceptEscrow{value: AMOUNT}(escrowId);
    }
}
