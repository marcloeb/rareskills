// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";

contract PriceFeed {
    AggregatorV3Interface internal priceFeed;

    constructor() {
        // sepolia price feed.
        priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    function getLatestEthPriceInUsd() external view returns (int) {
        (uint80 roundId, int256 price, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        console.log("price: ", uint(price));
        return price;
    }
}
