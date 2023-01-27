# EVM_More_Puzzles 05: Msize

Help used: https://www.evm.codes

```apache
00      6020      PUSH1 20
02      36        CALLDATASIZE
03      11        GT                -> calldatasize needs to be grater than 0x20
04      6008      PUSH1 08
06      57        JUMPI
07      FD        REVERT
08      5B        JUMPDEST
09      36        CALLDATASIZE
0A      6000      PUSH1 00
0C      6000      PUSH1 00
0E      37        CALLDATACOPY      -> copy the calldata
0F      36        CALLDATASIZE      -> []
10      59        MSIZE             -> size of active momory
                                    (What this instruction tracks is the highest offset that was accessed in the current execution)
11      03        SUB
12      6003      PUSH1 03          msize - calldatasize needs to be equal 3,
14      14        EQ
15      6019      PUSH1 19
17      57        JUMPI
18      FD        REVERT
19      5B        JUMPDEST
1A      00        STOP
```

The fifth of more Puzzle introduces Msize. It gives the active highest active memory back, the highest offset that was accessed in the current execution - it always works with full words, not correct bytes. If I add 61 bytes to memory, mzise will return 2x32 = 64 bytes.

My solution is:

FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF (122 F)

Haha, another done, this time in about 20min. Not that quick, not that fast ;-)
