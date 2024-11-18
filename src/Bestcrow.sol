// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Bestcrow is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant ADMIN_FEE_BASIS_POINTS = 50; // 0.5%
    uint256 public constant BASIS_POINTS_DENOMINATOR = 10000;
    uint256 public constant COLLATERAL_PERCENTAGE = 50; // 50%

    uint256 public accruedFeesETH;
    mapping(address => uint256) public accruedFeesERC20;

    struct Escrow {
        address depositor;
        address receiver;
        address token;
        uint256 amount;
        uint256 expiryDate;
        bool isActive;
        bool isCompleted;
        bool isEth;
        bool releaseRequested;
    }

    uint256 public nextEscrowId;
    mapping(uint256 => Escrow) public escrows;

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

    constructor() Ownable(msg.sender) {}

    function createEscrow(
        address _token,
        uint256 _amount,
        uint256 _expiryDate,
        address _receiver
    ) external payable returns (uint256) {
        require(_amount > 0, "Invalid amount");
        require(_receiver != address(0), "Invalid receiver");
        require(_receiver != msg.sender, "Receiver cannot be depositor");
        require(_expiryDate > block.timestamp, "Invalid expiry date");

        uint256 adminFee = (_amount * ADMIN_FEE_BASIS_POINTS) / BASIS_POINTS_DENOMINATOR;
        bool isEth = _token == address(0);
        
        if (isEth) {
            require(msg.value == _amount + adminFee, "Incorrect ETH amount");
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount + adminFee);
        }

        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = Escrow({
            depositor: msg.sender,
            receiver: _receiver,
            token: _token,
            amount: _amount,
            expiryDate: _expiryDate,
            isActive: false,
            isCompleted: false,
            isEth: isEth,
            releaseRequested: false
        });

        emit EscrowCreated(escrowId, msg.sender, _receiver, _token, _amount, _expiryDate);
        return escrowId;
    }

    function acceptEscrow(uint256 _escrowId) external payable nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(!escrow.isActive, "Escrow already active");
        require(block.timestamp < escrow.expiryDate, "Escrow expired");
        require(msg.sender == escrow.receiver, "Only specified receiver can accept");

        uint256 collateralAmount = escrow.amount * COLLATERAL_PERCENTAGE / 100;

        if (escrow.isEth) {
            require(msg.value == collateralAmount, "Incorrect collateral amount");
        } else {
            IERC20(escrow.token).safeTransferFrom(msg.sender, address(this), collateralAmount);
        }

        escrow.isActive = true;
        emit EscrowAccepted(_escrowId, msg.sender);
    }

    function requestRelease(uint256 _escrowId) external nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.isActive, "Escrow not active");
        require(!escrow.isCompleted, "Escrow already completed");
        require(msg.sender == escrow.receiver, "Only receiver can request release");
        require(!escrow.releaseRequested, "Release already requested");

        escrow.releaseRequested = true;
        emit ReleaseRequested(_escrowId);
    }

    function approveRelease(uint256 _escrowId) external nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.isActive, "Escrow not active");
        require(!escrow.isCompleted, "Escrow already completed");
        require(msg.sender == escrow.depositor, "Only depositor can approve release");
        require(escrow.releaseRequested, "Release not requested");

        uint256 adminFee = (escrow.amount * ADMIN_FEE_BASIS_POINTS) / BASIS_POINTS_DENOMINATOR;
        uint256 collateralAmount = escrow.amount * COLLATERAL_PERCENTAGE / 100;
        uint256 totalToReceiver = escrow.amount + collateralAmount;

        if (escrow.isEth) {
            accruedFeesETH += adminFee;
            payable(escrow.receiver).transfer(totalToReceiver);
        } else {
            accruedFeesERC20[escrow.token] += adminFee;
            IERC20(escrow.token).safeTransfer(escrow.receiver, totalToReceiver);
        }

        escrow.isCompleted = true;
        escrow.isActive = false;
        emit EscrowCompleted(_escrowId, escrow.receiver, totalToReceiver);
    }

    function refundExpiredEscrow(uint256 _escrowId) external nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(!escrow.isActive, "Escrow is active");
        require(!escrow.isCompleted, "Escrow already completed");
        require(msg.sender == escrow.depositor, "Only depositor can refund");
        require(block.timestamp >= escrow.expiryDate, "Escrow not expired");

        uint256 adminFee = (escrow.amount * ADMIN_FEE_BASIS_POINTS) / BASIS_POINTS_DENOMINATOR;
        uint256 totalRefund = escrow.amount + adminFee;

        if (escrow.isEth) {
            payable(escrow.depositor).transfer(totalRefund);
        } else {
            IERC20(escrow.token).safeTransfer(escrow.depositor, totalRefund);
        }

        escrow.isCompleted = true;
        emit EscrowRefunded(_escrowId, escrow.depositor);
    }

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

    receive() external payable {}
}
