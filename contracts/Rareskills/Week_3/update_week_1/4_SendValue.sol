// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Value {
    uint256 public tokenBalance;
    address public owner;

    modifier ownerOnly() {
        owner = msg.sender;
        _;
    }

    constructor() {
        tokenBalance = 0;
    }

    function addValue() public payable {
        tokenBalance = tokenBalance + (msg.value / 10);
    }

    function getTokenBalance() public view returns (uint256) {
        return tokenBalance;
    }
}
