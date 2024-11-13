// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Bestcrow} from "../src/Bestcrow.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract BestcrowTest is Test {
    Bestcrow public bestcrow;
    MockERC20 public token;
    
    address public depositor = makeAddr("depositor");
    uint256 public constant AMOUNT = 1 ether;
    uint256 public constant MILESTONES = 4;
    uint256 public constant DAYS_TO_EXPIRY = 30;

    function setUp() public {
        // Deploy contracts
        bestcrow = new Bestcrow();
        token = new MockERC20("Test Token", "TEST");

        // Setup depositor with ETH and tokens
        vm.deal(depositor, 10 ether);
        token.mint(depositor, 10 ether);

        // Approve tokens for depositor
        vm.prank(depositor);
        token.approve(address(bestcrow), type(uint256).max);
    }

    function test_createEscrowWithEth() public {
        // Switch to depositor context
        vm.prank(depositor);

        // Create escrow with ETH
        uint256 escrowId = bestcrow.createEscrow{value: AMOUNT}(
            address(0), // address(0) indicates ETH
            AMOUNT,
            MILESTONES,
            DAYS_TO_EXPIRY
        );

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
        uint256 escrowId = bestcrow.createEscrow(
            address(token),
            AMOUNT,
            MILESTONES,
            DAYS_TO_EXPIRY
        );

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
            address(0),
            AMOUNT,
            MILESTONES,
            DAYS_TO_EXPIRY
        );
    }
}
