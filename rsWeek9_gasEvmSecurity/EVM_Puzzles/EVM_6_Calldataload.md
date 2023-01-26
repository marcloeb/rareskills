# EVM_Puzzles 06: Calldataload

Help used: https://www.evm.codes

```apache
00      6000      PUSH1 00
02      35        CALLDATALOAD
03      56        JUMP
04      FD        REVERT
05      FD        REVERT
06      FD        REVERT
07      FD        REVERT
08      FD        REVERT
09      FD        REVERT
0A      5B        JUMPDEST
0B      00        STOP
```

The sixth Puzzle introduces CALLDATALOAD. This seems easy at first - load the calldata with a (0xa). But this will not work, because this will represent "0xa000000000000000000000000000000000000000000000000000000000000000", which is wrong. The correct input is "0x000000000000000000000000000000000000000000000000000000000000000a"

Done.
