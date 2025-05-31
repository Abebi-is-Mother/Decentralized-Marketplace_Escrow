# Decentralized Marketplace Escrow

A secure escrow smart contract for peer-to-peer marketplace transactions on the Stacks blockchain.

## Features

- **Secure Escrow**: Funds are held in contract until transaction completion
- **Dispute Resolution**: Built-in dispute mechanism with admin resolution
- **Order Tracking**: Complete order lifecycle management
- **STX Integration**: Native STX token support for payments

## Contract Functions

### Public Functions

- `create-order(seller, amount)` - Create new escrow order
- `complete-order(order-id)` - Complete order and release funds
- `dispute-order(order-id, reason)` - Dispute an order
- `resolve-dispute(order-id, winner)` - Admin function to resolve disputes

### Read-Only Functions

- `get-order(order-id)` - Get order details
- `get-dispute(order-id)` - Get dispute information
- `get-next-order-id()` - Get next available order ID

## Usage

1. Buyer creates order with seller address and amount
2. Funds are escrowed in the contract
3. Buyer completes order to release funds to seller
4. Either party can dispute if issues arise

## Security

- Owner-only dispute resolution
- Proper authorization checks
- Safe STX transfer handling