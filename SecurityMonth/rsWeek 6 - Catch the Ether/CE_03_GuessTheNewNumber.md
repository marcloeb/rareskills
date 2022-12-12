# Catch the Ether 3: Guess the RANDOM number

Random numbers cannot be created inside solidity, oracles are suggested

## The Task Intro

This time the number is generated based on a couple fairly random sources.I’m thinking of a number. All you have to do is guess it.

## The Task Code

```apache
pragma solidity ^0.4.21;

contract GuessTheRandomNumberChallenge {
    uint8 answer;

    function GuessTheRandomNumberChallenge() public payable {
        require(msg.value == 1 ether);
        answer = uint8(keccak256(block.blockhash(block.number - 1), now));
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        require(msg.value == 1 ether);

        if (n == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}
```

## The Solution

This task took a very long time for me. I was thinking it is easy to regenerate the number from etherscan, but failed here to do it manually. I was so confident that I can solve this challange that I published to the görli network and guessed with görli eth. They are quite difficult to get, so this developed like a personal challange to get the görlis back before somebody else was doing this.

This was the contract I was tying to manually get the secret number which proved wrong. From what I can say today when I document, the now keyowrd that now is depreciated in solidity was getting the block.timestamp. So this approach should work with the blockhash of the previous block and the timestamp of the current block.

```apache
contract Crack {
    uint8 answer;

    function getSecretNumber(uint256 blockNumber, uint256 timestamp) external view returns (uint8) {
        return uint8(keccak256(block.blockhash(blockNumber - 1), uint256(timestamp)));
    }
}
```

Then I realized a session with Rareskills or a video I watched that said all on the ethereum blockchain is public, even privatly marked elements. So I digged into that and found a web3 method, I used to call out from ehternaut... ;-)

With this I received the answer and finally was able to retrieve all görlis. Cool thing.

```apache
web3.eth.getStorageAt('0xaed30b7c460d94e5183d3f8f3f51cc46bfa46d4e', 0, (err, res) => {
  // convert to uint
  console.log(`0: uint8: res}`);
});
```

Still I was not satisfied with that solution so I was trying to implement that approach with a hardhat javascript test and succeeded with this code:

```apache
    const blockNumber = await gtrnc.provider.getBlockNumber();
    const block = await gtrnc.provider.getBlock(blockNumber);
    const blockTimestamp = block.timestamp;

    const secret = await crack.getSecretNumber(blockNumber, blockTimestamp);
    console.log('The solution from the crack contract: ');
    console.log(secret);

    await gtrnc.connect(owner).guess(secret, { value: ethers.utils.parseEther('1') });
```

I asked a fellow coder how he approached this problem - he chose to solve all from javascript that was his solution:

```apache
     const prevBlock = await gtrnc.provider.getBlock(blockNumber - 1);
      const prevBlockHash = prevBlock.hash;

      const currentBlock = await gtrnc.provider.getBlock(blockNumber);
      const currentBlockTimestamp = currentBlock.timestamp;

      // we have the correct guess now
      const guess = BigNumber.from(ethers.utils.solidityKeccak256(['bytes32', 'uint256'], [prevBlockHash, currentBlockTimestamp])).mask(8);
```

In the catch ether challange, this was the most challenging for me using as well most of my time, especally because I pubished too early to the görli network and was then focussed getting my eth back instead of working on the code. I think that learning is very valuable. As Jeff once mentioned, web3 needs more testing and asks for a higher standard of correctness as in previous tech projects. I completly agree now with this 👍
