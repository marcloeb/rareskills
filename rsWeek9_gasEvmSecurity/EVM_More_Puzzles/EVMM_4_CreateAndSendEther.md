# EVM_More_Puzzles 04: Create and send ether

Help used: https://www.evm.codes

```apache
00      30        ADDRESS           -> [Address]
01      31        BALANCE           -> [Balance beginning]
02      36        CALLDATASIZE      -> [Calldatasize, Balance beginning]
03      6000      PUSH1 00
05      6000      PUSH1 00          -> [00, 00, Calldatasize, Balance beginning]
07      37        CALLDATACOPY      -> [Balance beginning]
08      36        CALLDATASIZE      -> [Calldatasize, Balance beginning]
09      6000      PUSH1 00          -> [00, Calldatasize, Balance beginning]
0B      30        ADDRESS           -> [Address,00, Calldatasize, Balance beginning]
0C      31        BALANCE           -> [Balance current, 00, Calldatasize, Balance beginning]
0D      F0        CREATE            -> [Contract Address, Balance beginning]
0E      31        BALANCE           -> [Balance current, Balance beginning]
0F      90        SWAP1             -> [Balance beginning, Balance current]
10      04        DIV
11      6002      PUSH1 02
13      14        EQ                ->
14      6018      PUSH1 18
16      57        JUMPI
17      FD        REVERT
18      5B        JUMPDEST
19      00        STOP
```

The forth of more Puzzle introduces adds a new complexity, here I needed to take care of the stack how it develops, without this I was unable to realize what the problem is.

It turns out that we create a contract and send all the value to it. At the end the devision of the beginning balance / current balance needs to be 2. Because we send all to the new contract, this gives a zero devision.

The solution for this is creating a bytecode calldata that sends the money back after the execution, so we have a devision result of 2.

I follow it that way - in the beginning I will give the contract 4 wei, the contract that will be created needs to send 2 wei back. Like this the division result will be 2.

Creating the bytecode 0x6000808080600260025AF1600080F3 with the meaning:

- 60 Push1
- 00 Value -> return size
- 80 Dup1 00 -> return offset
- 80 Dup1 00 -> args size
- 80 Dup1 00 -> args offset
- 60 Push1
- 02 Value -> wei to send back
- 60 Push1
- 02 Value -> current address (internal)
- 5A Gas
- F1 CALL -> execute call
- 60 Push1
- 00 Value
- 80 Dup1
- F3 return

During the create the bytecode created immediately sends back 2 wei. As well here the return value is necessary.

Done, quite difficult though!
