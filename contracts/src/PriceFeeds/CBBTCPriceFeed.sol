// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "./MainnetPriceFeedBase.sol";

// import "forge-std/console2.sol";

contract CBBTCPriceFeed is MainnetPriceFeedBase {
    constructor(address _cbBtcUsdOracleAddress, uint256 _cbBtcUsdStalenessThreshold, address _borrowerOperationsAddress)
        MainnetPriceFeedBase(_cbBtcUsdOracleAddress, _cbBtcUsdStalenessThreshold, _borrowerOperationsAddress)
    {
        _fetchPricePrimary();

        // Check the oracle didn't already fail
        assert(priceSource == PriceSource.primary);
    }

    function fetchPrice() public returns (uint256, bool) {
        // If branch is live and the primary oracle setup has been working, try to use it
        if (priceSource == PriceSource.primary) return _fetchPricePrimary();

        // Otherwise if branch is shut down and already using the lastGoodPrice, continue with it
        assert(priceSource == PriceSource.lastGoodPrice);
        return (lastGoodPrice, false);
    }

    function fetchRedemptionPrice() external returns (uint256, bool) {
        // Use same price for redemption as all other ops in CBBTC branch
        return fetchPrice();
    }

    //  _fetchPricePrimary returns:
    // - The price
    // - A bool indicating whether a new oracle failure was detected in the call
    function _fetchPricePrimary() internal returns (uint256, bool) {
        assert(priceSource == PriceSource.primary);
        (uint256 cbBtcUsdPrice, bool cbBtcUsdOracleDown) = _getOracleAnswer(ethUsdOracle);

        // If the CBBTC-USD Chainlink response was invalid in this transaction, return the last good CBBTC-USD price calculated
        if (cbBtcUsdOracleDown) return (_shutDownAndSwitchToLastGoodPrice(address(ethUsdOracle.aggregator)), true);

        lastGoodPrice = cbBtcUsdPrice;
        return (cbBtcUsdPrice, false);
    }
}
