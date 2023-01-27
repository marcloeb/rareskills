# EVM_Puzzles 09: Two Jumpis

Help used: https://www.evm.codes, https://www.evm.codes/playground?callValue=0&unit=Wei&codeType=Bytecode&code=%2760016000526001601ff3%27_&ref=hackernoon.com&fork=merge

```apache
00      36        CALLDATASIZE
01      6003      PUSH1 03
03      10        LT            -> calldata needs to be larger than 3 bytes
04      6009      PUSH1 09
06      57        JUMPI
07      FD        REVERT
08      FD        REVERT
09      5B        JUMPDEST
0A      34        CALLVALUE
0B      36        CALLDATASIZE
0C      02        MUL           -> multiply calldatasize with callvalue
0D      6008      PUSH1 08
0F      14        EQ            -> this should be equal to 08: eg 4 bytes * 2 ether
10      6014      PUSH1 14
12      57        JUMPI
13      FD        REVERT
14      5B        JUMPDEST
15      00        STOP
```

The ninth Puzzle introduces nothing new, but I need to take care of two jump destinations. As input it asks a callvalue and calldata.

The first JUMPI upcode needs the calldata size to be at least 4 bytes. This here is different to the previous exercise, because there is not a contract creation happening. As calldata we can use a string as simple as 0xffffffff -> 4 bytes. That we receive 8 in the equal line of line 0F we need to multiply the 4 bytes with 2 ether callvalue.

DONE. Upcodes get easier with while using them :-)
