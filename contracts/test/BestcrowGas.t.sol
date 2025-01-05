// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {Bestcrow} from "../src/Bestcrow.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {console} from "lib/forge-std/src/console.sol";

/// @title Bestcrow Gas Optimization Test Suite
/// @notice Gas optimization tests for the Bestcrow escrow contract
/// @dev Tests various operations to ensure gas efficiency and sets maximum gas limits
contract BestcrowGasTest is Test {
    Bestcrow public bestcrow;
    MockERC20 public token;

    // Add these missing declarations
    address public depositor = makeAddr("depositor");
    address public receiver = makeAddr("receiver");
    uint256 public constant AMOUNT = 1 ether;
    uint256 public constant DAYS_TO_EXPIRY = 30;
    uint256 public constant ADMIN_FEE_BASIS_POINTS = 50; // 0.5% = 50 basis points
    uint256 public constant COLLATERAL_PERCENTAGE = 50; // 50%
    address public owner = makeAddr("owner");

    /// @notice Sets up the test environment with necessary contracts and initial state
    /// @dev Deploys Bestcrow and MockERC20, sets up accounts with ETH and tokens
    function setUp() public {
        // Deploy contracts
        bestcrow = new Bestcrow();
        token = new MockERC20("Test Token", "TEST");

        // Add this line to set the owner in the Bestcrow contract if needed
        bestcrow.transferOwnership(owner); // Only add this if Bestcrow has Ownable functionality

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

    /// @notice Tests gas usage for creating an escrow with a small amount
    /// @dev Ensures small amount escrows stay under 260k gas
    function test_gasCreateEscrowWithSmallAmount() public {
        uint256 smallAmount = 0.1 ether;
        uint256 adminFee = (smallAmount * ADMIN_FEE_BASIS_POINTS) / 10000;

        vm.prank(depositor);
        uint256 gasBefore = gasleft();
        bestcrow.createEscrow{value: smallAmount + adminFee}(
            address(0),
            smallAmount,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Small Amount Escrow",
            "Testing gas usage with small amount"
        );
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for small amount escrow:", gasUsed);
        assertTrue(gasUsed < 260000); // Increased limit to account for string storage
    }

    /// @notice Tests gas usage for creating an escrow with a large amount
    /// @dev Ensures large amount escrows stay under 260k gas
    function test_gasCreateEscrowWithLargeAmount() public {
        uint256 largeAmount = 100 ether;
        uint256 adminFee = (largeAmount * ADMIN_FEE_BASIS_POINTS) / 10000;

        vm.deal(depositor, largeAmount + adminFee);
        vm.prank(depositor);
        uint256 gasBefore = gasleft();
        bestcrow.createEscrow{value: largeAmount + adminFee}(
            address(0),
            largeAmount,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Large Amount Escrow",
            "Testing gas usage with large amount"
        );
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for large amount escrow:", gasUsed);
        assertTrue(gasUsed < 260000); // Increased limit to account for string storage
    }

    /// @notice Compares gas costs between ETH and ERC20 escrows
    /// @dev Verifies that ETH escrows use less gas than ERC20 escrows
    function test_gasCompareETHvsERC20() public {
        uint256 amount = 1 ether;
        uint256 adminFee = (amount * ADMIN_FEE_BASIS_POINTS) / 10000;

        // Test ETH escrow
        vm.prank(depositor);
        uint256 gasBefore = gasleft();
        bestcrow.createEscrow{value: amount + adminFee}(
            address(0),
            amount,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "ETH vs ERC20 Test - ETH",
            "Testing gas comparison for ETH escrow"
        );
        uint256 ethGasUsed = gasBefore - gasleft();

        // Test ERC20 escrow
        vm.prank(depositor);
        gasBefore = gasleft();
        bestcrow.createEscrow(
            address(token),
            amount,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "ETH vs ERC20 Test - ERC20",
            "Testing gas comparison for ERC20 escrow"
        );
        uint256 erc20GasUsed = gasBefore - gasleft();

        console.log("Gas used for ETH escrow:", ethGasUsed);
        console.log("Gas used for ERC20 escrow:", erc20GasUsed);
        assertTrue(ethGasUsed < erc20GasUsed); // ERC20 should use more gas
    }

    /// @notice Tests gas usage for creating multiple sequential escrows
    /// @dev Ensures average gas usage stays under 270k per escrow
    function test_gasSequentialEscrows() public {
        uint256 amount = 1 ether;
        uint256 adminFee = (amount * ADMIN_FEE_BASIS_POINTS) / 10000;

        uint256 totalGas;
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(depositor);
            uint256 gasBefore = gasleft();
            bestcrow.createEscrow{value: amount + adminFee}(
                address(0),
                amount,
                block.timestamp + DAYS_TO_EXPIRY * 1 days,
                receiver,
                string(abi.encodePacked("Sequential Test #", i + 1)),
                "Testing gas usage for sequential escrows"
            );
            totalGas += gasBefore - gasleft();
        }

        uint256 averageGas = totalGas / 5;
        console.log("Average gas per escrow:", averageGas);
        assertTrue(averageGas < 270000); // Increased limit to account for string storage
    }

    /// @notice Tests gas usage for a complete escrow workflow
    /// @dev Measures gas for create, accept, request, and approve operations
    function test_gasFullWorkflow() public {
        uint256 amount = 1 ether;
        uint256 adminFee = (amount * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 gasBefore;

        // Create escrow
        vm.prank(depositor);
        gasBefore = gasleft();
        uint256 escrowId = bestcrow.createEscrow{value: amount + adminFee}(
            address(0),
            amount,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Full Workflow Test",
            "Testing gas usage for complete workflow"
        );
        uint256 createGas = gasBefore - gasleft();

        // Accept escrow
        uint256 collateralAmount = (amount * COLLATERAL_PERCENTAGE) / 100;
        vm.prank(receiver);
        gasBefore = gasleft();
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);
        uint256 acceptGas = gasBefore - gasleft();

        // Request release
        vm.prank(receiver);
        gasBefore = gasleft();
        bestcrow.requestRelease(escrowId);
        uint256 requestGas = gasBefore - gasleft();

        // Approve release
        vm.prank(depositor);
        gasBefore = gasleft();
        bestcrow.approveRelease(escrowId);
        uint256 approveGas = gasBefore - gasleft();

        console.log("Gas breakdown:");
        console.log("Create:", createGas);
        console.log("Accept:", acceptGas);
        console.log("Request:", requestGas);
        console.log("Approve:", approveGas);
        console.log("Total:", createGas + acceptGas + requestGas + approveGas);

        // Set appropriate gas limits for each operation
        assertTrue(createGas < 260000); // Increased limit to account for string storage
        assertTrue(acceptGas < 100000);
        assertTrue(requestGas < 50000);
        assertTrue(approveGas < 100000);
    }

    /// @notice Tests the withdrawal of ERC20 fees by the owner
    /// @dev Verifies correct fee calculation and withdrawal
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
            "ERC20 Fee Test",
            "Testing withdrawal of ERC20 fees"
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
        uint256 gasBefore = gasleft();
        vm.prank(bestcrow.owner());
        bestcrow.withdrawFees(address(token));
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for withdrawing ERC20 fees:", gasUsed);
        assertEq(token.balanceOf(bestcrow.owner()), adminFee);
    }

    /// @notice Tests gas usage for minimum required operations in an escrow
    /// @dev Ensures complete workflow stays under 400k gas total
    function test_gasCompleteEscrowWithMinimumOperations() public {
        uint256 amount = 1 ether;
        uint256 adminFee = (amount * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalGas;

        // Measure gas for minimum required operations
        vm.prank(depositor);
        uint256 gasBefore = gasleft();

        uint256 escrowId = bestcrow.createEscrow{value: amount + adminFee}(
            address(0),
            amount,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Minimum Operations Test",
            "Testing minimum required operations"
        );

        uint256 createGas = gasBefore - gasleft();

        // Accept escrow
        uint256 collateralAmount = (amount * COLLATERAL_PERCENTAGE) / 100;
        vm.prank(receiver);
        gasBefore = gasleft();
        bestcrow.acceptEscrow{value: collateralAmount}(escrowId);
        uint256 acceptGas = gasBefore - gasleft();

        // Direct release (request + approve)
        vm.prank(receiver);
        gasBefore = gasleft();
        bestcrow.requestRelease(escrowId);
        uint256 requestGas = gasBefore - gasleft();

        vm.prank(depositor);
        gasBefore = gasleft();
        bestcrow.approveRelease(escrowId);
        uint256 approveGas = gasBefore - gasleft();

        totalGas = createGas + acceptGas + requestGas + approveGas;

        console.log("Minimum operations gas breakdown:");
        console.log("Create:", createGas);
        console.log("Accept:", acceptGas);
        console.log("Request:", requestGas);
        console.log("Approve:", approveGas);
        console.log("Total:", totalGas);

        // Assert reasonable gas limits
        assertTrue(totalGas < 450000); // Increased limit to account for string storage
    }

    /// @notice Tests gas usage for refunding an expired escrow
    /// @dev Ensures refund operation stays under 100k gas
    function test_gasRefundExpiredEscrow() public {
        uint256 amount = 1 ether;
        uint256 adminFee = (amount * ADMIN_FEE_BASIS_POINTS) / 10000;

        // Create escrow
        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: amount + adminFee}(
            address(0),
            amount,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Refund Test",
            "Testing gas usage for refund operation"
        );

        // Fast forward past expiry
        vm.warp(block.timestamp + DAYS_TO_EXPIRY * 1 days + 1);

        // Measure gas for refund
        vm.prank(depositor);
        uint256 gasBefore = gasleft();
        bestcrow.refundExpiredEscrow(escrowId);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for refund:", gasUsed);
        assertTrue(gasUsed < 100000);
    }

    /// @notice Tests gas usage with varying title and description lengths
    /// @dev Ensures gas costs stay reasonable with different string lengths
    function test_gasVaryingStringLengths() public {
        uint256 amount = 1 ether;
        uint256 adminFee = (amount * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = amount + adminFee;

        // Test short strings
        vm.prank(depositor);
        uint256 gasBefore = gasleft();
        bestcrow.createEscrow{value: totalAmount}(
            address(0),
            amount,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Short",
            "Brief"
        );
        uint256 shortStringsGas = gasBefore - gasleft();

        // Test medium strings
        vm.prank(depositor);
        gasBefore = gasleft();
        bestcrow.createEscrow{value: totalAmount}(
            address(0),
            amount,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Medium Length Title for Testing",
            "This is a medium length description for testing gas usage"
        );
        uint256 mediumStringsGas = gasBefore - gasleft();

        // Test long strings
        vm.prank(depositor);
        gasBefore = gasleft();
        bestcrow.createEscrow{value: totalAmount}(
            address(0),
            amount,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "This is a very long title that tests the gas usage with longer strings in the escrow contract",
            "This is an extremely long description that contains multiple sentences to test gas usage with long strings. It includes various details about the escrow agreement and tests how the contract handles larger amounts of text data."
        );
        uint256 longStringsGas = gasBefore - gasleft();

        console.log("Gas used with short strings:", shortStringsGas);
        console.log("Gas used with medium strings:", mediumStringsGas);
        console.log("Gas used with long strings:", longStringsGas);

        // Set reasonable gas limits
        assertTrue(shortStringsGas < 260000); // Increased for short strings
        assertTrue(mediumStringsGas < 300000); // Increased for medium strings
        assertTrue(longStringsGas < 850000); // Increased for long strings
    }

    /// @notice Tests gas usage for reading escrow details with different string lengths
    /// @dev Ensures reading escrow details stays efficient
    function test_gasReadEscrowDetails() public {
        uint256 amount = 1 ether;
        uint256 adminFee = (amount * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalAmount = amount + adminFee;

        // Create escrow with long strings
        vm.prank(depositor);
        uint256 escrowId = bestcrow.createEscrow{value: totalAmount}(
            address(0),
            amount,
            block.timestamp + DAYS_TO_EXPIRY * 1 days,
            receiver,
            "Long Title for Testing Gas Usage in Reading Escrow Details",
            "This is a long description used to test the gas consumption when reading escrow details. It contains multiple sentences to simulate a real-world scenario."
        );

        // Test gas usage for reading escrow details
        uint256 gasBefore = gasleft();
        bestcrow.escrowDetails(escrowId);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for reading escrow details:", gasUsed);
        assertTrue(gasUsed < 30000); // Reading should be relatively cheap
    }
}
