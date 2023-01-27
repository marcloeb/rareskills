# EVM_Puzzles 10: Multiple Upcodes

Help used: https://www.evm.codes

```apache
00      38          CODESIZE
01      34          CALLVALUE
02      90          SWAP1
03      11          GT              -> Calldatasize must be grater than callvalue
04      6008        PUSH1 08
06      57          JUMPI
07      FD          REVERT
08      5B          JUMPDEST
09      36          CALLDATASIZE
0A      610003      PUSH2 0003
0D      90          SWAP1
0E      06          MOD            -> calldatasize mod 3
0F      15          ISZERO         -> needs to be zero
10      34          CALLVALUE
11      600A        PUSH1 0A        -> callvalue + a must equal hex 19
13      01          ADD
14      57          JUMPI
15      FD          REVERT
16      FD          REVERT
17      FD          REVERT
18      FD          REVERT
19      5B          JUMPDEST
1A      00          STOP
```

The tenth Puzzle introduces some mathematics which makes the calculation more difficult. Input requested are the wei value and the calldata. I solve this puzzle by abstracting it:

- Calldatasize > callvalue
- Calldatasize mod 3 is 0
- Callvalue + 10 equals 25

That sets the callvalue to 15. The calldatasize must be larger than 15, the next higher 0 mod 3 from 15 is 18. so my calldatasize is 0xffffffffffffffffffffffffffffffffffff (18f).

Done and finished!!! I move on to the more evm puzzles.
