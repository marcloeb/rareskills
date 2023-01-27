# EVM_More_Puzzles 02: Create and Call

Help used: https://www.evm.codes

```apache
00      36        CALLDATASIZE
01      6000      PUSH1 00
03      6000      PUSH1 00
05      37        CALLDATACOPY       -> move calldata to memory
06      36        CALLDATASIZE
07      6000      PUSH1 00
09      6000      PUSH1 00
0B      F0        CREATE             -> create smart contract, leaves an address on the stack
0C      6000      PUSH1 00
0E      80        DUP1
0F      80        DUP1
10      80        DUP1
11      80        DUP1
12      94        SWAP5              -> moves the address on the second position
13      5A        GAS
14      F1        CALL               -> call the contract, receive something back
15      3D        RETURNDATASIZE     -> measure the size of the value returned
16      600A      PUSH1 0A           -> The returndatasize must be 10
18      14        EQ
19      601F      PUSH1 1F
1B      57        JUMPI
1C      FE        INVALID
1D      FE        INVALID
1E      FE        INVALID
1F      5B        JUMPDEST
20      00        STOP
```

The second of more Puzzle forces the calldata to return a value of the size of 10 bytes. As input the calldata is asked.
New fo me was that using https://www.evm.codes/playground?fork=merge I realized this can take Yul, Solidity, Bytecode and Mnemonic. So choosing bytecode for this exercise was necessary. This happend because I was using from my research for EVM Puzzle exercise 7 an existing solution and engineered backwards.

I first tried to use the solution from exercise 7, but this failed:
69FFFFFFFFFFFFFFFFFFFF600052600a6016f3 -> this places 10 bytes into memory, defines the offset and size of the return value and returns it.

The reason is that the return value offset is set to 0, meaning I do not have to give something back, I need to write 10 bytes to the 0 slot
69FFFFFFFFFFFFFFFFFFFF600052 -> but this does not work either.

So I realized that instead of giving 10 bytes of ff back, I will return the value 0a - 600a6000f3

- 60 Push1
- 0a value
- 60 Push1
- 00 storage slot
- f3 return

And this needs to be stored in storage slot 0: 64600A6000F36000526005601BF3

- 64 Push5
- 600a6000f3 Value from before
- 60 Push1
- 52 Mstore
- 05 5 bytes back
- 1B offset of
