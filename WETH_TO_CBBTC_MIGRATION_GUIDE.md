# WETH to CBBTC Migration Guide

**Version:** 1.0
**Date:** 2025
**Status:** Planning Document

This guide outlines the strategy for migrating the Liquity V2 protocol from WETH to CBBTC as the primary non-LST collateral type.

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Migration Rationale](#migration-rationale)
3. [Migration Timeline](#migration-timeline)
4. [Phase 1: CBBTC Introduction](#phase-1-cbbtc-introduction)
5. [Phase 2: Coexistence Period](#phase-2-coexistence-period)
6. [Phase 3: WETH Deprecation](#phase-3-weth-deprecation)
7. [Phase 4: WETH Sunset](#phase-4-weth-sunset)
8. [User Communication Strategy](#user-communication-strategy)
9. [Technical Implementation](#technical-implementation)
10. [Risk Mitigation](#risk-mitigation)
11. [FAQ](#faq)

---

## Executive Summary

**Goal**: Transition Liquity V2 from WETH to CBBTC collateral over a 6-12 month period.

**Key Metrics**:
- Current WETH TVL: $XXM (to be measured)
- Target CBBTC TVL: $XXM
- Expected migration timeline: 6-12 months
- User impact: Minimal (voluntary migration)

**Approach**: 4-phase gradual migration with incentives for early adopters and zero forced liquidations.

---

## Migration Rationale

### Why Migrate from WETH?

1. **Bitcoin as Superior Collateral**
   - Largest crypto market cap ($1.3T+ vs ETH $400B+)
   - Longer track record (15 years vs 9 years)
   - Lower volatility historically
   - Broader institutional acceptance

2. **CBBTC Benefits**
   - Coinbase-backed 1:1 with BTC
   - Audited and regulated
   - Strong liquidity on major DEXs
   - Lower perceived risk for conservative users

3. **Protocol Diversification**
   - Reduces correlation risk (ETH + ETH LSTs)
   - Attracts Bitcoin-native DeFi users
   - Positions Liquity as multi-asset CDP platform

### Why Keep CBBTC Parameters Same as WETH?

- **Risk Profile**: Both are non-yield-bearing, liquid assets
- **MCR 110%**: Appropriate for highly liquid collateral
- **CCR 150%**: Matches WETH's proven safety margin
- **User Familiarity**: Easier migration if parameters identical

---

## Migration Timeline

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  Phase 1          Phase 2              Phase 3          Phase 4    │
│  Introduction     Coexistence          Deprecation      Sunset      │
│  (1-2 months)     (3-6 months)         (2-3 months)     (1 month)   │
│                                                                     │
│  ┌─────────┐     ┌──────────────┐     ┌────────────┐   ┌────────┐  │
│  │ Deploy  │────▶│ Incentivize  │────▶│ Soft       │──▶│ Close  │  │
│  │ CBBTC   │     │ Migration    │     │ Deprecate  │   │ WETH   │  │
│  │         │     │              │     │ WETH       │   │ Branch │  │
│  └─────────┘     └──────────────┘     └────────────┘   └────────┘  │
│                                                                     │
│  - Audit        - Migration tool   - Stop new WETH   - Force close │
│  - Deploy       - Incentive pools  - UI warnings     - Archive data│
│  - Test         - Monitor growth   - Docs updates    - Final comms │
│  - Announce     - Community        - Grace period    - Celebrate   │
│                   support                                           │
└─────────────────────────────────────────────────────────────────────┘
```

### Estimated Duration: 7-12 months total

---

## Phase 1: CBBTC Introduction (Months 1-2)

### Objectives
- ✅ Deploy CBBTC contracts
- ✅ Verify oracle reliability
- ✅ Launch UI support
- ✅ Seed initial liquidity

### Actions

#### Week 1-2: Security & Testing
- [ ] Complete security audit of CBBTCPriceFeed
- [ ] Run 1-week oracle monitoring test
- [ ] Perform stress testing on testnet
- [ ] Review insurance/backstop options

#### Week 3-4: Deployment
- [ ] Deploy CBBTC contracts to mainnet
- [ ] Verify contracts on Etherscan
- [ ] Deploy updated frontend
- [ ] Update documentation

#### Week 5-6: Initial Liquidity
- [ ] Team opens first CBBTC troves (dogfooding)
- [ ] Seed CBBTC/BOLD Curve pool
- [ ] Establish CBBTC/USDC Uniswap pool
- [ ] Monitor first user troves closely

#### Week 7-8: Soft Launch
- [ ] Announce CBBTC support (Twitter, Discord, blog)
- [ ] Create migration tutorials
- [ ] Host community AMA
- [ ] Gather early feedback

### Success Criteria
- At least 10 CBBTC troves opened
- $1M+ TVL in CBBTC branch
- No oracle failures in 30 days
- Positive community sentiment

---

## Phase 2: Coexistence Period (Months 3-8)

### Objectives
- Grow CBBTC adoption organically
- Maintain WETH branch stability
- Build migration momentum
- Monitor system health

### Strategy 1: Migration Incentives

#### Option A: Direct BOLD Rewards
```
Migrate WETH → CBBTC and receive:
- 100 BOLD bonus (for troves >$10k)
- 500 BOLD bonus (for troves >$50k)
- 1000 BOLD bonus (for troves >$100k)

Total incentive budget: $500k in BOLD
```

#### Option B: Interest Rate Discount
```
CBBTC troves get:
- 0.25% lower minimum interest rate
- WETH min: 0.5%, CBBTC min: 0.25%
- Saves $25/year per $10k borrowed
```

#### Option C: Governance Token Airdrop
```
Snapshot CBBTC trove owners monthly
Distribute governance tokens based on:
- TVL contributed
- Duration held
- Activity (adjustments, redemptions handled)
```

### Strategy 2: One-Click Migration Tool

Deploy migration contract:

```solidity
contract WETHToCBBTCMigrator {
    // One-transaction migration:
    // 1. Close WETH trove
    // 2. Swap WETH for CBBTC on DEX
    // 3. Open CBBTC trove with same parameters
    // 4. Mint incentive bonus

    function migrateWETHToCBBTC(uint256 wethTroveId) external {
        // Gas-optimized, single-transaction migration
    }
}
```

**Frontend Flow:**
1. User clicks "Migrate to CBBTC"
2. Shows preview: debt, collateral, new trove parameters
3. One-click approval + execution
4. Bonus BOLD credited instantly

### Strategy 3: Educational Campaign

**Content Marketing:**
- [ ] "Why CBBTC? The Case for Bitcoin Collateral" (blog post)
- [ ] "Migration Step-by-Step" (video tutorial)
- [ ] "CBBTC vs WETH: Risk Comparison" (infographic)
- [ ] Weekly migration updates (Twitter thread)

**Community Engagement:**
- [ ] Migration contests (biggest migrator, most innovative use)
- [ ] Discord migration support channel
- [ ] Bi-weekly migration AMAs
- [ ] Feature migrated users in case studies

### Monitoring Metrics

Track weekly:
```
WETH Branch:
- Total troves: XXX → YYY (-Z%)
- TVL: $XXM → $YYM (-Z%)
- New troves: XX/week → Y/week

CBBTC Branch:
- Total troves: XXX → YYY (+Z%)
- TVL: $XXM → $YYM (+Z%)
- Migrations: XX/week

Target: CBBTC > 50% of WETH TVL by month 6
```

### Success Criteria
- CBBTC TVL > $10M
- CBBTC troves > 100
- At least 25% of WETH users migrated
- Zero critical incidents in CBBTC branch

---

## Phase 3: WETH Deprecation (Months 9-11)

### Objectives
- Signal WETH sunset
- Accelerate remaining migrations
- Prepare for branch closure
- Minimize user disruption

### Actions

#### Month 9: Soft Deprecation

**UI Changes:**
- Add warning banner on WETH borrow page:
  ```
  ⚠️ WETH collateral is being phased out.
  Migrate to CBBTC to continue using Liquity V2.
  ```
- Show migration CTA on all WETH trove pages
- Hide WETH from new user flows (keep in dropdown for existing users)

**Smart Contract Changes:**
- **Do NOT** disable WETH operations (users can still manage troves)
- **Do NOT** force close troves
- Continue normal redemptions, liquidations, interest

#### Month 10: Accelerated Migration

**Increased Incentives:**
```
Final migration bonus (last 60 days):
- 2x BOLD rewards
- Priority customer support
- Exclusive NFT for "V2 Pioneer" migrators
```

**Notifications:**
- Email all WETH trove owners (if emails available)
- On-chain notifications via Trove NFT metadata
- Discord DMs to active community members

**Migration Assistance:**
- Dedicated migration support chat
- Gas fee reimbursement for large troves (>$100k)
- White-glove service for whales (>$1M)

#### Month 11: Final Call

**Hard Deadline Announcement:**
```
📢 FINAL NOTICE 📢

WETH collateral support ends on [DATE].

After this date:
❌ No new WETH troves
❌ No WETH collateral additions
✅ Can still close existing troves
✅ Can still withdraw collateral

Migrate to CBBTC before [DATE] to maintain your position.
```

**Documentation Updates:**
- Mark WETH as "deprecated" in all docs
- Update README to show CBBTC as primary
- Archive WETH guides to "legacy" section

### Success Criteria
- >90% of WETH TVL migrated
- <50 remaining WETH troves
- Clear communication to all users
- Migration tool battle-tested

---

## Phase 4: WETH Sunset (Month 12)

### Objectives
- Close WETH branch cleanly
- Ensure all users have exited or migrated
- Archive historical data
- Celebrate successful migration

### Week 1-2: Grace Period Ends

**Smart Contract Updates:**
```solidity
// Disable new WETH trove openings
function openTrove() external {
    require(block.timestamp < WETH_SUNSET_DATE, "WETH branch closed");
    // ... rest of logic
}

// Disable WETH collateral additions
function addColl() external {
    require(block.timestamp < WETH_SUNSET_DATE, "WETH branch closed");
    // ... rest of logic
}

// Allow withdrawals and closures indefinitely
```

**Frontend Changes:**
- Remove WETH from collateral dropdown
- Redirect `/borrow/eth` to `/borrow/cbbtc` with migration banner
- Keep read-only view for existing WETH troves

### Week 3-4: Force Close Mechanism (If Needed)

**For Abandoned Troves:**

If users haven't migrated/closed after 60-day grace period:

```solidity
// Governance-triggered batch closure
function forceCloseAbandonedWETHTroves(uint256[] calldata troveIds) external onlyGovernance {
    for (uint256 i = 0; i < troveIds.length; i++) {
        // 1. Repay debt from collateral (sell WETH for BOLD via DEX)
        // 2. Return remaining collateral to owner
        // 3. Close trove
        // 4. Emit event for user to claim remaining coll
    }
}
```

**Protection:**
- Only callable after grace period
- Requires governance multisig
- Prioritizes user funds (no liquidation penalty)
- Transparent on-chain audit trail

### Week 5-6: Data Archival

**Historical Data:**
- [ ] Archive all WETH trove data to IPFS
- [ ] Preserve event logs on Etherscan
- [ ] Update subgraph with "closed" status
- [ ] Maintain read-only API endpoints

**Analytics:**
- [ ] Final WETH branch report (total TVL, users, duration)
- [ ] Migration success metrics (% migrated, avg. time, incentives spent)
- [ ] Lessons learned document

### Week 7-8: Celebration & Retrospective

**Community:**
- [ ] "CBBTC Migration Complete" announcement
- [ ] Publish migration case study
- [ ] Thank migrators (highlight top contributors)
- [ ] POAP/NFT for all participants

**Internal:**
- [ ] Team retrospective meeting
- [ ] Update playbooks for future migrations
- [ ] Archive code and documentation
- [ ] Plan next collateral addition

### Success Criteria
- 100% of WETH TVL migrated or closed
- Zero user funds lost
- Positive community feedback
- Clean protocol state (3 active branches: wstETH, rETH, CBBTC)

---

## User Communication Strategy

### Communication Channels

1. **In-App Notifications**
   - Banner on WETH trove pages
   - Modal on app load (dismissible)
   - Toast on WETH operations

2. **Email** (if available)
   - Month 1: "Introducing CBBTC Collateral"
   - Month 3: "Migrate to CBBTC and Earn Rewards"
   - Month 9: "WETH Deprecation Notice"
   - Month 11: "Final Call: WETH Sunset in 30 Days"

3. **Social Media**
   - Twitter announcements (pinned thread)
   - Discord server (dedicated #migration channel)
   - Blog posts (migration guides)
   - YouTube tutorials

4. **On-Chain**
   - Trove NFT metadata updates
   - Events emitted on key milestones
   - Smart contract comments

### Messaging Framework

**Tone**: Supportive, transparent, user-first

**Key Messages:**
- ✅ "Your funds are safe" (no forced liquidations)
- ✅ "Migrating is easy" (one-click tool)
- ✅ "Migrating is rewarding" (incentives)
- ✅ "We're here to help" (support available)

**Avoid:**
- ❌ Urgency without support ("migrate NOW or else!")
- ❌ Technical jargon ("oracle aggregator migration")
- ❌ Downplaying WETH ("WETH is bad")

### Sample Communications

#### Month 1 Announcement

```
📢 Introducing CBBTC Collateral on Liquity V2! 📢

We're excited to announce support for Coinbase Wrapped Bitcoin (CBBTC)
as a new collateral option.

Why CBBTC?
• Bitcoin's proven track record
• Lower volatility vs. ETH
• Coinbase-backed 1:1 with BTC
• Same great 110% MCR as WETH

WETH isn't going anywhere yet! Both collaterals will coexist while we
gather feedback and optimize the experience.

Try CBBTC today: https://liquity.app/borrow/cbbtc
```

#### Month 9 Deprecation Notice

```
⚠️ Important: WETH Collateral Deprecation Timeline ⚠️

To improve protocol stability, we're phasing out WETH in favor of CBBTC.

Timeline:
• Now: WETH still fully supported
• Month 11: New WETH troves disabled
• Month 12: WETH branch closes (existing troves closable)

What you need to do:
1. Migrate to CBBTC (one-click tool available)
2. OR close your WETH trove and withdraw collateral

Migration rewards still available! Get up to 1000 BOLD bonus.

Need help? Join #migration-support on Discord or visit our guide:
https://docs.liquity.app/migration
```

#### Month 12 Final Notice

```
🚨 FINAL NOTICE: WETH Branch Closes in 7 Days 🚨

This is your last chance to migrate or close your WETH trove.

After [DATE]:
❌ Cannot open new WETH troves
❌ Cannot add WETH collateral
✅ Can still withdraw and close

Your options:
1. Migrate to CBBTC now (get 2x bonus!)
2. Close trove and withdraw WETH
3. Do nothing (we'll help close your trove after grace period)

Migrate here: https://liquity.app/migrate

Questions? DM @LiquitySupport or email support@liquity.org
```

---

## Technical Implementation

### Migration Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract WETHToCBBTCMigrator {
    IBorrowerOperations public immutable wethBorrowerOps;
    IBorrowerOperations public immutable cbbtcBorrowerOps;
    ITroveManager public immutable wethTroveManager;
    IBoldToken public immutable boldToken;
    IERC20 public immutable WETH;
    IERC20 public immutable CBBTC;
    ISwapRouter public immutable uniswapRouter;

    uint256 public migrationBonusPerTrove = 100e18; // 100 BOLD

    event TroveMigrated(
        address indexed user,
        uint256 wethTroveId,
        uint256 cbbtcTroveId,
        uint256 collAmount,
        uint256 debtAmount,
        uint256 bonus
    );

    function migrateWETHToCBBTC(
        uint256 wethTroveId,
        uint256 minCBBTCOut,
        uint24 uniswapFee
    ) external returns (uint256 cbbtcTroveId) {
        address user = msg.sender;

        // 1. Get WETH trove details
        LatestTroveData memory wethTrove = wethTroveManager.getLatestTroveData(wethTroveId);
        require(wethTrove.entireDebt > 0, "Trove doesn't exist");

        // 2. Close WETH trove (debt repaid, collateral returned)
        uint256 wethReceived = _closeWETHTrove(wethTroveId, user);

        // 3. Swap WETH for CBBTC on Uniswap
        uint256 cbbtcReceived = _swapWETHForCBBTC(wethReceived, minCBBTCOut, uniswapFee);

        // 4. Open CBBTC trove with same parameters
        cbbtcTroveId = _openCBBTCTrove(
            user,
            cbbtcReceived,
            wethTrove.entireDebt,
            wethTrove.annualInterestRate
        );

        // 5. Mint bonus BOLD
        if (migrationBonusPerTrove > 0 && wethTrove.entireDebt >= 10000e18) {
            boldToken.mint(user, migrationBonusPerTrove);
        }

        emit TroveMigrated(
            user,
            wethTroveId,
            cbbtcTroveId,
            cbbtcReceived,
            wethTrove.entireDebt,
            migrationBonusPerTrove
        );
    }

    function _closeWETHTrove(uint256 troveId, address user) internal returns (uint256) {
        // Transfer Trove NFT to this contract
        // Close trove via BorrowerOperations
        // Return WETH amount withdrawn
    }

    function _swapWETHForCBBTC(
        uint256 wethAmount,
        uint256 minCBBTCOut,
        uint24 fee
    ) internal returns (uint256) {
        // Uniswap V3 swap: WETH → CBBTC
        // Slippage protection via minCBBTCOut
    }

    function _openCBBTCTrove(
        address user,
        uint256 collAmount,
        uint256 debtAmount,
        uint256 interestRate
    ) internal returns (uint256) {
        // Approve CBBTC to BorrowerOperations
        // Open trove with same debt and interest rate
        // Transfer Trove NFT to user
    }
}
```

### Frontend Migration UI

```tsx
// MigrationModal.tsx
export function MigrationModal({ wethTroveId, wethTrove }: Props) {
  const [slippage, setSlippage] = useState(0.5); // 0.5%
  const [estimatedCBBTC, setEstimatedCBBTC] = useState<bigint>(0n);

  const estimate = useEstimateMigration(wethTrove.collateral);

  useEffect(() => {
    // Fetch WETH/CBBTC price from Uniswap
    // Calculate expected CBBTC amount minus fees
    setEstimatedCBBTC(estimate);
  }, [wethTrove.collateral, slippage]);

  return (
    <Modal title="Migrate to CBBTC">
      <div className="migration-summary">
        <h3>Current WETH Trove</h3>
        <p>Collateral: {formatEther(wethTrove.collateral)} WETH</p>
        <p>Debt: {formatEther(wethTrove.debt)} BOLD</p>
        <p>Interest: {wethTrove.interestRate}%</p>

        <Arrow />

        <h3>New CBBTC Trove</h3>
        <p>Collateral: ~{formatEther(estimatedCBBTC)} CBBTC</p>
        <p>Debt: {formatEther(wethTrove.debt)} BOLD</p>
        <p>Interest: {wethTrove.interestRate}% (same)</p>

        <BonusBadge>
          +{MIGRATION_BONUS} BOLD Bonus! 🎉
        </BonusBadge>
      </div>

      <SlippageInput value={slippage} onChange={setSlippage} />

      <Button onClick={handleMigrate}>
        Migrate to CBBTC
      </Button>

      <SmallPrint>
        This will close your WETH trove, swap WETH for CBBTC on Uniswap,
        and open a new CBBTC trove in one transaction.
      </SmallPrint>
    </Modal>
  );
}
```

---

## Risk Mitigation

### Risk 1: Mass Exodus from WETH

**Scenario**: Users panic-migrate, causing WETH liquidity crisis

**Mitigation**:
- Gradual 6-12 month timeline
- No forced migrations
- Stagger incentives to smooth migration curve
- Monitor WETH Stability Pool health

### Risk 2: CBBTC Oracle Failure

**Scenario**: Chainlink CBBTC/USD oracle stops updating

**Mitigation**:
- 24h staleness threshold (graceful degradation)
- LastGoodPrice fallback mechanism
- Monitor oracle health 24/7
- Emergency shutdown procedure tested

### Risk 3: CBBTC Depegging

**Scenario**: CBBTC loses 1:1 peg with BTC

**Mitigation**:
- Conservative MCR (110% same as WETH)
- Stability Pool buffer
- Emergency shutdown at 5% depeg
- Insurance fund consideration

### Risk 4: User Confusion

**Scenario**: Users don't understand migration or miss deadline

**Mitigation**:
- Multi-channel communication
- Simple one-click migration tool
- Generous grace period (60+ days)
- No forced liquidations
- Support team trained

### Risk 5: Smart Contract Bug in Migrator

**Scenario**: Migration contract has exploit

**Mitigation**:
- Full security audit before launch
- Bug bounty program
- Gradual rollout (test with team first)
- Circuit breakers
- User approval limits

### Risk 6: Regulatory Issues with CBBTC

**Scenario**: Coinbase discontinues CBBTC or regulatory action

**Mitigation**:
- Monitor Coinbase announcements
- Backup plan to support other wrapped BTC (WBTC, tBTC)
- Can keep both WETH and CBBTC long-term if needed
- Diversification strategy

---

## FAQ

### For Users

**Q: Do I have to migrate?**
A: No, migration is voluntary. However, WETH support will eventually be removed, so migrating to CBBTC is recommended.

**Q: What happens if I don't migrate?**
A: After the grace period, you can still close your WETH trove and withdraw collateral. New WETH troves will be disabled.

**Q: Will I lose money migrating?**
A: The migration tool includes slippage protection. Swap fees (~0.05%) apply, but you'll receive a BOLD bonus to offset costs.

**Q: Why CBBTC instead of WBTC?**
A: CBBTC is backed by Coinbase, a regulated US company, with strong liquidity and lower counterparty risk than WBTC's BitGo custody.

**Q: Can I keep both WETH and CBBTC troves?**
A: Yes! During the coexistence period (months 3-8), you can have both.

**Q: What if CBBTC depegs?**
A: The system has a 110% MCR and emergency shutdown mechanisms. Liquity would trigger shutdown if depeg >5%.

### For Developers

**Q: Will the migration affect the subgraph?**
A: Yes, subgraph will be updated to show WETH as "deprecated". Historical data preserved.

**Q: Are there breaking changes to the smart contracts?**
A: No. CBBTC is added as index 3, WETH remains at index 0. Only new deployments affected.

**Q: How does the migration contract work?**
A: It closes the WETH trove, swaps WETH→CBBTC via Uniswap, and opens a CBBTC trove in one transaction.

**Q: Can we fork this for other collaterals?**
A: Yes! The migration contract is modular. See `CONSIDERATIONS_FOR_V2_FORKS.md` in the README.

---

## Appendix A: Migration Checklist

Use this checklist to track migration progress:

### Phase 1: Introduction
- [ ] Audit CBBTCPriceFeed
- [ ] Deploy CBBTC contracts
- [ ] Launch frontend support
- [ ] Announce to community
- [ ] Monitor first 30 days

### Phase 2: Coexistence
- [ ] Deploy migration contract
- [ ] Launch migration tool UI
- [ ] Activate incentive program
- [ ] Publish migration guides
- [ ] Monitor monthly metrics
- [ ] Hit 50% migration target

### Phase 3: Deprecation
- [ ] Add UI warnings
- [ ] Send user notifications
- [ ] Increase incentives
- [ ] Set hard deadline
- [ ] Achieve 90% migration

### Phase 4: Sunset
- [ ] Disable new WETH troves
- [ ] Gracefully close remaining
- [ ] Archive historical data
- [ ] Celebrate success
- [ ] Document lessons learned

---

## Appendix B: Cost Estimate

| Item | Estimated Cost |
|------|----------------|
| **Security Audit** | $50k - $100k |
| **Migration Incentives** (BOLD rewards) | $200k - $500k |
| **Development Time** (smart contracts + frontend) | 160 hours @ $200/hr = $32k |
| **Marketing & Communications** | $20k - $50k |
| **Support & Monitoring** (12 months) | $50k |
| **Gas Reimbursements** (large troves) | $10k - $30k |
| **Contingency** (20%) | $76k - $152k |
| **TOTAL** | **$438k - $914k** |

**Funding Options:**
1. Protocol treasury allocation
2. DAO governance vote
3. Gradual fee collection over 12 months

---

## Appendix C: Metrics Dashboard

Track these KPIs weekly:

```
Migration Health Score = (
  (CBBTC TVL / (CBBTC TVL + WETH TVL)) * 40% +
  (CBBTC Troves / Total Troves) * 30% +
  (Weekly Migrations / 10) * 20% +
  (Community Sentiment Score) * 10%
)

Target: >80% by Month 8
```

**Dashboards to Build:**
- Real-time migration counter
- TVL comparison chart (WETH vs CBBTC)
- Migration leaderboard (top migrators)
- Oracle health monitor
- User sentiment tracker

---

## Conclusion

This migration represents a significant evolution for Liquity V2, positioning the protocol as a leader in multi-asset CDP platforms. By prioritizing user experience, providing generous incentives, and maintaining transparent communication, we can achieve a smooth transition that strengthens the protocol's long-term sustainability.

**Key Success Factors:**
1. ✅ No user funds lost
2. ✅ Voluntary migration (no forced liquidations)
3. ✅ Clear communication at every step
4. ✅ Generous migration rewards
5. ✅ Strong technical execution

**Timeline**: 6-12 months
**Budget**: $438k - $914k
**Risk**: Low-Medium (with proper execution)
**Reward**: Diversified collateral base, Bitcoin exposure, stronger protocol

---

**Prepared by**: Liquity Development Team
**Review Required**: DAO Governance, Security Team, Community
**Status**: Draft for Discussion

**Next Steps:**
1. Community feedback (30 days)
2. DAO governance vote
3. Security audit procurement
4. Phase 1 execution planning

---

*For questions or suggestions, open a GitHub issue or post in #protocol-development on Discord.*
