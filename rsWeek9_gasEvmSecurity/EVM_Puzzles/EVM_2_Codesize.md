# EVM_Puzzles 02: Codesize

Help used: https://www.evm.codes

```apache
00      34      CALLVALUE
01      38      CODESIZE
02      03      SUB
03      56      JUMP
04      FD      REVERT
05      FD      REVERT
06      5B      JUMPDEST
07      00      STOP
08      FD      REVERT
09      FD      REVERT
```

The second Puzzle substracts Codesize from the Callvalue. Codesize is the size of the bytecode of our contract. Each - I need to add all upcodes which gives me 10.

Important to know: Executing Callvalue will push a value on the stack and remove Callvalue, the same with Codesize. So the stack before the substraction looks like this in hex:

1. 0a (10 bytes)
2. 4 (our input)
3. SUB

This took me some time to understand, I assumed the stack order remains and I was substracting codevalue - codesize, but because of pushing on the stack it is the other way around.

Solved, that was a bit harder and I needed to understand the stack oderder. Solved 🎉️.
