# Liquity V2 Codebase Architecture

A comprehensive overview of the Liquity V2 (Bold) monorepo - a multi-collateral stablecoin system built on Ethereum.

## Table of Contents

1. [Monorepo Structure](#monorepo-structure)
2. [Smart Contracts Architecture](#smart-contracts-architecture)
3. [Frontend Architecture](#frontend-architecture)
4. [Subgraph Architecture](#subgraph-architecture)
5. [Build and Development Commands](#build-and-development-commands)
6. [Development Setup](#development-setup)

---

## Monorepo Structure

This is a **pnpm monorepo** with the following workspaces:

```
liquity-v2-bold/
├── contracts/                 # Smart contracts (Solidity)
├── frontend/
│   ├── app/                  # Next.js main application
│   ├── uikit/                # UI component library (PandaCSS)
│   └── uikit-gallery/        # Component showcase
├── subgraph/                 # TheGraph indexing (GraphQL)
├── package.json              # Root pnpm config
├── pnpm-workspace.yaml       # Workspace definitions
├── README.md                 # Main documentation
└── INSTRUCTIONS.md           # Setup & deployment guide
```

**Package Manager:** pnpm 8.15.8+ (required)

---

## Smart Contracts Architecture

Location: `/contracts/src/`

### Core System Architecture

Liquity V2 implements a **multi-collateral stablecoin protocol** supporting up to 10 different collateral types. The system is branch-based, with a separate TroveManager per collateral.

#### Top-Level Contracts (Entry Points)

**CollateralRegistry** (`CollateralRegistry.sol`)
- Central registry managing all collateral branches
- Stores references to tokens, TroveManagers, and pricing
- Manages global baseRate and fee operations
- Coordinates redemptions across multiple collaterals
- Max 10 collaterals per deployment

**BorrowerOperations** (`BorrowerOperations.sol`) - Per Collateral
- Entry point for borrowers to open/adjust/close troves
- Validates collateral ratios (ICR, MCR, CCR, SCR, BCR)
- Manages trove delegation and batch interest management
- Handles interest rate delegates and batch managers
- Applies interest calculations and fee operations

**TroveManager** (`TroveManager.sol`) - Per Collateral
- Core state machine for individual troves
- Manages trove liquidation logic
- Handles redistributions and stability pool offsets
- Tracks interest rates per collateral branch
- Maintains sorted list of troves

#### Collateral Pools & State Contracts

**StabilityPool** (`StabilityPool.sol`)
- Holds BOLD deposits from Stability Pool providers
- Distributes collateral gains to depositors from liquidations
- Implements scalable reward distribution (Product-Sum algorithm)
- Provides the primary liquidation mechanism
- Mints compounding yield (YBOLD)

**ActivePool** (`ActivePool.sol`)
- Stores collateral from active troves
- Manages total collateral across the system
- Tracks gains from liquidations

**DefaultPool** (`DefaultPool.sol`)
- Holds collateral from redistributed troves
- Fallback when stability pool is insufficient

**CollSurplusPool** (`CollSurplusPool.sol`)
- Stores collateral surpluses from liquidations
- Allows borrowers to claim excess collateral after liquidation

#### Token Contracts

**BoldToken** (`BoldToken.sol`)
- ERC20 token representing the BOLD stablecoin
- Minted by TroveManager when borrowers open positions
- Burned when borrowers repay or when liquidations occur
- Includes permit() for gasless approvals

**TroveNFT** (`TroveNFT.sol`)
- ERC721 token representing ownership of a Trove
- One NFT per trove ID
- Transferred when trove ownership changes

#### Helper & View Contracts

**SortedTroves** (`SortedTroves.sol`)
- Doubly-linked list of troves
- Sorted by collateral ratio (ICR) for efficient liquidation ordering
- Enables O(log n) lookups and insertions

**HintHelpers** (`HintHelpers.sol`)
- Generates hints for efficient list navigation
- Calculates approximate trove positions

**MultiTroveGetter** (`MultiTroveGetter.sol`)
- Batch query interface for multiple troves
- Used by frontend for efficient data fetching

**DebtInFrontHelper** (`DebtInFrontHelper.sol`)
- Calculates debt ahead in the redemption queue

**GasPool** (`GasPool.sol`)
- Holds ETH for liquidation gas compensation
- Simple balance tracking contract

#### Price Feeds & Oracles

Location: `/contracts/src/PriceFeeds/`

**CompositePriceFeed** (`CompositePriceFeed.sol`)
- Aggregates multiple oracle sources
- Primary/fallback oracle configuration
- Returns worst price (conservative for borrower protection)

**MainnetPriceFeedBase** (`MainnetPriceFeedBase.sol`)
- Base class for Mainnet oracle implementations
- Chainlink integration framework
- Price staleness checks

**WETHPriceFeed, WSTETHPriceFeed, RETHPriceFeed** (`*.sol`)
- Specific implementations for major LST/wrapped tokens
- Custom logic for exchange rate calculations
- Fallback mechanisms

#### Zapper Contracts

Location: `/contracts/src/Zappers/`

**WETHZapper** (`WETHZapper.sol`)
- Converts native ETH to WETH and opens trove in one tx

**LeverageWETHZapper** (`LeverageWETHZapper.sol`)
- Enables leverage trading with WETH collateral
- Flash loan integration for leverage

**LeverageLSTZapper** (`LeverageLSTZapper.sol`)
- Leverage support for Liquid Staking Token collaterals
- Handles LST-specific logic

**GasCompZapper** (`GasCompZapper.sol`)
- Gas compensation handling for liquidations

#### Types & Dependencies

Location: `/contracts/src/Types/` and `/contracts/src/Dependencies/`

**Key Types:**
- `TroveId.sol` - Unique identifier for troves (uint256)
- `LatestTroveData.sol` - Cached trove state struct
- `LatestBatchData.sol` - Interest batch metadata
- `TroveChange.sol` - Parameters for trove modifications
- `BatchId.sol` - Batch manager identifiers

**Core Dependencies:**
- `LiquityBase.sol` - Base contract with shared constants
- `LiquityMath.sol` - Mathematical utilities (MCR calculations, etc.)
- `AddRemoveManagers.sol` - Delegation management logic
- `Constants.sol` - Protocol parameters and constants
- `Ownable.sol` - Simple ownership model

### Key Contract Interfaces

Location: `/contracts/src/Interfaces/`

Main interfaces (read for API contracts):
- `IBorrowerOperations.sol` - Borrowing operations
- `ITroveManager.sol` - Trove management and liquidation
- `IStabilityPool.sol` - Stability pool interface
- `ICollateralRegistry.sol` - Collateral registry
- `IBoldToken.sol` - Token interface
- `IActivePool.sol`, `IDefaultPool.sol`, `ICollSurplusPool.sol`
- `ISortedTroves.sol` - Sorted list interface
- `IHintHelpers.sol` - Hint generation
- `IPriceFeed.sol` - Generic price feed interface

### Core System Design Patterns

1. **Multi-Collateral with Branches**
   - Each collateral has its own TroveManager
   - Separate interest rates per collateral
   - CollateralRegistry coordinates across branches

2. **Interest Rate System**
   - Individual trove interest rates (configurable by borrower)
   - Batch managers can set rates for groups of troves
   - Recorded debt tracks actual debt with interest applied
   - Base rate updated on redemptions and new borrowing

3. **Liquidation Mechanics**
   - Stability Pool offset (preferred)
   - Redistribution (if SP insufficient)
   - Requires 110% MCR minimum
   - CCR (120%) triggers restriction, SCR (150%) triggers shutdown

4. **Redemption System**
   - Allows BOLD holders to redeem collateral
   - Routes through collaterals to minimize losses
   - Progressive fee schedule (increases with amount redeemed)
   - Base rate increases after redemptions

5. **Trove Hints & Sorting**
   - Troves sorted by ICR in SortedTroves
   - Hints reduce gas by O(log n) vs O(n)
   - Essential for efficient liquidations

### Deployment Scripts

Location: `/contracts/script/`

**Key scripts:**
- `DeployLiquity2.s.sol` - Full system deployment (all components)
- `DeployGovernance.s.sol` - Governance token setup
- `OpenTroves.s.sol` - Test data generation
- `DeployOnlyExchangeHelpers.s.sol` - Exchange integrations

### Testing

Location: `/contracts/test/` and `/contracts/test-js/`

- **Foundry tests** (Solidity) - Core contract logic
- **Hardhat tests** (JavaScript/TypeScript) - Integration tests
- **Coverage:** `pnpm coverage` - Solidity coverage reports

---

## Frontend Architecture

Location: `/frontend/app/`

### Technology Stack

- **Framework:** Next.js 15 (React 19)
- **Styling:** PandaCSS (CSS-in-JS with type safety)
- **Web3 Integration:** Wagmi + Viem (modern Web3 library)
- **State Management:** React Query (TanStack Query) + React Context
- **Type Safety:** TypeScript + Zod validation
- **GraphQL:** GraphQL Code Generator for type-safe queries
- **Animation:** React Spring
- **Component Library:** Custom uikit built with PandaCSS

### Directory Structure

```
frontend/app/src/
├── app/                      # Next.js app router structure
│   ├── account/             # User portfolio & positions
│   ├── borrow/              # Borrowing interface
│   │   └── [collateral]/    # Per-collateral view
│   ├── earn/                # Stability Pool earning
│   ├── loan/                # Trove management
│   ├── multiply/            # Leverage trading
│   ├── redeem/              # BOLD redemption
│   ├── stake/               # LQTY staking
│   ├── legacy/              # Liquity V1 integration
│   └── transactions/        # Tx history
│
├── screens/                 # Screen-level components
│   ├── HomeScreen/
│   ├── BorrowScreen/
│   ├── LoanScreen/
│   ├── EarnPoolScreen/
│   ├── LeverageScreen/
│   ├── StakeScreen/
│   ├── RedeemScreen/
│   └── TransactionsScreen/
│
├── comps/                   # Reusable UI components (38 directories)
│   └── [various component folders]
│
├── tx-flows/                # Transaction flow handlers (24 files)
│   ├── openBorrowPosition.tsx
│   ├── updateBorrowPosition.tsx
│   ├── openLeveragePosition.tsx
│   ├── redeemCollateral.tsx
│   ├── earnClaimRewards.tsx
│   ├── stakeDeposit.tsx
│   └── [others]
│
├── services/                # Service layer (6 modules)
│   ├── Ethereum.tsx         # Wallet & chain management
│   ├── Prices.tsx           # Price data management
│   ├── TransactionFlow.tsx  # TX flow orchestration
│   ├── IndicatorManager.tsx # UI indicators
│   ├── ReactQuery.tsx       # Query client setup
│   └── StoredState.tsx      # Local storage
│
├── abi/                     # Contract ABIs (26 files)
├── graphql/                 # GraphQL queries & schemas
├── indicators/              # Shared UI indicators
│
├── constants.ts             # App-wide constants
├── contracts.ts             # Contract address management
├── env.ts                   # Environment variables
├── liquity-utils.ts         # Core Liquity logic (45KB)
├── liquity-math.ts          # Math utilities
├── subgraph.ts              # Subgraph integration
├── formatting.ts            # Number formatting
├── sbold.ts                 # sBOLD (staked BOLD) utilities
├── ybold.ts                 # YBOLD (yield BOLD) utilities
├── liquity-governance.ts    # Governance integration
├── liquity-leverage.ts      # Leverage math
└── [other utilities]
```

### Key Application Sections

1. **Borrow Section** (`/borrow`)
   - Open new trove positions
   - Per-collateral interface
   - Collateral selection and validation

2. **Loan Management** (`/loan`)
   - View active positions
   - Adjust collateral/debt
   - Close positions
   - Manage interest rates

3. **Earn** (`/earn`)
   - Stability Pool deposits
   - Liquidity provision
   - Yield tracking
   - Reward claims

4. **Multiply/Leverage** (`/multiply`)
   - Leveraged positions
   - Flash loan integration
   - Risk management UI

5. **Redeem** (`/redeem`)
   - BOLD redemption interface
   - Route-aware redemption
   - Fee estimation

6. **Stake** (`/stake`)
   - LQTY token staking
   - Governance participation
   - Reward distribution

7. **Account** (`/account`)
   - Portfolio overview
   - Position summary
   - Transaction history

8. **Legacy** (`/legacy`)
   - Liquity V1 support
   - Migration utilities

### Transaction Flow System

The `tx-flows/` directory contains 24 transaction handlers implementing the state machine for each user action:

- **Borrow flows:** openBorrowPosition, updateBorrowPosition, closeLoanPosition
- **Leverage flows:** openLeveragePosition, updateLeveragePosition
- **Redemption flows:** redeemCollateral, legacyRedeemCollateral
- **Earn flows:** earnUpdate, earnClaimRewards, earnWithdrawAll
- **Staking flows:** stakeDeposit, stakeClaimRewards, unstakeDeposit
- **Special flows:** allocateVotingPower, claimBribes, updateLoanInterestRate
- **Legacy flows:** legacyCloseLoanPosition, legacyUnstakeAll

Each flow file exports step-by-step transaction builders that validate inputs and generate contract calls.

### State Management

- **React Query:** Cache and sync remote contract state
- **React Context:** Global app state (wallet, chain, user prefs)
- **Local Storage:** Persisted user preferences via StoredState service
- **Dynamic Import:** Lazy load screens for code splitting

### Build Commands

- `pnpm dev` - Development with hot reload (Turbopack)
- `pnpm build` - Production build (Next.js + PandaCSS)
- `pnpm build-deps` - Build all dependencies first
- `pnpm build-graphql` - Codegen from GraphQL schema
- `pnpm build-panda` - Generate PandaCSS files
- `pnpm lint` - oxlint linting
- `pnpm test` - Vitest unit tests
- `pnpm coverage` - Test coverage reports

---

## Subgraph Architecture

Location: `/subgraph/`

### Purpose

The Graph subgraph indexes Liquity V2 smart contract events and exposes them via GraphQL API. Enables efficient querying of:
- Trove data and history
- Liquidation events
- Redemption tracking
- User portfolio data
- Collateral statistics
- Governance data

### Data Sources

**Primary Contracts (dataSources):**

1. **BoldToken**
   - Tracks BOLD token transfers and approvals
   - Events: CollateralRegistryAddressChanged
   - File: `BoldToken.mapping.ts`

2. **Governance**
   - Tracks LQTY staking and voting
   - Events: DepositLQTY, WithdrawLQTY, AllocateLQTY, RegisterInitiative
   - File: `Governance.mapping.ts`

**Dynamic Templates (templates):**

3. **TroveManager** (per collateral)
   - Dynamically created for each collateral branch
   - Tracks trove operations and state changes
   - Events: TroveOperation, TroveUpdated, BatchedTroveUpdated
   - File: `TroveManager.mapping.ts`

4. **TroveNFT** (per collateral)
   - Tracks NFT transfers (trove ownership)
   - File: `TroveNFT.mapping.ts`

5. **CollSurplusPool** (per collateral)
   - Tracks collateral surplus claims
   - File: `CollSurplusPool.mapping.ts`

### Schema

GraphQL schema (`schema.graphql`) defines:

**Core Entities:**
- `Collateral` - Collateral metadata and stats
- `Trove` - Individual trove state and history
- `InterestRateBracket` - Interest rate ranges
- `InterestBatch` - Batch manager groupings
- `BorrowerInfo` - User portfolio aggregation
- `GovernanceAllocation` - Voting power data
- `GovernanceInitiative` - Governance proposals

**Event Tracking:**
- `TroveOperation` events for all modifications
- Liquidation and redemption tracking
- Balance change history

### Mappings

Each mapping file (written in AssemblyScript) transforms blockchain events into GraphQL entities:

**TroveManager.mapping.ts** (most complex)
- Handles TroveOperation events with nested data
- Tracks interest rate updates
- Updates collateral aggregates
- Computes ICR/CCR ratios

**Governance.mapping.ts**
- Aggregates voting power changes
- Tracks initiative participation

**BoldToken.mapping.ts**
- Token supply tracking

### Build/Deploy

- `pnpm codegen` - Generate TypeScript from schema
- Deployment targets: Mainnet (primary), Sepolia (testnet)
- Start blocks set for each data source (e.g., 22483043 for Mainnet BoldToken)

---

## Build and Development Commands

### Root Level (pnpm)

```bash
# Install all dependencies across all workspaces
pnpm install

# Run linting with dprint (code formatter)
pnpm format

# List all workspaces
pnpm ls --depth=-1
```

### Contracts (`/contracts`)

```bash
# Testing
pnpm test                  # Run all Hardhat tests in parallel
pnpm coverage              # Generate coverage report

# Code quality
pnpm format               # Format with Foundry + dprint

# Utilities
pnpm extract-abi          # Extract ABIs from compiled contracts
pnpm fuzz                 # Run fuzzing campaign
pnpm fuzz-repro           # Reproduce fuzzing result
pnpm fuzz-start           # Start pm2 fuzzing daemon
pnpm fuzz-stop            # Stop fuzzing daemon
pnpm fuzz-monit           # Monitor fuzzing
pnpm fuzz-logs            # View fuzzing logs

# Compilation happens automatically with Hardhat/Foundry
# Forge installs dependencies: cd contracts && forge install
```

**Solidity Compiler:** 0.8.24 (main), 0.8.18 (legacy)
**Testing Framework:** Hardhat + Chai + Foundry

### Frontend (`/frontend/app`)

```bash
# Development
pnpm dev                  # Start Next.js dev server with Turbopack

# Building
pnpm build                # Production build
pnpm build-deps           # Build dependencies (GraphQL, UIKit, PandaCSS)
pnpm build-graphql        # GraphQL code generation
pnpm build-panda          # Generate PandaCSS styling
pnpm build-uikit          # Build uikit package
pnpm clean                # Clear .next cache

# Code quality
pnpm fmt                  # Format code with dprint
pnpm lint                 # Lint with oxlint

# Testing
pnpm test                 # Run Vitest unit tests
pnpm coverage             # Test coverage with Vitest

# Utilities
pnpm update-liquity-abis  # Update contract ABIs from deployed contracts
```

### UIKit (`/frontend/uikit`)

```bash
# Development
pnpm dev                  # Watch mode with Vite

# Building
pnpm build                # Build component library
pnpm build-deps           # Generate PandaCSS files
pnpm build-panda          # PandaCSS codegen

# Utilities
pnpm update-icons         # Update icon set from source
pnpm lint                 # Lint source code
```

### Subgraph (`/subgraph`)

```bash
# Code generation
pnpm codegen              # Generate AssemblyScript types from GraphQL schema
```

---

## Development Setup

### Prerequisites

- **Node.js** v20+
- **pnpm** 8.15.8+
- **Foundry** (for contract development)
- **Anvil** (local blockchain node)

### Quick Start

```bash
# 1. Install dependencies
pnpm install

# 2. Set up contracts (if developing contracts)
cd contracts
forge install
cd ..

# 3. Start local blockchain in separate terminal
anvil

# 4. Deploy contracts to local node
cd contracts
./deploy local --open-demo-troves
cd ..

# 5. Configure frontend
cd frontend/app
cp .env .env.local
# Edit .env.local with contract addresses from deployment output

# 6. Start dev server
pnpm dev

# App running at http://localhost:3000
```

### Environment Variables

**Frontend** (`/frontend/app/.env.local`):
- `NEXT_PUBLIC_SUBGRAPH_URL` - GraphQL endpoint (Graph API key)
- `NEXT_PUBLIC_RPC_URL_*` - RPC URLs per chain
- `NEXT_PUBLIC_CHAIN_ID` - Default chain
- Contract addresses for all deployed contracts
- Feature flags (LQTY_BYPASS_CHECKS, etc.)

**Contracts**:
- `.env` files for deployment networks
- RPC URLs, private keys (development only)
- Chain-specific settings

### Local Development Workflow

1. **Terminal 1:** Start anvil
   ```bash
   anvil
   ```

2. **Terminal 2:** Deploy and develop contracts
   ```bash
   cd contracts
   pnpm test                    # Run tests
   forge build                  # Compile
   ```

3. **Terminal 3:** Develop frontend
   ```bash
   cd frontend/app
   pnpm dev                     # Hot reload at localhost:3000
   ```

### Deployment to Networks

**Sepolia Testnet:**
```bash
cd contracts
./deploy sepolia
# Update frontend .env.local with new addresses
```

**Mainnet:**
```bash
cd contracts
./deploy mainnet
```

Deployment manifests saved to `broadcast/` directory with transaction history.

---

## Key Concepts & Terminology

### Collateral Ratios

- **Individual Collateral Ratio (ICR):** (Trove Collateral Value / Trove Debt) * 100%
- **Total Collateral Ratio (TCR):** (Total Collateral Value / Total Debt) * 100%
- **Minimum Collateral Ratio (MCR):** 110% - minimum individual ratio
- **Batch Collateral Ratio (BCR):** MCR + buffer for batch operations
- **Critical Collateral Ratio (CCR):** 120% - system restrictions trigger
- **Shutdown Collateral Ratio (SCR):** 150% - market freezes

### System States

- **Normal:** TCR > CCR, all operations allowed
- **Critical:** CCR >= TCR > SCR, borrowing restricted
- **Shutdown:** TCR < SCR, only position closing allowed

### Fee Mechanisms

- **Base Rate:** Global rate increased by redemptions and new borrowing
- **Borrowing Fee:** Applied when opening/borrowing against position
- **Redemption Fee:** Progressive fee increasing with amount redeemed
- **Batch Management Fee:** Annual fee for batch managers

### Interest Rates

- **Individual Interest Rate:** Per-trove rate set by borrower or delegate
- **Batch Interest Rate:** Applied to all troves in a batch
- **Recorded Debt:** Current debt including accrued interest
- **Aggregate Debt:** Sum of all recorded debts in system

### Liquidation Types

1. **Stability Pool Offset:** SP BOLD burns to cover debt, collateral distributed to SP
2. **Redistribution:** When SP exhausted, debt/collateral spread to remaining troves
3. **Cascading Liquidation:** Multiple troves liquidated sequentially

### Special Tokens

- **BOLD:** Stablecoin minted/burned by protocol
- **LQTY:** Governance token (Liquity V1)
- **sBOLD:** Staked BOLD (locked in earning strategies)
- **YBOLD:** Yield-bearing BOLD (auto-compounding rewards)

---

## Important Files & Entry Points

### Smart Contracts

- Main borrowing: `/contracts/src/BorrowerOperations.sol`
- Position management: `/contracts/src/TroveManager.sol`
- Liquidations: `/contracts/src/StabilityPool.sol`
- Deployments: `/contracts/script/DeployLiquity2.s.sol`

### Frontend

- App router: `/frontend/app/src/app/`
- Screens: `/frontend/app/src/screens/`
- Transaction flows: `/frontend/app/src/tx-flows/`
- Core logic: `/frontend/app/src/liquity-utils.ts`
- Contract integrations: `/frontend/app/src/contracts.ts`

### Subgraph

- Main mapping: `/subgraph/src/TroveManager.mapping.ts`
- Schema: `/subgraph/schema.graphql`
- Manifest: `/subgraph/subgraph.yaml`

---

## Performance & Optimization Notes

### Smart Contracts

- **Gas Optimization:** Immutable storage for frequently accessed values
- **Linked Lists:** Efficient trove sorting (SortedTroves)
- **Hints System:** Reduces liquidation gas costs from O(n) to O(log n)
- **Batch Operations:** Process multiple liquidations in single transaction
- **Scaled Integers:** 18-decimal precision for all financial values

### Frontend

- **Code Splitting:** Lazy-loaded screen components via dynamic imports
- **Static Generation:** Next.js SSG where possible
- **Query Caching:** React Query with deduplication
- **Image Optimization:** Next.js Image for smart caching

### Subgraph

- **Event Indexing:** Only processes blockchain events (no RPC calls during indexing)
- **Entity Relationships:** GraphQL handles multi-collateral queries
- **Caching:** Graph node caches frequently accessed data

---

## Testing Strategy

### Unit Tests

- **Contracts:** Hardhat + Chai assertions
- **Frontend:** Vitest + React Testing Library
- **Coverage:** Solidity coverage + Vitest coverage

### Integration Tests

- Deploy full system locally with Anvil
- Test end-to-end flows with real contracts
- Use deployment scripts as integration test templates

### Fuzzing

- **Echidna:** Property-based testing for contract invariants
- **PM2 daemon:** Long-running fuzz campaigns
- **Reproducers:** Saved crashing inputs for regression testing

---

## Additional Resources

- **README.md** - Comprehensive protocol documentation
- **INSTRUCTIONS.md** - Setup and deployment guide
- **Contracts README** - Contract-specific documentation
- **Frontend README** - (`/frontend/app/README.md`) Frontend-specific setup
- **GitHub** - https://github.com/liquity/bold

---

*Last Updated: October 2024*
*License: BUSL-1.1 (Contracts), MIT (Frontend)*
