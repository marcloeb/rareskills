# Ehternaut 18: Magic Number

assembly

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MagicNum {

  address public solver;

  constructor() {}

  function setSolver(address _solver) public {
    solver = _solver;
  }

  /*
    ____________/\\\_______/\\\\\\\\\_____
     __________/\\\\\_____/\\\///////\\\___
      ________/\\\/\\\____\///______\//\\\__
       ______/\\\/\/\\\______________/\\\/___
        ____/\\\/__\/\\\___________/\\\//_____
         __/\\\\\\\\\\\\\\\\_____/\\\//________
          _\///////////\\\//____/\\\/___________
           ___________\/\\\_____/\\\\\\\\\\\\\\\_
            ___________\///_____\///////////////__
  */
}
```

Here we are again with the second last ethernaut exercise of this week. Happy :-). The task is give an address to the solver that gives back the number 42 and has not more than 10 upcodes.

Doing so in solidity is a fail, the upcodes are way too long. I tried a hybrid approach but failed.

So I went all back to upcodes and here again the contract initialization and the contract code itself - here the contract code first: 602A6000526001601ff3

- 602a Push1 2a (which equals 42)
- 6000 Push1 00 (Memory location)
- 52 Store
- 6001 Push 00 (memory size)
- 601f Push 1f (memory offset)
- f3 Return

Second I need a initalization code of the smart contract:

- 69602a60005260206000f3 Push10 69602a60005260206000f3 (my contract code)
- 6000 Push1 00 (memory location)
- 52 MStore
- 600a Push1 0A (size of memory = 10)
- 6016 Push1 16 (offset in memory, values from pos 22)
- f3 Return

`69`**`602a60005260206000f3`** `600052600a6016f3`

Thats the bytecode. The problem is how to deploy? I tried with a hybrid approach in remix, too. But failed again. The esiest way ist do it directly in ethernaut console with this code:

```apache
await ethereum.request({
  method: 'eth_sendTransaction',
  params: [{
    from: (await ethereum.request({ method: 'eth_requestAccounts' }))[0],
    data: '0x69602a60005260206000f3600052600a6016f3'
  }]
});

// followed by
await contract.setSolver('[Address received from transaction]');
```

Done 🎉️
