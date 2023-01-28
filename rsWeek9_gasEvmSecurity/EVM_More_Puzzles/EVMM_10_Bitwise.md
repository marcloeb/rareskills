# EVM_More_Puzzles 10: Bitwise

Help used: https://www.evm.codes

```apache
00      6020                                                                    PUSH1 20
02      6000                                                                    PUSH1 00
04      6000                                                                    PUSH1 00
06      37                                                                      CALLDATACOPY      -> copy calldata
07      6000                                                                    PUSH1 00
09      51                                                                      MLOAD             -> load calldata to stack
0A      7FF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0      PUSH32    F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0                                  -> push a mask to the stack
2B      16                                                                      AND               -> make a bitwise and operation
2C      6020                                                                    PUSH1 20
2E      6020                                                                    PUSH1 20
30      6000                                                                    PUSH1 00
32      37                                                                      CALLDATACOPY      -> copy another word calldata
33      6000                                                                    PUSH1 00
35      51                                                                      MLOAD             -> load second word
36      17                                                                      OR                masked and -> or it with mload
37      7FABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAB      PUSH32 ABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAB
58      14                                                                      EQ               -> this should be equal with push32
59      605D                                                                    PUSH1 5D
5B      57                                                                      JUMPI
5C      FD                                                                      REVERT
5D      5B                                                                      JUMPDEST
5E      00                                                                      STOP
```

Finally last puzzle! The tenth of more Puzzle introduces bitwise operations. It takes the call data and masks it with a and operation. Then the algorythm uses the result and xor it with the calldata. The result should equal 7FABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAB

LOL. So whats the question I have? Can I reverse engineer the call data? The equation is the following:

(A & 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0) | B = 0xABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAB

easiest solution is to enter the first word 32 bytes of 0, that will 0 out the first expression.
If I xor 0xABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAB with all zeros, then the result will be the input.

Therefore the solution is
0x0000000000000000000000000000000000000000000000000000000000000000ABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAB
