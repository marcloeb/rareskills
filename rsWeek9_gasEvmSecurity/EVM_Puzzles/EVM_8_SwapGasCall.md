# EVM_Puzzles 08: SWAP, GAS and CALL

Help used: https://www.evm.codes

```apache
00      36        CALLDATASIZE
01      6000      PUSH1 00
03      80        DUP1
04      37        CALLDATACOPY
05      36        CALLDATASIZE
06      6000      PUSH1 00
08      6000      PUSH1 00
0A      F0        CREATE
0B      6000      PUSH1 00
0D      80        DUP1
0E      80        DUP1
0F      80        DUP1
10      80        DUP1
11      94        SWAP5
12      5A        GAS
13      F1        CALL
14      6000      PUSH1 00
16      14        EQ
17      601B      PUSH1 1B
19      57        JUMPI
1A      FD        REVERT
1B      5B        JUMPDEST
1C      00        STOP
```

The eight Puzzle introduces SWAP, GAS and Call. First the instruction copies the calldata to memory slot 0. Then a contract is created from memory slot 0. Then a message call to this contract is initiated. The return value of the contract needs to be 0.

What does a return value of 0 from a call to a contract mean? It means failure of the call, unsuccessful.

How to create the calldata for a smart contract that a call to it returns 0?

From the previous exercise I know, the return value from the calldata will be the new contract code.

What Upcode will produce a failure? I use here the stop upcode of 0. This makes my upcode

0x60FD6000526001601ff3

- 60 - push1
- FD - value FD -> REVERT
- 60 - push1
- 00 - value 00 -> Storage slot 0
- 52 - mstore
- 60 - push1
- 01 - value 01 -> get one byte
- 60 - push1
- 1f - value 1f -> from position 1f = last byte
- f3 - return

I could have used any upcode like add or substract that misses enough stack input, that would revert as well.

DONE 🎉️🎉️🎉️

I am proud I solved this exercise with deduction from the previous one myself!!!!
