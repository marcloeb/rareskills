// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
contract Value {
    uint256 public tokenBalance;
    
    constructor()  {
        tokenBalance = 0;
    }
    
    function addValue() payable public {
        tokenBalance = tokenBalance + (msg.value/10);
    } 
    
    function getTokenBalance() view public returns (uint256) {
        return tokenBalance;
    }
}