# EVM_More_Puzzles 07: Gas used

Help used: https://www.evm.codes

```apache
00      5A        GAS            2 gas
01      34        CALLVALUE      2 gas
02      5B        JUMPDEST       1 gas
03      6001      PUSH1 01       3 gas          -> [01, Callvalue, Gas]
05      90        SWAP1          3 gas          -> [Callvalue, 01, Gas]
06      03        SUB            3 gas                                                    -> result needs to be 0
07      80        DUP1           3 gas          -> [Subresult, Subresult, Gas]
08      6000      PUSH1 00       3 gas          -> [00, Subresult, Subresult, Gas]
0A      14        EQ             3 gas
0B      6011      PUSH1 11       3 gas
0D      57        JUMPI         10 gas                                                    -> if it fails execution continues
0E      6002      PUSH1 02       3 gas
10      56        JUMP           8 gas                                                   -> jump back to position 02
11      5B        JUMPDEST       1 gas
12      5A        GAS            2 gas          -> [GasNew, Subresult, Gas]
13      90        SWAP1                         -> [Subresult, GasNew, Gas]
14      91        SWAP2                         -> [Gas, GasNew, Subresult]
15      03        SUB                           -> [Gasused, Subresult]
16      60A6      PUSH1 A6                      -> [A6, Gasused, Subresult]
18      14        EQ
19      601D      PUSH1 1D
1B      57        JUMPI
1C      FD        REVERT
1D      5B        JUMPDEST
1E      00        STOP
```

The seventh of Puzzle introduces a gas used puzzle. First I needed to understand the structure. There is a loop that exist with the condition callvalue - 01 = 0. If 0 wei is given, then the loop runs until there is no more gas left. At the beginning the gas is mesured and after the loop is exited the gas is mesured as well.

The last condition to be met is that the gas used needs to be 0xA6 = 166. To achive this I need to know how much gas is used in one iteration and all additional iterations

- Before the loop: 2+2+1 = 5
- The loop: 1+3+3+3+3+3+3+3+10+3+8 = 43
- last loop: 43-11 (Push and jump do not happen) = 32

3\*43 = 129 + 5 + 32 = 166

The substraction is callvalue - 01. Therefore I need to give the value 4 as a solution.

DONI :-) PUh, that took some time.
