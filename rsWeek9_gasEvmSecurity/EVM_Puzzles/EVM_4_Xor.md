# EVM_Puzzles 04: Xor

Help used: https://www.evm.codes, https://www.rapidtables.com/convert/number/binary-to-hex.html, https://codebeautify.org/xor-calculator

```apache
00      34      CALLVALUE
01      38      CODESIZE
02      18      XOR
03      56      JUMP
04      FD      REVERT
05      FD      REVERT
06      FD      REVERT
07      FD      REVERT
08      FD      REVERT
09      FD      REVERT
0A      5B      JUMPDEST
0B      00      STOP
```

The forth Puzzle introduces XOR. This task was not difficult, but needed already 20min for me. I know that the stack order is

1. codesize -> 12 bytes or 0xc
2. callvalue -> ???

That brought me to bitwise XOR. I know that it returns 1 if one value of both value is true (or 1). If both are true or both are false xor returns false (or 0).

That said I converted my values:

1. 0xc -> 1100
2. ?? -> ??
3. ===============
4. 0xa -> 1010

Which makes the result 0110, which equals HEX 0x6.

👀️ funny stuff, this hex, binary, decimal xor bitwise calcs.
