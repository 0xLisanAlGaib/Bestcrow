# Bestcrow

A decentralized escrow smart contract for secure peer-to-peer transactions using ETH and ERC20 tokens.

## Overview

Bestcrow is a trustless escrow service that facilitates secure transactions between two parties (depositor and receiver) with built-in collateral requirements and time-based expiration. It supports both ETH and ERC20 tokens.


### Sepolia

| Version  | Address | Network |
| -------- | ------- | ------- |
| 0.1      | 0x34fde614F47C61E355cCf9680FD549fFAb1cbC0f    | Sepolia
| 0.1      | 0x3d6e4b427867ee08F6a2995d50de4c8D86fAA595    | Holesky
| 0.2      | 0x8c2acF6Fb82305f19fbB3F60a53810b17df9BC9B    | Holesky
| 0.3      | 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A    | Holesky
| 0.4      | 0x77C385fD50164Fde71A6c29732F9F7763AAC6753    | Holesky
| 0.5      | 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6    | Holesky


## Features

- **Dual Asset Support**: Handle both ETH and ERC20 token transactions
- **Collateral System**: Requires 50% collateral from receivers to ensure commitment
- **Time-Based Expiration**: Automatic refund mechanism after expiry if not accepted
- **Two-Step Release**: Requires receiver request and depositor approval for added security
- **Fee System**: 0.5% administrative fee on transactions
- **Security**: Built with OpenZeppelin's secure components including:
  - ReentrancyGuard for protection against reentrancy attacks
  - SafeERC20 for safe token transfers
  - Ownable for controlled fee withdrawal

## How It Works

1. **Creating an Escrow**
   - Depositor creates an escrow by specifying:
     - Token address (or address(0) for ETH)
     - Amount
     - Expiry date
     - Receiver's address
   - Depositor sends funds + 0.5% fee

2. **Accepting an Escrow**
   - Receiver must accept by providing 50% collateral
   - Must be done before expiry date

3. **Rejecting an Escrow**
   - Receiver can reject an escrow before expiry date
   - If rejected, depositor can reclaim funds

4. **Completing the Transaction**
   - Receiver requests release of funds
   - Depositor approves the release
   - Both original amount and collateral are sent to receiver

4. **Expiration/Refund**
   - If receiver never accepts, depositor can reclaim funds after expiry
   - Includes refund of administrative fee

## Contract Functions

- `createEscrow`: Create a new escrow agreement
- `acceptEscrow`: Accept and collateralize an escrow
- `rejectEscrow`: Reject an escrow before expiry
- `requestRelease`: Request release of escrowed funds
- `approveRelease`: Approve and execute fund release
- `refundExpiredEscrow`: Reclaim funds from expired escrows
- `withdrawFees`: Admin function to withdraw collected fees

## Security

- Contact: 0xlisanalgaib@gmail.com
- Built with Solidity 0.8.24
- Implements reentrancy protection
- Uses safe transfer methods for tokens

## License

MIT License
