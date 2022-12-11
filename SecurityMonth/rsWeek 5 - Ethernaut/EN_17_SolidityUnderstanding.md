# Ethernaut 17: Recovery - understanding Interfaces

## The Task Intro

Contract addresses are deterministic and are calculated by `keccak256(address, nonce)` where the `address` is the address of the contract (or ethereum address that created the transaction) and `nonce` is the number of contracts the spawning contract has created (or the transaction nonce, for regular transactions).

Because of this, one can send ether to a pre-determined address
(which has no private key) and later create a contract at that address
which recovers the ether. This is a non-intuitive and somewhat secretive
way to (dangerously) store ether without holding a private key.

An interesting [blog post](https://swende.se/blog/Ethereum_quirks_and_vulns.html) by Martin Swende details potential use cases of this.

If you're going to implement this technique, make sure you don't miss the nonce, or your funds will be lost forever.

## The Task Code

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recovery {

  //generate tokens
  function generateToken(string memory _name, uint256 _initialSupply) public {
    new SimpleToken(_name, msg.sender, _initialSupply);

  }
}

contract SimpleToken {

  string public name;
  mapping (address => uint) public balances;

  // constructor
  constructor(string memory _name, address _creator, uint256 _initialSupply) {
    name = _name;
    balances[_creator] = _initialSupply;
  }

  // collect ether in return for tokens
  receive() external payable {
    balances[msg.sender] = msg.value * 10;
  }

  // allow transfers of tokens
  function transfer(address _to, uint _amount) public {
    require(balances[msg.sender] >= _amount);
    balances[msg.sender] = balances[msg.sender] - _amount;
    balances[_to] = _amount;
  }

  // clean up after ourselves
  function destroy(address payable _to) public {
    selfdestruct(_to);
  }
}
```

## The Solution

Here as well with this description I did not know where to start. So I went to etherscan, realized that the recovery contract created a SimpleToken Contract and was able to get its address.

From there it was as easy as call the destroy function to receive the ether. I did that through remix.

While I was reading the intro and creating the documentation, I became aware that I should read the full intro ;-) So I found out that the address is generated with a nonce and in a hardhat test I can predict the address, worked beautifully with these lines below!

```apache
const { getContractAddress } = require('@ethersproject/address');

const lostTokenAddress = getContractAddress({
  from: recovery.address,
   nonce: 1,
});
```
