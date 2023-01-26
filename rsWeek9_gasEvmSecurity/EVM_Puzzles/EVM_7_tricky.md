# EVM_Puzzles 07: Tricky - CALLDATASIZE, CALLDATACOPY, CREATE, EXTCODESIZE

Help used: https://www.evm.codes

```apache
00      36        CALLDATASIZE
01      6000      PUSH1 00
03      80        DUP1
04      37        CALLDATACOPY
05      36        CALLDATASIZE
06      6000      PUSH1 00
08      6000      PUSH1 00
0A      F0        CREATE            -> returns address
0B      3B        EXTCODESIZE       -> extCodeSize must be 01 byte -> calldatasize must be one byte
0C      6001      PUSH1 01
0E      14        EQ
0F      6013      PUSH1 13
11      57        JUMPI
12      FD        REVERT
13      5B        JUMPDEST
14      00        STOP
```

The seventh Puzzle introduces CALLDATASIZE, CALLDATACOPY, CREATE, EXTCODESIZE. It is marked as a tricky exercise.
And well it had a tricky part! The start was not that difficult - we get the calldatasize, push 00 to the stack and duplicate it and make a calldatacopy. This copies the calldata to the memmory - 3 values are removed from the stack and none added. Then calldatasize is called again followed by pushing twice 00. Here create is called, that creates a smart contract and return its address. Obviously the extcodesize is must be 1 byte.

Here is the tricky part: how to form the calldata that it generates a smart contract with one byte returning from extcodesize?

Here I needed to research. The solution I found pushes one to the stack and stores this value into memory slot 0. Then it gives back the return value of 1 byte back at the position 1F.

0x60016000526001601ff3
60 - push1
01 - value 01
60 - push1
00 - value 00
52 - mstore
60 - push1
01 - value 01
60 - push1
1f - value 1f
f3 - return

This calldata stores the value 01 to memory storage slot 0 and returns 1 byte back from offset 1f.

Solved, but I needed research, extcodesize work was not documented.
