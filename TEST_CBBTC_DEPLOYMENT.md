# CBBTC Deployment Testing Guide

This guide walks through testing the CBBTC integration on local Anvil and testnets.

---

## Prerequisites

Ensure you have:
- Node.js v18+
- pnpm installed
- Foundry installed (`foundryup`)
- Mainnet RPC URL (for forking)

---

## Step 1: Local Anvil Fork Testing

### 1.1 Set Environment Variables

Create or update `/contracts/.env`:

```bash
# Required for mainnet fork
FORK_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY
FORK_BLOCK_NUMBER=21571000  # Or latest block
FORK_CHAIN_ID=1

# Optional
DEPLOYER=0xYourDeployerPrivateKey
SALT=Liquity2
USE_TESTNET_PRICEFEEDS=false
ETHERSCAN_API_KEY=your_key_here
```

### 1.2 Start Anvil Fork

Terminal 1:
```bash
cd contracts
pnpm anvil:start
```

Expected output:
```
Starting Anvil fork on http://127.0.0.1:8545
Forking from block 21571000...
```

### 1.3 Run Unit Tests

Terminal 2:
```bash
cd contracts

# Test CBBTC PriceFeed specifically
forge test --match-contract CBBTCPriceFeedTest -vv

# Test multicollateral integration
forge test --match-contract MulticollateralTest -vv

# Run all tests
pnpm test
```

Expected results:
- ✅ `testConstructorInitialization` - PriceFeed initializes correctly
- ✅ `testFetchPriceSuccess` - Oracle returns valid price
- ✅ `testFetchRedemptionPrice` - Redemption price matches
- ✅ `testMultiCollateralDeployment` - 4 collaterals deployed
- ✅ `testMultiCollateralRedemption` - Redemptions work across all branches

### 1.4 Deploy to Anvil Fork

```bash
cd contracts
pnpm deploy:fork
```

Expected output:
```
Deploying Liquity V2 with 4 collateral branches...
Branch 0: WETH
Branch 1: wstETH
Branch 2: rETH
Branch 3: CBBTC

✅ CBBTCPriceFeed deployed at: 0x...
✅ TroveManager (CBBTC) deployed at: 0x...
✅ StabilityPool (CBBTC) deployed at: 0x...
✅ CollateralRegistry updated with 4 collaterals

Deployment complete!
```

### 1.5 Verify Deployment

Check deployment addresses:
```bash
cat contracts/addresses/31337.json
```

Should show 4 branches including:
```json
{
  "branches": [
    { "collSymbol": "WETH", ... },
    { "collSymbol": "wstETH", ... },
    { "collSymbol": "rETH", ... },
    { "collSymbol": "CBBTC", "collToken": "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf", ... }
  ]
}
```

### 1.6 Test Frontend Integration

Terminal 3:
```bash
cd ../frontend/app

# Update .env with Anvil addresses
# Set NEXT_PUBLIC_CHAIN_ID=31337
# Set NEXT_PUBLIC_CHAIN_RPC_URL=http://127.0.0.1:8545
# Uncomment and fill NEXT_PUBLIC_COLL_3_* variables

pnpm dev
```

Visit http://localhost:3000 and verify:
- [ ] CBBTC appears in collateral dropdown
- [ ] Can navigate to /borrow/cbbtc
- [ ] Can navigate to /multiply/cbbtc
- [ ] CBBTC icon displays correctly
- [ ] Price fetches from oracle (~$65,000)

---

## Step 2: Sepolia Testnet Deployment

### 2.1 Get Sepolia Setup

1. Get Sepolia ETH from faucet: https://sepoliafaucet.com/
2. Get testnet cbBTC (if available) or deploy mock ERC20
3. Update `.env`:

```bash
FORK_URL=https://sepolia.infura.io/v3/YOUR_API_KEY
FORK_CHAIN_ID=11155111
DEPLOYER=0xYourSepoliaPrivateKey
USE_TESTNET_PRICEFEEDS=true  # Uses mocks instead of real oracles
```

### 2.2 Deploy to Sepolia

```bash
cd contracts
pnpm deploy:sepolia
```

⚠️ **Note**: On Sepolia, `USE_TESTNET_PRICEFEEDS=true` will deploy `PriceFeedTestnet` mocks instead of real Chainlink oracles since cbBTC may not have Sepolia oracle.

### 2.3 Update Frontend for Sepolia

In `/frontend/app/.env`, uncomment Sepolia section and update:

```bash
# Uncomment Sepolia config
NEXT_PUBLIC_CHAIN_ID=11155111
NEXT_PUBLIC_CHAIN_RPC_URL=https://sepolia.infura.io/v3/YOUR_API_KEY
...

# Update CBBTC addresses from deployment
NEXT_PUBLIC_COLL_3_TOKEN_ID=CBBTC
NEXT_PUBLIC_COLL_3_CONTRACT_ACTIVE_POOL=0x...
NEXT_PUBLIC_COLL_3_CONTRACT_BORROWER_OPERATIONS=0x...
# ... all 11 contract addresses
```

### 2.4 Test on Sepolia

```bash
cd frontend/app
pnpm build
pnpm start
```

Manual testing:
- [ ] Connect MetaMask to Sepolia
- [ ] Open trove with CBBTC collateral
- [ ] Borrow BOLD against CBBTC
- [ ] Adjust trove (add/remove collateral)
- [ ] Close trove
- [ ] Verify transactions on Sepolia Etherscan

---

## Step 3: Mainnet Deployment (Production)

⚠️ **CRITICAL**: Only deploy after:
1. ✅ Full security audit of CBBTCPriceFeed
2. ✅ All tests passing on Anvil and Sepolia
3. ✅ Oracle verified operational: `0x2665701293fCbEB223D11A08D826563EDcCE423A`
4. ✅ Team approval

### 3.1 Pre-Deployment Checklist

- [ ] Auditor has reviewed CBBTCPriceFeed.sol
- [ ] All Foundry tests pass
- [ ] Frontend builds without errors
- [ ] Oracle health verified on mainnet
- [ ] Deployer wallet has sufficient ETH for gas (~5 ETH recommended)
- [ ] Deployment key secured (hardware wallet recommended)
- [ ] Emergency pause mechanism tested
- [ ] Monitoring tools ready

### 3.2 Deploy to Mainnet

```bash
cd contracts

# Double-check .env
FORK_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY
FORK_CHAIN_ID=1
DEPLOYER=0xYourMainnetDeployerKey  # Use hardware wallet!
USE_TESTNET_PRICEFEEDS=false  # Use real oracles

# Dry run first
forge script script/DeployLiquity2.s.sol --rpc-url $FORK_URL --private-key $DEPLOYER --simulate

# If simulation passes, deploy
pnpm deploy:mainnet
```

### 3.3 Verify Contracts on Etherscan

```bash
# Verify CBBTCPriceFeed
forge verify-contract \
  --chain-id 1 \
  --constructor-args $(cast abi-encode "constructor(address,uint256,address)" 0x2665701293fCbEB223D11A08D826563EDcCE423A 86400 0xBorrowerOpsAddress) \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  0xDeployedCBBTCPriceFeedAddress \
  src/PriceFeeds/CBBTCPriceFeed.sol:CBBTCPriceFeed

# Verify other CBBTC branch contracts...
```

### 3.4 Update Production Frontend

```bash
cd frontend/app

# Update .env.production
NEXT_PUBLIC_CHAIN_ID=1
NEXT_PUBLIC_COLL_3_TOKEN_ID=CBBTC
# ... fill all addresses from contracts/addresses/1.json

pnpm build
# Deploy to production (Vercel, etc.)
```

### 3.5 Deploy Subgraph

```bash
cd subgraph

# Update subgraph.yaml with correct start block
# (Use deployment block number)

pnpm codegen
pnpm build
pnpm deploy:mainnet
```

---

## Step 4: Post-Deployment Monitoring

### 4.1 First 24 Hours - Critical Monitoring

Monitor these metrics every hour:

1. **Oracle Health**
   - Check `cbbtcPriceFeed.fetchPrice()` returns valid data
   - Verify price updates within 24h window
   - Compare against CoinGecko/CoinMarketCap BTC price

2. **First Trove Operations**
   - Monitor first CBBTC trove openings
   - Check collateral ratios
   - Verify BOLD minting amounts

3. **Price Feed Status**
   - `cbbtcPriceFeed.priceSource()` should return `0` (primary)
   - `cbbtcPriceFeed.lastGoodPrice()` should match current price
   - Oracle `roundId` should be incrementing

4. **Gas Costs**
   - Compare CBBTC operations to WETH baseline
   - Check for any unusual gas spikes

### 4.2 Monitoring Commands

```solidity
// Check oracle status
cast call 0xCBBTCPriceFeedAddress "fetchPrice()(uint256,bool)"

// Check price source
cast call 0xCBBTCPriceFeedAddress "priceSource()(uint8)"

// Get last good price
cast call 0xCBBTCPriceFeedAddress "lastGoodPrice()(uint256)"

// Check CollateralRegistry
cast call 0xCollateralRegistryAddress "totalCollaterals()(uint256)"
// Should return 4

// Check CBBTC TroveManager
cast call 0xCBBTCTroveManagerAddress "getTroveIdsCount()(uint256)"
// Shows number of CBBTC troves
```

### 4.3 Alert Triggers

Set up alerts for:
- ❌ Oracle failure (priceSource != 0)
- ❌ Stale price (>24h old)
- ❌ Price deviation >10% from market
- ❌ First liquidation event
- ❌ Unusual redemption volume
- ❌ Gas costs >2x normal

---

## Step 5: Rollback Plan

If critical issues arise:

### 5.1 Emergency Pause (If Implemented)
```solidity
// Trigger branch shutdown if needed
cast send 0xGovernanceAddress "triggerBranchShutdown(uint256)" 3
```

### 5.2 Frontend Disable
```bash
# Remove CBBTC from frontend
cd frontend/app
# Comment out CBBTC in tokens.ts COLLATERALS array
# Comment out cbbtc in route params
git commit -m "Emergency: Disable CBBTC UI"
git push origin main
# Redeploy
```

### 5.3 Communication
- [ ] Post mortem to Discord/Twitter
- [ ] Update documentation
- [ ] Notify users of any risks
- [ ] Plan remediation

---

## Troubleshooting

### Issue: "Oracle already failed" on deployment
**Solution**: Check oracle address is correct `0x2665701293fCbEB223D11A08D826563EDcCE423A`

### Issue: Frontend doesn't show CBBTC
**Solution**:
1. Check env vars are uncommented
2. Verify token address matches deployment
3. Clear browser cache
4. Check console for TypeScript errors

### Issue: Tests fail on Anvil
**Solution**:
1. Ensure forking from recent block
2. Check FORK_URL is valid
3. Verify oracle is accessible

### Issue: Price is 0 or unrealistic
**Solution**:
1. Check oracle staleness threshold
2. Verify Chainlink feed is live
3. Check for network congestion

---

## Success Criteria

Deployment is successful when:

- [x] All unit tests pass
- [x] All integration tests pass
- [x] Deployment completes without errors
- [x] Oracle returns valid price (~$40k-$100k range)
- [x] First trove can be opened
- [x] BOLD can be borrowed against CBBTC
- [x] Frontend displays CBBTC correctly
- [x] Subgraph indexes CBBTC data
- [x] No critical alerts in first 48h

---

## Next Steps After Successful Deployment

1. Monitor for 1 week before announcing publicly
2. Seed initial liquidity in CBBTC branch
3. Coordinate with BOLD/CBBTC liquidity pools
4. Announce to community
5. Begin WETH deprecation plan (see migration guide)

---

**Questions or issues?** Check deployment logs in `contracts/broadcast/` or contract verification on Etherscan.
