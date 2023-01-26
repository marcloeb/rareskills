# EVM_Puzzles 01: Jump

Help used: https://www.evm.codes

```apache
00      34      CALLVALUE
01      56      JUMP
02      FD      REVERT
03      FD      REVERT
04      FD      REVERT
05      FD      REVERT
06      FD      REVERT
07      FD      REVERT
08      5B      JUMPDEST
09      00      STOP
```

The first Puzzle reads the callvalue = msg.value and uses this value to jump to a valid jump destitnation. In our case we need to send 8 ether.

Puzzle solved, that was easy - I feel pushed to be motivated! But thats okay 😄.
