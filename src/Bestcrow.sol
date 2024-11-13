// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Bestcrow is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Escrow {
        address depositor;
        address receiver;
        address token;
        uint256 amount;
        uint256 milestones;
        uint256 completedMilestones;
        uint256 expiryDate;
        bool isActive;
        bool isEth;
    }

    uint256 public nextEscrowId;
    mapping(uint256 => Escrow) public escrows;

    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed depositor,
        address token,
        uint256 amount,
        uint256 milestones,
        uint256 expiryDate
    );
    
    event EscrowAccepted(uint256 indexed escrowId, address indexed receiver);
    event MilestoneCompleted(uint256 indexed escrowId, uint256 milestone);
    event PaymentReleased(uint256 indexed escrowId, uint256 amount);
    event CollateralReturned(uint256 indexed escrowId, address indexed receiver);

    function createEscrow(
        address _token,
        uint256 _amount,
        uint256 _milestones,
        uint256 _daysToExpiry
    ) external payable returns (uint256) {
        require(_milestones > 0, "Invalid milestone count");
        require(_amount > 0, "Invalid amount");
        
        bool isEth = _token == address(0);
        if (isEth) {
            require(msg.value == _amount, "Incorrect ETH amount");
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = Escrow({
            depositor: msg.sender,
            receiver: address(0),
            token: _token,
            amount: _amount,
            milestones: _milestones,
            completedMilestones: 0,
            expiryDate: block.timestamp + (_daysToExpiry * 1 days),
            isActive: true,
            isEth: isEth
        });

        emit EscrowCreated(
            escrowId,
            msg.sender,
            _token,
            _amount,
            _milestones,
            block.timestamp + (_daysToExpiry * 1 days)
        );

        return escrowId;
    }

    function acceptEscrow(uint256 _escrowId) external payable nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.isActive, "Escrow not active");
        require(block.timestamp < escrow.expiryDate, "Escrow expired");
        require(escrow.receiver == address(0), "Escrow already accepted");
        require(msg.sender != escrow.depositor, "Depositor cannot be receiver");

        if (escrow.isEth) {
            require(msg.value == escrow.amount, "Incorrect collateral amount");
        } else {
            IERC20(escrow.token).safeTransferFrom(msg.sender, address(this), escrow.amount);
        }

        escrow.receiver = msg.sender;
        emit EscrowAccepted(_escrowId, msg.sender);
    }

    function requestMilestoneCompletion(uint256 _escrowId) external nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.isActive, "Escrow not active");
        require(msg.sender == escrow.receiver, "Only receiver can request");
        require(escrow.completedMilestones < escrow.milestones, "All milestones completed");

        uint256 paymentAmount = escrow.amount / escrow.milestones;
        escrow.completedMilestones++;

        if (escrow.isEth) {
            payable(escrow.receiver).transfer(paymentAmount);
        } else {
            IERC20(escrow.token).safeTransfer(escrow.receiver, paymentAmount);
        }

        emit MilestoneCompleted(_escrowId, escrow.completedMilestones);
        emit PaymentReleased(_escrowId, paymentAmount);

        // Return collateral if this was the final milestone
        if (escrow.completedMilestones == escrow.milestones) {
            if (escrow.isEth) {
                payable(escrow.receiver).transfer(escrow.amount);
            } else {
                IERC20(escrow.token).safeTransfer(escrow.receiver, escrow.amount);
            }
            escrow.isActive = false;
            emit CollateralReturned(_escrowId, escrow.receiver);
        }
    }

    function refundExpiredEscrow(uint256 _escrowId) external nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.isActive, "Escrow not active");
        require(block.timestamp >= escrow.expiryDate, "Escrow not expired");
        
        if (escrow.receiver == address(0)) {
            // No receiver joined, return funds to depositor
            if (escrow.isEth) {
                payable(escrow.depositor).transfer(escrow.amount);
            } else {
                IERC20(escrow.token).safeTransfer(escrow.depositor, escrow.amount);
            }
        } else {
            // Return both deposit and collateral
            if (escrow.isEth) {
                payable(escrow.depositor).transfer(escrow.amount);
                payable(escrow.receiver).transfer(escrow.amount);
            } else {
                IERC20(escrow.token).safeTransfer(escrow.depositor, escrow.amount);
                IERC20(escrow.token).safeTransfer(escrow.receiver, escrow.amount);
            }
        }
        
        escrow.isActive = false;
    }

    // Add this at the end of the contract
    receive() external payable {}
}
