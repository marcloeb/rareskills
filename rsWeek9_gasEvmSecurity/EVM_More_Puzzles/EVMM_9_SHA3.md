# EVM_More_Puzzles 09: SHA3

Help used: https://www.evm.codes

```apache
00      34        CALLVALUE
01      6000      PUSH1 00
03      52        MSTORE            -> store callvalue at memory location 0
04      6020      PUSH1 20          -> size of input to sha3
06      6000      PUSH1 00          -> position of sha3 => callvalue
08      20        SHA3              -> input value for rightshift
09      60F8      PUSH1 F8          -> 248 amount to shift right
0B      1C        SHR               -> Shift right bit operation
0C      60A8      PUSH1 A8          -> 168
0E      14        EQ
0F      6016      PUSH1 16
11      57        JUMPI
12      FD        REVERT
13      FD        REVERT
14      FD        REVERT
15      FD        REVERT
16      5B        JUMPDEST
17      00        STOP


```

The ninths of Puzzle introduces SHA3 and bitwise shifting to the right. The Opcodes take the sha3 has on the call value. From the resulting hash, 248 bits are shifted off. The remaining 8 bits should equal to decimal 168.

Question: What callvalue is fulfilling this?

Best approach is trying by brute force, it is only 256 values. I was to lazy to enter it manually or to create a full new script so I decided to use shell to run the puzzles automatically. I create a counter. The internals of the puzzles are that it saves files when its solved to the solution folder, I remove that file to have a fresh environment in each iteration. Then I start the puzzles with the value of the counter and increment the counter, remove the solution file. If the result is not a failure (=1), I continue.

COUNT=1
rm solutions/solution_9.json
while [ $? == 1 ]
do
printf "$COUNT\nn\n" | npx hardhat play
     COUNT=$[$COUNT +1]
rm solutions/solution_9.json
done

The script stops at solution is 47.
Done
