# EVM_More_Puzzles 03: Delegatecall and Storage Slots

Help used: https://www.evm.codes

```apache
00      36        CALLDATASIZE
01      6000      PUSH1 00
03      6000      PUSH1 00
05      37        CALLDATACOPY      -> copy calldata to mem
06      36        CALLDATASIZE
07      6000      PUSH1 00
09      6000      PUSH1 00
0B      F0        CREATE            -> create a contract
0C      6000      PUSH1 00
0E      80        DUP1
0F      80        DUP1
10      80        DUP1
11      93        SWAP4
12      5A        GAS
13      F4        DELEGATECALL     ->Delegate call
14      6005      PUSH1 05
16      54        SLOAD            -> Load from storage slot 05
17      60AA      PUSH1 AA
19      14        EQ               -> storage slot needs to have the value AA in it
1A      601E      PUSH1 1E
1C      57        JUMPI
1D      FE        INVALID
1E      5B        JUMPDEST
1F      00        STOP
```

The third of more Puzzle introduces to Delegate Call and Storage slots. I need to give the puzzle the calldata that saves a value in storage slot 5.

60AA600555 -> this pushes the value AA to the stack, then the storage position 05 and saves it to storage. This does not work as a contract it seems. So I fall back to the solution I created before.

6460AA6005556000526005601BF3 -> To make create work I need to push the solution on the stack and store it to memory location 0, then define the size and offset of the return value, followed by the return upcode.

-> the contract code is in the return value.

-> strage strage -> but just by design and to remember.

6460AA6005556000526005601BF3 means:

- 64 Push5 bytes
- 60AA600555 My solution storing AA at slot 5
- 60 Push1
- 00 Memory position 0
- 52 Mstore
- 60 Push1
- 05 Bytes to grab from return value
- 1B Offset to grab return value
- F3 Return upcode

DONE!\*\*\*\*
