# Catch the Ether 2: Guess the SECRET number

Learn about Hashing.

## The Task Intro

I’m thinking of a number. All you have to do is guess it.

## The Task Code

```apache
pragma solidity ^0.4.21;

contract GuessTheSecretNumberChallenge {
    bytes32 answerHash = 0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365;

    function GuessTheSecretNumberChallenge() public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        require(msg.value == 1 ether);

        if (keccak256(n) == answerHash) {
            msg.sender.transfer(2 ether);
        }
    }
}

```

## The Solution

The solution of this exercise is trivial, all you need to do is send 42 to the guess function with one ether. The work for me was setting up the hardhat environment, in particular the javascript test cases.

1. I checked first that the eth is on the contract,
2. Then check the owner balance
3. call the guess function
4. then check if the eth came back from the contract to the calling owner.
5. Finally I call the is completed function of the contract.

I will not repeat this code in the following tasks, unless there are essential changes from this approach.

```apache
describe('CE_01: Guess The Number', function () {
  async function deployReentrencyFixture() {
    const [owner, otherAccount] = await ethers.getSigners();

    const GuessTheNumberChallenge = await ethers.getContractFactory('contracts/CE_01_GuessTheNumber.sol:GuessTheNumberChallenge');
    const gtnc = await GuessTheNumberChallenge.connect(owner).deploy({
      value: ethers.utils.parseEther('1'),
    });

    return { gtnc, owner, otherAccount };
  }

  describe('Deployment', function () {
    it('Guess Number', async function () {
      const { gtnc, owner } = await loadFixture(deployReentrencyFixture);

      //contract has 1 Ether on it
      expect(await gtnc.provider.getBalance(gtnc.address)).to.be.equal(ethers.utils.parseEther('1'));

      //get owner balance
      const balance = await owner.provider.getBalance(owner.address);
      console.log(ethers.utils.formatUnits(balance));

      //guess the number
      await expect(gtnc.connect(owner).guess(42, { value: ethers.utils.parseEther('1') })).to.changeEtherBalances(
        [owner, gtnc],
        [ethers.utils.parseEther('1'), ethers.utils.parseEther('-1')]
      );

      //get new balance
      const newBalance = await owner.provider.getBalance(owner.address);
      console.log(ethers.utils.formatUnits(newBalance));

      const diff = parseInt(ethers.utils.formatUnits(newBalance)) - parseInt(ethers.utils.formatUnits(balance));
      expect(diff).to.be.equal(1);

      //check contract is completed
      expect(await gtnc.isComplete()).to.be.true;
    });
  });
});
```
