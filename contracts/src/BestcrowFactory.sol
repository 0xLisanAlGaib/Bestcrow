// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Bestcrow} from "./Bestcrow.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title BestcrowFactory
 * @author @0xLisanAlGaib
 * @notice Factory contract for deploying new Bestcrow instances
 * @dev Creates and keeps track of all deployed Bestcrow contracts
 */
contract BestcrowFactory is Ownable {
    /// @notice Array to store addresses of all deployed Bestcrow contracts
    address[] public deployedBestcrows;

    /// @notice Emitted when a new Bestcrow contract is deployed
    event BestcrowDeployed(
        address indexed bestcrowAddress,
        address indexed depositor,
        address indexed receiver,
        address token,
        uint256 amount
    );

    /**
     * @notice Initializes the factory with the deployer as owner
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Creates a new Bestcrow contract and initiates the first escrow
     * @dev The factory owner becomes the owner of the new Bestcrow contract
     * @param _token The token address (address(0) for ETH)
     * @param _amount The amount to be escrowed
     * @param _expiryDate The timestamp when the escrow expires
     * @param _receiver The address that can claim the escrowed funds
     * @return The address of the newly deployed Bestcrow contract
     */
    function createBestcrowAndEscrow(
        address _token,
        uint256 _amount,
        uint256 _expiryDate,
        address _receiver
    ) external payable returns (address) {
        // Deploy new Bestcrow contract with factory owner as the owner
        Bestcrow newBestcrow = new Bestcrow();

        // Create the escrow in the new contract
        if (_token == address(0)) {
            // For ETH escrows
            newBestcrow.createEscrow{value: msg.value}(
                _token,
                _amount,
                _expiryDate,
                _receiver
            );
        } else {
            // For ERC20 escrows
            // Approve the new contract to spend tokens
            IERC20(_token).approve(address(newBestcrow), _amount);
            newBestcrow.createEscrow(_token, _amount, _expiryDate, _receiver);
        }

        deployedBestcrows.push(address(newBestcrow));

        emit BestcrowDeployed(
            address(newBestcrow),
            msg.sender,
            _receiver,
            _token,
            _amount
        );

        return address(newBestcrow);
    }

    /**
     * @notice Returns the number of deployed Bestcrow contracts
     * @return The total count of deployed contracts
     */
    function getDeployedBestcrowsCount() external view returns (uint256) {
        return deployedBestcrows.length;
    }

    /**
     * @notice Returns all deployed Bestcrow contract addresses
     * @return Array of deployed Bestcrow addresses
     */
    function getDeployedBestcrows() external view returns (address[] memory) {
        return deployedBestcrows;
    }
}
