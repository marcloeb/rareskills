# EVM_Puzzles 05: JUMPI

Help used: https://www.evm.codes

```apache
00      34          CALLVALUE
01      80          DUP1
02      02          MUL
03      610100      PUSH2 0100
06      14          EQ
07      600C        PUSH1 0C
09      57          JUMPI
0A      FD          REVERT
0B      FD          REVERT
0C      5B          JUMPDEST
0D      00          STOP
0E      FD          REVERT
0F      FD          REVERT
```

The fifth Puzzle introduces DUP1, MUL, PUSH, EQ are self explanatory. Jumpi was new because it needs 2 arguments, first the jump address and second the condition.
In this case EQ must give 1. To make this true the value must be equal to 0x100, which equals 256. The square root of 256 is 16, which makes 16 our imput and solution.

Done 🎉️ .
