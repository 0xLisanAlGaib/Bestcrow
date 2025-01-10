# Bestcrow 🔒

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.24-blue.svg)](https://soliditylang.org/)

A secure, decentralized escrow protocol for trustless peer-to-peer transactions supporting ETH and ERC20 tokens on multiple networks. Built with OpenZeppelin's secure components, it ensures safe and transparent transactions with built-in collateral requirements.

<div align="center">

[Features](#features) •
[Quick Start](#quick-start) •
[How It Works](#how-it-works) •
[Security](#security) •
[Documentation](#documentation) •
[Contributing](#contributing)

</div>

## 📜 Overview

Bestcrow is a trustless escrow service that revolutionizes secure transactions between two parties (depositor and receiver). Each escrow agreement includes:

- A title and detailed description of the agreement
- Customizable expiry date for time-bound transactions
- 50% collateral requirement from receivers
- 0.5% administrative fee (refundable if escrow expires or is rejected)
- Support for both ETH and any ERC20 token

### 🌐 Deployed Contracts

| Version | Network  | Address | Explorer  |
| ------- | -------- | ------- | ---------------------------------------------------------- |
| 1.0     | Arbitrum | 0x718D184786561e6D12a7fe66aD71504Ce90aEee3 | [View on Arbiscan](https://arbiscan.io/address/0x718D184786561e6D12a7fe66aD71504Ce90aEee3#code)    |
| 0.2     | Holesky  | 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 | [View on Holesky](https://holesky.etherscan.io/address/0x7ebd1370491e6f546841bd02ed0772a0c4dac3b6) |
| 0.1     | Sepolia  | 0x34fde614F47C61E355cCf9680FD549fFAb1cbC0f | [View on Sepolia](https://sepolia.etherscan.io/address/0x34fde614F47C61E355cCf9680FD549fFAb1cbC0f) |

## ⭐ Features

### Core Features

- **Multi-Asset Support**:
  - Native ETH transactions with automatic value handling
  - Any ERC20 token support via SafeERC20
  - Separate fee tracking for ETH and each ERC20 token
- **Advanced Security**:
  - Collateral-backed transactions (50% requirement)
  - Time-based expiration system with automatic refund capability
  - Two-step release mechanism (request + approval)
  - Reentrancy protection via OpenZeppelin's ReentrancyGuard
  - Secure token transfers using SafeERC20

### Additional Benefits

- **Transparent Fee Structure**:
  - Only 0.5% administrative fee (50 basis points)
  - Fee automatically calculated and collected
  - Fee refunded if escrow expires or is rejected
  - Separate fee tracking for ETH and ERC20 tokens
- **Flexible Control**:
  - Receiver rejection capability before expiry
  - Automatic refund system for expired escrows
  - Customizable expiry dates for each agreement
  - Detailed agreement descriptions and titles
- **Built for Scale**:
  - Gas-optimized operations with minimal storage
  - Multi-network deployment support
  - Professional audit-ready code with full documentation
  - Event emission for all major state changes

## 🚀 Quick Start

### Creating an Escrow

```solidity
function createEscrow(
    address token,    // Use address(0) for ETH
    uint256 amount,   // Amount to escrow
    uint256 expiryDate,   // Timestamp for expiration
    address receiver,  // Recipient address
    string memory title,  // Title of the agreement
    string memory description  // Detailed description
) external payable returns (uint256 escrowId)
```

### Accepting an Escrow

```solidity
function acceptEscrow(
    uint256 escrowId  // ID of the escrow to accept
) external payable
```

## 🔄 How It Works

### 1. Escrow Creation

- Depositor initiates by providing:
  - Asset type (ETH or ERC20 token address)
  - Transaction amount
  - Expiration timestamp
  - Receiver's address
  - Title and description of the agreement
- System requirements:
  - Amount must be greater than 0
  - Receiver cannot be the zero address or depositor
  - Expiry date must be in the future
  - Title cannot be empty
  - Depositor transfers full amount + 0.5% fee

### 2. Receiver Acceptance

- Requirements:
  - Must be the specified receiver
  - Must accept before expiry date
  - Must provide exactly 50% collateral
  - Cannot accept if already active
- Process:
  - Transfers collateral to contract
  - Marks escrow as active
  - Emits EscrowAccepted event

### 3. Transaction Flow

- **Standard Flow**:
  1. Receiver requests release via `requestRelease`
  2. Depositor approves via `approveRelease`
  3. Contract transfers:
     - Original amount to receiver
     - Collateral returned to receiver
     - Fee stored in contract
- **Alternative Flows**:
  - **Rejection**: Receiver can reject before accepting, full refund to depositor
  - **Expiration**: Depositor can claim refund after expiry if not accepted
  - **Fee Management**: Owner can withdraw accumulated fees per token

## 🔒 Security

### Security Measures

- **Smart Contract Security**:
  - OpenZeppelin's secure components:
    - ReentrancyGuard for all value transfers
    - SafeERC20 for token operations
    - Ownable for fee management
  - Strict input validation
  - State machine pattern for escrow lifecycle
  - Event emission for all state changes


## 📖 Documentation

### Core Functions

| Function              | Description                 | Access    | Requirements                      |
| --------------------- | --------------------------- | --------- | --------------------------------- |
| `createEscrow`        | Create new escrow agreement | Public    | Approval for amount + fee         |
| `acceptEscrow`        | Accept and collateralize    | Receiver  | Approval for 50% collateral       |
| `rejectEscrow`        | Reject before expiry        | Receiver  | Before expiry, not active         |
| `requestRelease`      | Request funds release       | Receiver  | Active escrow                     |
| `approveRelease`      | Approve and execute release | Depositor | After request                     |
| `refundExpiredEscrow` | Reclaim expired funds       | Depositor | After expiry, not active          |
| `withdrawFees`        | Withdraw admin fees         | Owner     | Accumulated fees > 0              |

### Events

```solidity
event EscrowCreated(
    uint256 indexed escrowId,
    address indexed depositor,
    address indexed receiver,
    address token,
    uint256 amount,
    uint256 expiryDate,
    uint256 createdAt,
    string title,
    string description
);
event EscrowAccepted(uint256 indexed escrowId, address indexed receiver);
event EscrowRejected(uint256 indexed escrowId, address indexed receiver);
event ReleaseRequested(uint256 indexed escrowId);
event EscrowCompleted(uint256 indexed escrowId, address indexed receiver, uint256 amount);
event EscrowRefunded(uint256 indexed escrowId, address indexed depositor);
event FeesWithdrawn(address token, uint256 amount);
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Built with ❤️ by 0xLisanAlGaib

[Website](https://bestcrow.vercel.app/) •
[Twitter](https://twitter.com/0xLisanAlGaib) •
[Medium](https://medium.com/@0xlisanalgaib/bestcrow-a-decentralized-escrow-5baeed283505)

</div>
