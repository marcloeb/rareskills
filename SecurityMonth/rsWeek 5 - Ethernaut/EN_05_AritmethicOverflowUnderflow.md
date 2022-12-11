# Ethernaut 05: Token - under/overflow

Ethereum works with integer only. Additionally Solidity did not know overflow protection of its values. After passing the max value (overflow), solidity counts again from the begining or the other way around (underflow).

## The Task Intro

The goal of this level is for you to hack the basic token contract below.

You are given 20 tokens to start with and you will beat the level if
you somehow manage to get your hands on any additional tokens.
Preferably a very large amount of tokens.

## The Task Code

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Token {

  mapping(address => uint) balances;
  uint public totalSupply;

  constructor(uint _initialSupply) public {
    balances[msg.sender] = totalSupply = _initialSupply;
  }

  function transfer(address _to, uint _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
}
```

## The Solution

The Transfer function require statemment evaluates to a uint, therefore we can let the require statement underflow with a value of:

```apache
uint256 public underflow = 2 ** 256 - 1 -20;
```

With this I gain a very large amount of tokens.
