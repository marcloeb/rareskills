# EVM_Puzzles 03: Calldatasize

Help used: https://www.evm.codes

```apache
00      36      CALLDATASIZE
01      56      JUMP
02      FD      REVERT
03      FD      REVERT
04      5B      JUMPDEST
05      00      STOP
```

The third Puzzle introduces CALLDATASIZE. This gets the byte size of the calldata. The prompt asks for the calldata. The input is in HEX -> One Hex number represent 4 bits, 2 Hex numbers make 8 bits or 1 byte. Therefore a Calldata like 0xffffffff will give 4 bytes and that will point to the JUMPDEST at line 4.

Done.
