# trustlock

A milestone-based escrow smart contract on the Sui blockchain, written in Move. Designed for trustless peer-to-peer agreements with built-in dispute arbitration.

---

## What It Does

Two parties — a buyer and a seller — can lock funds into a shared contract and release them incrementally as work is delivered. If either party raises a dispute, a pre-agreed arbitrator steps in to split the remaining funds. No third party can access funds outside of these defined rules.

```
Buyer locks funds → Seller accepts → Milestones completed → Funds released
                                           ↓
                                    Dispute raised
                                           ↓
                                  Arbitrator resolves
```

---

## Features

- **Milestone-based payments** — funds are split across defined milestones; the buyer releases each one independently
- **Dispute arbitration** — either party can raise a dispute; a neutral arbitrator decides the split
- **Timeout protection** — if the arbitrator is unresponsive after 7 days, funds auto-split 50/50
- **Cancellation** — buyer can cancel and recover funds if the seller never accepts
- **Fully on-chain** — no off-chain components, no admin keys, no upgradeable proxies

---

## Contract Architecture

### States

| State | Description |
|---|---|
| `CREATED` | Buyer has locked funds, awaiting seller acceptance |
| `ACTIVE` | Seller accepted, work is in progress |
| `DISPUTED` | One party raised a dispute, arbitrator must act |
| `COMPLETED` | All milestones released or dispute resolved |
| `CANCELLED` | Buyer cancelled before seller accepted |

### Actors

| Actor | Role |
|---|---|
| Buyer | Creates escrow, locks funds, approves milestones, can raise dispute |
| Seller | Accepts escrow, claims released milestones, can raise dispute |
| Arbitrator | Neutral address set at creation; resolves disputes with a custom split |

### Core Functions

| Function | Caller | Description |
|---|---|---|
| `create_escrow` | Buyer | Locks funds, defines milestones, sets arbitrator address |
| `accept_escrow` | Seller | Accepts terms, moves contract to ACTIVE |
| `release_milestone` | Buyer | Approves a single milestone, transfers funds to seller |
| `raise_dispute` | Buyer or Seller | Flags a problem, freezes further milestone releases |
| `resolve_dispute` | Arbitrator | Splits remaining funds with a custom buyer/seller percentage |
| `cancel_escrow` | Buyer | Cancels before seller accepts, returns full amount to buyer |
| `claim_timeout` | Anyone | Triggers 50/50 split if arbitrator is inactive past deadline |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Smart contract | Move (Sui dialect) |
| Blockchain | Sui Testnet |
| Token | Native SUI |
| Frontend | React + `@mysten/dapp-kit` |
| Wallet | Sui Wallet Standard (Slush, Sui Wallet, Suiet) |

---

## Project Structure

```
trustlock/
├── Move.toml
├── sources/
│   └── escrow.move       ← core contract
├── tests/
│   └── escrow_tests.move ← unit tests
└── frontend/
    ├── src/
    │   ├── App.tsx
    │   ├── components/
    │   │   ├── CreateEscrow.tsx
    │   │   ├── MilestoneList.tsx
    │   │   └── DisputePanel.tsx
    │   └── hooks/
    │       └── useEscrow.ts
    └── package.json
```

---

## Getting Started

### Prerequisites

- [Rust](https://rustup.rs/)
- [Sui CLI](https://docs.sui.io/guides/developer/getting-started/sui-install)
- [Node.js](https://nodejs.org/) v18+

### Install Sui CLI

```bash
cargo install --locked --git https://github.com/MystenLabs/sui.git --branch testnet sui
```

### Configure Testnet

```bash
sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443
sui client switch --env testnet
sui client faucet
```

### Build & Test

```bash
sui move build
sui move test
```

### Deploy

```bash
sui client publish --gas-budget 100000000
```

Save the `Package ID` from the output — you'll need it to call functions.

---

## Usage Example (CLI)

```bash
# Create escrow with 3 milestones (amounts in MIST, 1 SUI = 1,000,000,000 MIST)
sui client call \
  --package <PACKAGE_ID> \
  --module escrow \
  --function create_escrow \
  --args <SELLER_ADDRESS> <ARBITRATOR_ADDRESS> "[100000000, 100000000, 100000000]" \
  --gas-budget 10000000

# Release milestone 0
sui client call \
  --package <PACKAGE_ID> \
  --module escrow \
  --function release_milestone \
  --args <ESCROW_ID> 0 \
  --gas-budget 10000000
```

---

## Design Decisions

**Why Sui Move over Solidity?**
Sui's object-ownership model is a fundamentally different paradigm — funds are stored as actual `Coin<SUI>` objects inside the escrow, not as a balance in a mapping. This means the compiler physically prevents double-spend scenarios at the language level.

**Why a single arbitrator?**
Multi-arbitrator voting adds coordination complexity without proportional security gain at this contract size. The arbitrator address is set at creation time and visible to both parties before they commit.

**Known extensions (not implemented)**
- Custom ERC20/fungible token support beyond native SUI
- Multi-arbitrator quorum voting
- On-chain milestone descriptions (currently tracked off-chain to minimise gas)
- DAO governance over arbitrator selection

---

## Authors

Built by [Mike](https://github.com/Laximas) as part of an ongoing blockchain development portfolio.

Previous project: [solidity-voting](https://github.com/KatGkar/solidity-voting) — an on-chain voting contract in Solidity.

---

## License

MIT