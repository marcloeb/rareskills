# Ehternaut 13: Gatekeeper One

passing gas to a smart contract

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {

  address public entrant;

  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    require(gasleft() % 8191 == 0);
    _;
  }

  modifier gateThree(bytes8 _gateKey) {
      require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
      require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
      require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }
}

```

## Well well well

This was a really nasty task, that I had hours to solve. Again, this was my mistake not to see the obvious, but this seems how we learn. It looks easy at the beginning. There are 3 modifier that are applied to the enter function. We need to get entrance through the gates, the gates are the modifiers. This anaolgy is nice. So far so good.

### Gate 1

The first gate is obvious, we cannot call that contract from an EOA, we need to go through a smart contract. After being in vacation I was reluctant opening my hardhat environment, because it needs time. As well remix seems to be needed, too. But its a good practice to reuse and with every usage I get more productive.

So I set up a hardhat project and copied the GateKeeperOne to this environment and added some helper functions each modifier alone. Worked great.

### Gate 3

My feelings were to attack gate three first, so I checked all the conditions for several values:

````apache
       console.logBytes8(_gateKey);
        console.log("Casting Gatekey from 64 to 32/16 need to be the same");
        console.log("uint64(_gateKey) %s", uint64(_gateKey));
        console.log("uint32(uint64(_gateKey)) %s", uint32(uint64(_gateKey)));
        console.log("uint16(uint64(_gateKey)) %s", uint16(uint64(_gateKey)));
        console.log("-----------------------------------------");
        console.log("Casting Gatekey from 64 to 32 needs NOT to be the same as uint64 from Gatekey");
        console.log("uint64(_gateKey) %s", uint64(_gateKey));
        console.log("uint32(uint64(_gateKey)) %s", uint32(uint64(_gateKey)));
        console.log("-----------------------------------------");
        console.log("Casting from address to uint160 to uint16 needs to be the same as casting the gateKey to uint64 to uint32");
        console.log("uint16(uint160(tx.origin)) %s", uint16(uint160(tx.origin)));
        console.log("uint32(uint64(_gateKey)) %s", uint32(uint64(_gateKey)));
```
````

Downcasting is a difficult task, because data are lost. And important, the rules for ints and bytes are different (https://medium.com/coinmonks/learn-solidity-lesson-22-type-casting-656d164b9991):

> Consider the 16-bit binary value 0000101000001001. In decimal it is written as 2569. Now let’s do an explicit conversion to** \***uint8\* . What do you think should be the result?
>
> Only the last 8 bits are kept. The value 0000101000001001 is converted to 00001001, which is 9 in decimal. When converting from a larger integer type to a smaller one, the bits on the right are kept while the bits on the left are lost.
>
> In converting bytes types, the opposite occurs. When a larger byte type is converted to a smaller type, the first bytes are kept and the last ones are lost. When converting a smaller byte to a larger byte, null bytes are appended to the right.

Here we speak only about downcasting of integers - meaning the last bytes are kept. Looking at the log, this means for the first gate, casting to 32 means a loss of 4 bytes and casting to uint16 a loss of 6 bytes. That these values can be the same, we can only add 2 bytes of data.

The second gate asks that the uint64 and uint32 are different. This can be easily achived with a value above the first 4 bytes. Eg 0x1000000000A3BA (=8 bytes). This would be different than 0x0000000000A3BA.

The third gate asks for the last two bytes from the address are equal to the last 4 bytes of the gatekey. Here we need to take the last 4 hex numbers from the address.

For the Address 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 we would use only ddC4 (2bytes) and to satisfy the second gate we would add 6 bytes with one number different from byte 5-7. Eg 0x1000000000ddC4

### Gate 2

And here the dreadful gate 2. Casting was enough difficult, but here the issue was my setup. First was the question how to measure the needed gas and how ot pass it to the function. That not that difficult, in the Exploit contract I added an attack function and added beside the gatekey a gaslimit parameter. The problem was how to call it? Hari and Naveen were talking about bruteforcing, meaning to iterate until you find. Why not. The code was not difficult, 8191 iterations needed to find mod 0.

And here the problems started. Wrong number, transaction failed. I tried to manually debug in Remix, but mehh no tracecode for the called contract Gatekeeper - if there were I could move to the gas upcode and see how far it is away from a mod 0 result. So I switched back to hardhat. I realized that the compiler needs to be set similar to the contract, so I went to ethernet and checked the compiler version and the evmversion, set it accordingly. Again transaction failed. One more thing the optimizer needed to be enabled with 1000 runs. Transaction failed....

Something is missing... Back to Remix and try in the local environment not in Görli, and debugging is possible again, so I was able to see how much gas was left after the gas upcode was hit. As well here I set the compiler to 0.8.12 and evmversion to london to match the current contract, as well the optimizer with the number of 1000 runs. YEAh, the number worked, transaction successful! But what went worng in Hardhat? It was that I changed the code of the gatekeeper!! This added of course upcodes that were not there in the deployed original.

## Final thoughs

This was a painful learning, casting I did not know about much, as well calculating gas, then relearning Remix and Hardhat after a break. But the lessons learned about casting, gas calculation and Hardhat and remix - I will not forget.
