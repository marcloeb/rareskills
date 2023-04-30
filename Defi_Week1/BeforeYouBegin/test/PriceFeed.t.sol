// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import {PriceFeed} from "contracts/PriceFeed.sol";

contract PriceFeedTest is Test {
    PriceFeed priceFeed;

    function setUp() public {
        priceFeed = new PriceFeed();
    }

    function testGetLatestEthPriceInUsd() public view {
        int price = priceFeed.getLatestEthPriceInUsd();
        console.log("price: ", uint(price));
        //        assertEq(price, 100000000000);
    }
}
