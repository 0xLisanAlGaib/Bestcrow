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
}
