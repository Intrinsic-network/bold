// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "src/PriceFeeds/CBBTCPriceFeed.sol";
import "src/PriceFeeds/MainnetPriceFeedBase.sol";

import "./TestContracts/Accounts.sol";
import "./TestContracts/ChainlinkOracleMock.sol";
import "./TestContracts/Deployment.t.sol";

import "src/Dependencies/AggregatorV3Interface.sol";

import "forge-std/Test.sol";
import "forge-std/console2.sol";

contract CBBTCPriceFeedTest is TestAccounts {
    AggregatorV3Interface cbbtcOracle;
    ChainlinkOracleMock mockOracle;

    CBBTCPriceFeed cbbtcPriceFeed;
    address borrowerOperations;

    uint256 constant CBBTC_ORACLE_ADDRESS = 0x2665701293fCbEB223D11A08D826563EDcCE423A;
    uint256 constant CBBTC_USD_STALENESS_THRESHOLD = 24 hours;

    // Sample prices (cbBTC typically tracks BTC price ~$40k-$100k)
    int256 constant INITIAL_CBBTC_PRICE = 65000e8; // $65,000 with 8 decimals

    function setUp() public {
        // Try to fork mainnet, skip if not available
        try vm.envString("MAINNET_RPC_URL") returns (string memory rpcUrl) {
            vm.createSelectFork(rpcUrl);

            // Use real Chainlink oracle on mainnet
            cbbtcOracle = AggregatorV3Interface(CBBTC_ORACLE_ADDRESS);

            // Deploy borrowerOperations mock
            borrowerOperations = address(new Accounts());

            // Deploy CBBTCPriceFeed with real oracle
            cbbtcPriceFeed = new CBBTCPriceFeed(
                CBBTC_ORACLE_ADDRESS,
                CBBTC_USD_STALENESS_THRESHOLD,
                borrowerOperations
            );
        } catch {
            // If no mainnet fork, use mocks
            borrowerOperations = address(new Accounts());
            mockOracle = new ChainlinkOracleMock();

            // Set initial price
            mockOracle.setLatestRoundId(1);
            mockOracle.setPrevRoundId(1);
            mockOracle.setPrice(INITIAL_CBBTC_PRICE);
            mockOracle.setDecimals(8);
            mockOracle.setUpdateTime(block.timestamp);

            // Deploy with mock
            cbbtcPriceFeed = new CBBTCPriceFeed(
                address(mockOracle),
                CBBTC_USD_STALENESS_THRESHOLD,
                borrowerOperations
            );
        }
    }

    // Test 1: Constructor initializes correctly
    function testConstructorInitialization() public {
        assertEq(address(cbbtcPriceFeed.borrowerOperations()), borrowerOperations);
        assertEq(uint256(cbbtcPriceFeed.priceSource()), uint256(IMainnetPriceFeed.PriceSource.primary));
    }

    // Test 2: fetchPrice returns valid price
    function testFetchPriceSuccess() public {
        (uint256 price, bool oracleFailure) = cbbtcPriceFeed.fetchPrice();

        assertGt(price, 0, "Price should be greater than 0");
        assertFalse(oracleFailure, "Oracle should not have failed");

        // Price should be scaled to 18 decimals (from 8 decimals)
        // Expect price in range $10k - $200k (reasonable BTC price range)
        assertGt(price, 10000e18, "Price should be > $10k");
        assertLt(price, 200000e18, "Price should be < $200k");
    }

    // Test 3: fetchRedemptionPrice returns same as fetchPrice
    function testFetchRedemptionPrice() public {
        (uint256 normalPrice, bool normalFailure) = cbbtcPriceFeed.fetchPrice();
        (uint256 redemptionPrice, bool redemptionFailure) = cbbtcPriceFeed.fetchRedemptionPrice();

        assertEq(normalPrice, redemptionPrice, "Redemption price should equal normal price");
        assertEq(normalFailure, redemptionFailure, "Failure flags should match");
    }

    // Test 4: Oracle failure switches to lastGoodPrice (mock only)
    function testOracleFailureFallback() public {
        // Skip if using real mainnet fork
        if (address(mockOracle) == address(0)) {
            vm.skip(true);
            return;
        }

        // First, get a good price
        (uint256 goodPrice,) = cbbtcPriceFeed.fetchPrice();
        assertGt(goodPrice, 0, "Should have valid initial price");

        // Simulate oracle failure by breaking it
        mockOracle.setPrice(0); // Invalid price

        // Fetch price again - should use lastGoodPrice
        (uint256 fallbackPrice, bool oracleFailure) = cbbtcPriceFeed.fetchPrice();

        assertTrue(oracleFailure, "Oracle failure should be detected");
        assertEq(fallbackPrice, goodPrice, "Should return last good price");
        assertEq(
            uint256(cbbtcPriceFeed.priceSource()),
            uint256(IMainnetPriceFeed.PriceSource.lastGoodPrice),
            "Should switch to lastGoodPrice source"
        );
    }

    // Test 5: Stale oracle data triggers fallback (mock only)
    function testStaleOracleTriggersFallback() public {
        // Skip if using real mainnet fork
        if (address(mockOracle) == address(0)) {
            vm.skip(true);
            return;
        }

        // Get initial good price
        (uint256 goodPrice,) = cbbtcPriceFeed.fetchPrice();

        // Make oracle data stale (older than 24 hours)
        vm.warp(block.timestamp + CBBTC_USD_STALENESS_THRESHOLD + 1);

        // Fetch price - should detect staleness
        (uint256 fallbackPrice, bool oracleFailure) = cbbtcPriceFeed.fetchPrice();

        assertTrue(oracleFailure, "Stale oracle should trigger failure");
        assertEq(fallbackPrice, goodPrice, "Should return last good price");
    }

    // Test 6: Price updates correctly when oracle updates (mock only)
    function testPriceUpdatesWithOracle() public {
        // Skip if using real mainnet fork
        if (address(mockOracle) == address(0)) {
            vm.skip(true);
            return;
        }

        // Get initial price
        (uint256 initialPrice,) = cbbtcPriceFeed.fetchPrice();

        // Update oracle to new price
        int256 newPrice = 70000e8; // $70,000
        mockOracle.setPrice(newPrice);
        mockOracle.setUpdateTime(block.timestamp);
        mockOracle.setLatestRoundId(2);

        // Fetch new price
        (uint256 updatedPrice, bool oracleFailure) = cbbtcPriceFeed.fetchPrice();

        assertFalse(oracleFailure, "Oracle should not fail");
        assertGt(updatedPrice, initialPrice, "Price should have increased");
        assertEq(updatedPrice, uint256(newPrice) * 1e10, "Price should be scaled to 18 decimals");
    }

    // Test 7: lastGoodPrice is stored correctly
    function testLastGoodPriceStorage() public {
        (uint256 price,) = cbbtcPriceFeed.fetchPrice();
        uint256 storedLastGoodPrice = cbbtcPriceFeed.lastGoodPrice();

        assertEq(price, storedLastGoodPrice, "lastGoodPrice should equal fetched price");
        assertGt(storedLastGoodPrice, 0, "lastGoodPrice should be set");
    }

    // Test 8: Multiple consecutive fetchPrice calls work correctly
    function testMultipleFetchPriceCalls() public {
        (uint256 price1, bool failure1) = cbbtcPriceFeed.fetchPrice();
        (uint256 price2, bool failure2) = cbbtcPriceFeed.fetchPrice();
        (uint256 price3, bool failure3) = cbbtcPriceFeed.fetchPrice();

        assertFalse(failure1, "First fetch should succeed");
        assertFalse(failure2, "Second fetch should succeed");
        assertFalse(failure3, "Third fetch should succeed");

        // Prices should be consistent if oracle hasn't updated
        assertEq(price1, price2, "Consecutive prices should match");
        assertEq(price2, price3, "Consecutive prices should match");
    }

    // Test 9: Price decimals conversion (8 decimals -> 18 decimals)
    function testPriceDecimalsConversion() public {
        // Skip if using real mainnet fork
        if (address(mockOracle) == address(0)) {
            vm.skip(true);
            return;
        }

        // Set oracle price with 8 decimals
        int256 oraclePrice = 50000e8; // $50,000 with 8 decimals
        mockOracle.setPrice(oraclePrice);
        mockOracle.setDecimals(8);
        mockOracle.setUpdateTime(block.timestamp);

        (uint256 price,) = cbbtcPriceFeed.fetchPrice();

        // Should be scaled to 18 decimals
        uint256 expectedPrice = uint256(oraclePrice) * 1e10;
        assertEq(price, expectedPrice, "Price should be scaled from 8 to 18 decimals");
    }

    // Test 10: Contract reverts if oracle already failed at construction
    function testConstructorRevertsOnFailedOracle() public {
        // Skip if using real mainnet fork
        if (address(mockOracle) == address(0)) {
            vm.skip(true);
            return;
        }

        // Create a broken oracle
        ChainlinkOracleMock brokenOracle = new ChainlinkOracleMock();
        brokenOracle.setPrice(0); // Invalid price
        brokenOracle.setDecimals(8);
        brokenOracle.setUpdateTime(block.timestamp);

        // Should revert with assertion failure
        vm.expectRevert();
        new CBBTCPriceFeed(
            address(brokenOracle),
            CBBTC_USD_STALENESS_THRESHOLD,
            borrowerOperations
        );
    }
}
