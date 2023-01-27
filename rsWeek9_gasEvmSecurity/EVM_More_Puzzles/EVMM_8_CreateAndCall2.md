# EVM_More_Puzzles 08: CreateAndCall2

Help used: https://www.evm.codes

```apache
00      34        CALLVALUE         -> [callvalue]
01      15        ISZERO            -> [0/1]
02      19        NOT               -> bitwise flip, will always be non zero
03      6007      PUSH1 07
05      57        JUMPI             -> will jump no matter what happens
06      FD        REVERT
07      5B        JUMPDEST
08      36        CALLDATASIZE
09      6000      PUSH1 00
0B      6000      PUSH1 00
0D      37        CALLDATACOPY      -> copy calldata to memory
0E      36        CALLDATASIZE
0F      6000      PUSH1 00
11      6000      PUSH1 00
13      F0        CREATE            -> create a new contract with calldata
14      47        SELFBALANCE
15      6000      PUSH1 00
17      6000      PUSH1 00
19      6000      PUSH1 00
1B      6000      PUSH1 00
1D      47        SELFBALANCE       -> [balance, 00, 00, 00, 00, balance,contractAddress]
1E      86        DUP7              -> [contractAddress, balance, 00, 00, 00, 00, balance,contractAddress]
1F      5A        GAS               -> [gas, contractAddress, balance, 00, 00, 00, 00, balance,contractAddress]
20      F1        CALL              -> [1, balance,contractAddress]
21      6001      PUSH1 01
23      14        EQ
24      6028      PUSH1 28
26      57        JUMPI             -> call must be success
27      FD        REVERT
28      5B        JUMPDEST
29      47        SELFBALANCE       -> [balance,balance,contractAddress]
2A      14        EQ                -> the balance from the beginning must be the same as after
2B      602F      PUSH1 2F
2D      57        JUMPI
2E      FD        REVERT
2F      5B        JUMPDEST
30      00        STOP
```

The eigth of more Puzzle introduces changing values between a newly created contract and a new contract. The first jumpi will always be true, no matter what callvalue in wei I enter. The second large part creates a new contract and calls the contract with all the value of the contractbalance.

The last condition asks that the balance of the contract before sending all to the new contract is again the same as after the sending. That can only be true if the new contract sends the eth back. The task is to create the calldata that fullfills this. As usual we need to write the solution to memory and return the value -> this will be the new contract.

This was a tough **MF** for me! I suffered generating the byte code. Things to remember:

1. The code of transferring back the eth is just a call upcode with all the operands
2. A create upcode needs a return value. A return value needs to be stored in memory first. with the return upcode I pass the offset and size of the return value

So first the call 600160005260016000808047335af1:

- 6001 -> Push1 01
- 6000 -> Push1 00
- 52 -> MStore, this is the sucess value for the call
- 6001 -> Push1 01, size of return value
- 6000 -> Push1 00, memory position (offset) of return value
- 80 -> Duplicate 0, arg size
- 80 -> Duplicate 0, arg memory position (offset)
- 47 -> Selfbalance
- 33 -> Caller
- 5a -> Gas
- f1 -> Call

Hey and now the second part of the return value

6e xxx 600052600f6011f3

- 6e xxx -> Push15 600160005260016000808047335af1 pushes our bytecode above to the stack
- 6000 -> Push1 00, memory position
- 52 -> MStore of our value at position 0
- 600f -> Push1 0f, size of our bytecode
- 6011 -> Push1 11, offset of our bytecode
- f3 -> Return the value

And thats it!!!!!!!!!!!

Hurra.
