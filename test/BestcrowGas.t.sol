// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/Bestcrow.sol";
import "./mocks/MockERC20.sol";
import "forge-std/console.sol";

// Gas Optimization Test Suite
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

    // Test gas costs for different escrow amounts
    function test_gasCreateEscrowWithSmallAmount() public {
        uint256 smallAmount = 0.1 ether;
        uint256 adminFee = (smallAmount * ADMIN_FEE_BASIS_POINTS) / 10000;

        vm.prank(depositor);
        uint256 gasBefore = gasleft();
        bestcrow.createEscrow{value: smallAmount + adminFee}(
            address(0), smallAmount, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for small amount escrow:", gasUsed);
        assertTrue(gasUsed < 120000); // Baseline gas limit
    }

    function test_gasCreateEscrowWithLargeAmount() public {
        uint256 largeAmount = 100 ether;
        uint256 adminFee = (largeAmount * ADMIN_FEE_BASIS_POINTS) / 10000;

        vm.deal(depositor, largeAmount + adminFee);
        vm.prank(depositor);
        uint256 gasBefore = gasleft();
        bestcrow.createEscrow{value: largeAmount + adminFee}(
            address(0), largeAmount, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for large amount escrow:", gasUsed);
        assertTrue(gasUsed < 120000); // Should be similar to small amount
    }

    // Test gas costs for different token types
    function test_gasCompareETHvsERC20() public {
        uint256 amount = 1 ether;
        uint256 adminFee = (amount * ADMIN_FEE_BASIS_POINTS) / 10000;

        // Test ETH escrow
        vm.prank(depositor);
        uint256 gasBefore = gasleft();
        bestcrow.createEscrow{value: amount + adminFee}(
            address(0), amount, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
        );
        uint256 ethGasUsed = gasBefore - gasleft();

        // Test ERC20 escrow
        vm.prank(depositor);
        gasBefore = gasleft();
        bestcrow.createEscrow(address(token), amount, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver);
        uint256 erc20GasUsed = gasBefore - gasleft();

        console.log("Gas used for ETH escrow:", ethGasUsed);
        console.log("Gas used for ERC20 escrow:", erc20GasUsed);
        assertTrue(ethGasUsed < erc20GasUsed); // ERC20 should use more gas
    }

    // Test gas costs for sequential operations
    function test_gasSequentialEscrows() public {
        uint256 amount = 1 ether;
        uint256 adminFee = (amount * ADMIN_FEE_BASIS_POINTS) / 10000;

        uint256 totalGas;
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(depositor);
            uint256 gasBefore = gasleft();
            bestcrow.createEscrow{value: amount + adminFee}(
                address(0), amount, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
            );
            totalGas += gasBefore - gasleft();
        }

        uint256 averageGas = totalGas / 5;
        console.log("Average gas per escrow:", averageGas);
        assertTrue(averageGas < 120000);
    }

    // Test gas costs for complete workflow
    function test_gasFullWorkflow() public {
        uint256 amount = 1 ether;
        uint256 adminFee = (amount * ADMIN_FEE_BASIS_POINTS) / 10000;
        uint256 totalGas;
        uint256 gasBefore;

        // Create escrow
        vm.prank(depositor);
        gasBefore = gasleft();
        uint256 escrowId = bestcrow.createEscrow{value: amount + adminFee}(
            address(0), amount, block.timestamp + DAYS_TO_EXPIRY * 1 days, receiver
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
        assertTrue(createGas < 120000);
        assertTrue(acceptGas < 80000);
        assertTrue(requestGas < 50000);
        assertTrue(approveGas < 100000);
    }
}
