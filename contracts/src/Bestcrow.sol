// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Bestcrow
 * @author @0xLisanAlGaib
 * @notice A decentralized escrow contract for ETH and ERC20 tokens.
 * @dev Uses SafeERC20, ReentrancyGuard, and Ownable for security and functionality.
 * @custom:security-contact security@bestcrow.com
 */
contract Bestcrow is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /**
     * @notice The administrative fee in basis points (0.5%).
     * @dev 50 basis points = 0.5%
     */
    uint256 public constant ADMIN_FEE_BASIS_POINTS = 50;
    /**
     * @notice The denominator for basis points calculations
     * @dev 10000 basis points = 100%
     */
    uint256 public constant BASIS_POINTS_DENOMINATOR = 10000;
    /**
     * @notice The collateral percentage required from the receiver in basis points
     * @dev 5000 basis points = 50%
     */
    uint256 public constant COLLATERAL_PERCENTAGE_BASIS_POINTS = 5000;

    /**
     * @notice Tracks the total ETH fees collected by the contract
     * @dev Accumulated fees can be withdrawn by the contract owner
     */
    uint256 public accruedFeesETH;
    /**
     * @notice Tracks the total ERC20 fees collected per token
     * @dev Mapping of token address to accumulated fee amount
     */
    mapping(address => uint256) public accruedFeesERC20;

    /**
     * @notice Represents an escrow agreement between two parties
     * @dev All escrow details are stored in this structure
     * @param depositor The address that creates and funds the escrow
     * @param receiver The intended recipient of the escrowed funds
     * @param token The token being escrowed (address(0) for ETH)
     * @param amount The amount of tokens/ETH in escrow
     * @param expiryDate The timestamp after which the escrow can be refunded
     * @param isActive Whether the escrow has been accepted by receiver
     * @param isCompleted Whether the escrow has been completed successfully
     * @param isEth Whether the escrow is for ETH (true) or ERC20 (false)
     * @param releaseRequested Whether the receiver has requested fund release
     * @param title Title of the escrow agreement
     * @param description Detailed description of the escrow agreement
     */
    struct Escrow {
        address depositor; // The address that creates the escrow.
        address receiver; // The intended recipient of the funds.
        address token; // The token being escrowed (use address(0) for ETH).
        uint256 amount; // The amount to be held in escrow.
        uint256 expiryDate; // The timestamp when the escrow expires.
        uint256 createdAt; // The timestamp when the escrow was created
        bool isActive; // Whether the escrow is active.
        bool isCompleted; // Whether the escrow has been completed.
        bool isEth; // Whether the escrow is for ETH.
        bool releaseRequested; // Whether the release of funds has been requested.
        string title; // Title of the escrow agreement
        string description; // Detailed description of the escrow agreement
    }

    /**
     * @notice Counter for generating unique escrow IDs
     * @dev Increments by 1 for each new escrow
     */
    uint256 public nextEscrowId;
    /**
     * @notice Maps escrow IDs to their corresponding Escrow struct
     */
    mapping(uint256 => Escrow) public escrows;

    /// @notice Emitted when a new escrow is created.
    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed depositor,
        address indexed receiver,
        address token,
        uint256 amount,
        uint256 expiryDate
    );
    /// @notice Emitted when an escrow is accepted by the receiver.
    event EscrowAccepted(uint256 indexed escrowId, address indexed receiver);
    /// @notice Emitted when the release of an escrow is requested.
    event ReleaseRequested(uint256 indexed escrowId);
    /// @notice Emitted when an escrow is completed and funds are released to the receiver.
    event EscrowCompleted(
        uint256 indexed escrowId,
        address indexed receiver,
        uint256 amount
    );
    /// @notice Emitted when an escrow is refunded to the depositor.
    event EscrowRefunded(uint256 indexed escrowId, address indexed depositor);
    /// @notice Emitted when fees are withdrawn by the contract owner.
    event FeesWithdrawn(address token, uint256 amount);

    /**
     * @notice Initializes the contract with the deployer as owner
     * @dev Calls Ownable constructor with msg.sender
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Creates a new escrow agreement
     * @dev Transfers funds from sender to contract and creates escrow record
     * @param _token The token address (address(0) for ETH)
     * @param _amount The amount to be escrowed
     * @param _expiryDate The timestamp when the escrow expires
     * @param _receiver The address that can claim the escrowed funds
     * @param _title Title of the escrow agreement
     * @param _description Detailed description of the escrow agreement
     * @return escrowId The unique identifier for the created escrow
     */
    function createEscrow(
        address _token,
        uint256 _amount,
        uint256 _expiryDate,
        address _receiver,
        string memory _title,
        string memory _description
    ) external payable returns (uint256) {
        require(_amount > 0, "Invalid amount");
        require(_receiver != address(0), "Invalid receiver");
        require(_receiver != msg.sender, "Receiver cannot be depositor");
        require(_expiryDate > block.timestamp, "Invalid expiry date");
        require(bytes(_title).length > 0, "Title cannot be empty");

        uint256 adminFee = (_amount * ADMIN_FEE_BASIS_POINTS) /
            BASIS_POINTS_DENOMINATOR;
        bool isEth = _token == address(0);

        if (isEth) {
            require(msg.value == _amount + adminFee, "Incorrect ETH amount");
        } else {
            IERC20(_token).safeTransferFrom(
                msg.sender,
                address(this),
                _amount + adminFee
            );
        }

        nextEscrowId++;
        escrows[nextEscrowId] = Escrow({
            depositor: msg.sender,
            receiver: _receiver,
            token: _token,
            amount: _amount,
            expiryDate: _expiryDate,
            createdAt: block.timestamp,
            isActive: false,
            isCompleted: false,
            isEth: isEth,
            releaseRequested: false,
            title: _title,
            description: _description
        });

        emit EscrowCreated(
            nextEscrowId,
            msg.sender,
            _receiver,
            _token,
            _amount,
            _expiryDate
        );
        return nextEscrowId;
    }

    /**
     * @notice Allows the receiver to accept an escrow by providing collateral
     * @dev Transfers collateral from receiver to contract
     * @param _escrowId The ID of the escrow to accept
     */
    function acceptEscrow(uint256 _escrowId) external payable nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(!escrow.isActive, "Escrow already active");
        require(block.timestamp < escrow.expiryDate, "Escrow expired");
        require(
            msg.sender == escrow.receiver,
            "Only specified receiver can accept"
        );

        uint256 collateralAmount = (escrow.amount *
            COLLATERAL_PERCENTAGE_BASIS_POINTS) / BASIS_POINTS_DENOMINATOR;

        if (escrow.isEth) {
            require(
                msg.value == collateralAmount,
                "Incorrect collateral amount"
            );
        } else {
            IERC20(escrow.token).safeTransferFrom(
                msg.sender,
                address(this),
                collateralAmount
            );
        }

        escrow.isActive = true;
        emit EscrowAccepted(_escrowId, msg.sender);
    }

    /**
     * @notice Allows the receiver to request release of escrowed funds
     * @dev Must be called before depositor can approve release
     * @param _escrowId The ID of the escrow
     */
    function requestRelease(uint256 _escrowId) external nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(!escrow.isCompleted, "Escrow already completed");
        require(escrow.isActive, "Escrow not active");
        require(
            msg.sender == escrow.receiver,
            "Only receiver can request release"
        );
        require(!escrow.releaseRequested, "Release already requested");

        escrow.releaseRequested = true;
        emit ReleaseRequested(_escrowId);
    }

    /**
     * @notice Allows the depositor to approve release of funds to receiver
     * @dev Transfers both escrowed amount and collateral to receiver
     * @param _escrowId The ID of the escrow
     */
    function approveRelease(uint256 _escrowId) external nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.isActive, "Escrow not active");
        require(!escrow.isCompleted, "Escrow already completed");
        require(
            msg.sender == escrow.depositor,
            "Only depositor can approve release"
        );
        require(escrow.releaseRequested, "Release not requested");

        uint256 adminFee = (escrow.amount * ADMIN_FEE_BASIS_POINTS) /
            BASIS_POINTS_DENOMINATOR;
        uint256 collateralAmount = (escrow.amount *
            COLLATERAL_PERCENTAGE_BASIS_POINTS) / BASIS_POINTS_DENOMINATOR;
        uint256 totalToReceiver = escrow.amount + collateralAmount;

        if (escrow.isEth) {
            accruedFeesETH += adminFee;
            payable(escrow.receiver).transfer(totalToReceiver);
        } else {
            accruedFeesERC20[escrow.token] += adminFee;
            IERC20(escrow.token).safeTransfer(escrow.receiver, totalToReceiver);
        }

        // Update escrow state
        escrow.isActive = false;
        escrow.isCompleted = true;

        emit EscrowCompleted(_escrowId, escrow.receiver, totalToReceiver);
    }

    /**
     * @notice Allows depositor to reclaim funds from an expired escrow
     * @dev Can only be called after expiry and if escrow wasn't accepted
     * @param _escrowId The ID of the escrow
     */
    function refundExpiredEscrow(uint256 _escrowId) external nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(
            !escrow.isActive && !escrow.isCompleted,
            "Escrow is active or completed"
        );
        require(msg.sender == escrow.depositor, "Only depositor can refund");
        require(block.timestamp >= escrow.expiryDate, "Escrow not expired");
        require(!escrow.releaseRequested, "Escrow was previously accepted");

        uint256 adminFee = (escrow.amount * ADMIN_FEE_BASIS_POINTS) /
            BASIS_POINTS_DENOMINATOR;
        uint256 totalRefund = escrow.amount + adminFee;

        if (escrow.isEth) {
            payable(escrow.depositor).transfer(totalRefund);
        } else {
            IERC20(escrow.token).safeTransfer(escrow.depositor, totalRefund);
        }

        escrow.isCompleted = true;
        emit EscrowRefunded(_escrowId, escrow.depositor);
    }

    /**
     * @notice Allows owner to withdraw accumulated fees
     * @dev Separate withdrawal for ETH and each ERC20 token
     * @param _token The token address (address(0) for ETH)
     */
    function withdrawFees(address _token) external onlyOwner {
        if (_token == address(0)) {
            require(accruedFeesETH > 0, "No ETH fees to withdraw");
            uint256 amount = accruedFeesETH;
            accruedFeesETH = 0;
            payable(owner()).transfer(amount);
            emit FeesWithdrawn(address(0), amount);
        } else {
            uint256 amount = accruedFeesERC20[_token];
            require(amount > 0, "No token fees to withdraw");
            accruedFeesERC20[_token] = 0;
            IERC20(_token).safeTransfer(owner(), amount);
            emit FeesWithdrawn(_token, amount);
        }
    }

    function escrowDetails(
        uint256 _escrowId
    )
        public
        view
        returns (
            address _depositor,
            address _receiver,
            address _token,
            uint256 _amount,
            uint256 _expiryDate,
            uint256 _createdAt,
            bool _isActive,
            bool _isCompleted,
            bool _isEth,
            bool _releaseRequested,
            string memory _title,
            string memory _description
        )
    {
        Escrow memory escrow = escrows[_escrowId];
        return (
            escrow.depositor,
            escrow.receiver,
            escrow.token,
            escrow.amount,
            escrow.expiryDate,
            escrow.createdAt,
            escrow.isActive,
            escrow.isCompleted,
            escrow.isEth,
            escrow.releaseRequested,
            escrow.title,
            escrow.description
        );
    }

    function getEscrowDepositor(
        uint256 _escrowId
    ) public view returns (address) {
        return escrows[_escrowId].depositor;
    }

    /**
     * @notice Allows contract to receive ETH
     * @dev Required for escrow operations involving ETH
     */
    receive() external payable {}
}
