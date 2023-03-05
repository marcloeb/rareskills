# Task 2: Strange Exercise

This exercise teaches the use of Metamorphic contracts

## The Task Intro

Solve this challenge and post your solution on your github

```apache
contract StrangeV4 {
    bool check1;
    address private strangeContract;
    bytes32 private codeHash;
    uint256 private codeLength;

    constructor() payable {
        require(msg.value == 1 ether);
    }

    function initialize(address _contract) external {
        require(_contract.code.length != 0, "target must be a contract");
        codeHash = _contract.codehash;
        strangeContract = _contract;
    }

    function success(address _contract) external {
        require(_contract.code.length != 0, "must be a contract");
        require(_contract == strangeContract, "must be the same contract");
        require(_contract.codehash != codeHash, "contract isn't strange");
        uint256 bal;
        assembly {
            bal := selfbalance()
        }
        payable(msg.sender).transfer(bal);
    }
}
```

## The Solution

This tasked lacks a bit of instruction - its needed to know that I work on metamorphic contracts. In the intro of the task I received a teaching about 0age 4 year old metamorphic factory, which is quite impressive. Currently selfdistruct is depreciated and it seems that metamorphic contracts are out of fashion. Still I did the exercise with passion :-).

The strange contracts receives 1 eth at construction, then it is inicalized with a contract that takes the codehash and address to storage.

The success case, when I receive my ether back, if:

- the address is a contract
- the address in the success case is the same as in the initialization case
- the codehash is different

The last condition says, that the contract under the same address changed its implementation -> a metamorph!

So I used the 0age MetamorphicContract Factory, the strangev4 contract and two implementations of one function that will alter the codehash called Original and Exploitor.

I first wanted to solve the exercise with foundry, after being half through realizing that [selfdestruct is not supported by foundry](https://github.com/foundry-rs/foundry/issues/1543) - ok, restart with Hardhat.

I started the setup in a fixture (even that this in not necessary):

- Get the users
- Create the Metamorhic contract factory
- Setup the StrangeV4 contract
- Create the Original and Exploiter contract

The metamorphic contract needs a salt that starts with the deployer address so first I create the salt with the deployer address + 02 + trailing 0 to 32 bytes.

I create the metamorph contract with the original implementation, the salt and a 0x0 for a transientcontract that we do not use (specific to the MetamorphContractFactory).

The difficult part here was to get the metamorph address out of the transaction in javascript. I did it through the Metamorphed event from the MetamorphicContractFactory. My learning here was first get the transaction, then wait for the receipt. Then search for the event, get the argument. Easy if you know it, but tough to do it the first time. Just regular software development!

After this third setup begins:

- I set the metamorph address to the strange contract
- I initalize the StrangeV4 to the metamorph address
- I attach to the deployed metamorph contract (there exist several methods for this :-)

Finally after this setup I test:

- The implementation function addTwo works as expected by adding +2
- I kill the metamorph contract with selfdestruct in the original contract (delegate call)
- I redeploy the metamorph with the Exploitor implementation addTwo +4
- The address of the new metamorp remains the same :-)
- I test if the new metamorph gives back addTwo with +4
- I call success on strangeV4

## Conclusion

Metamorphic contracts will be a relict after selfdestruct is not available any more, even now that selfdestruct is depreciated. Upgradability is done through Proxy mainly I suppose. Hey task solved!!! It was not as simple, expecally understanding foundry does not work, how to receive a value in hardhat test and setting up all correctly.

Done 🎉️.

Here the hardhat test file:

```apache
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { expect } = require('chai');

describe('Metamorph', function () {
  async function deployContractsFixture() {
    //Users
    const [owner, otherAccount] = await ethers.getSigners();
    const zeroByte = '0x';

    //StrangeV4 task
    const Strange = await ethers.getContractFactory('StrangeV4');
    const strange = await Strange.deploy({
      value: ethers.utils.parseEther('1'),
    });
    await strange.deployed();

    //Metamorphic contract factory
    const MetaMorphFactory = await ethers.getContractFactory(
      'MetamorphicContractFactory'
    );
    const metaMorphFactory = await MetaMorphFactory.deploy(zeroByte);
    await metaMorphFactory.deployed();

    //Original and Exploitor contract
    const OriginalImplementation = await ethers.getContractFactory('Original');
    const originalImplementation = await OriginalImplementation.deploy(
      metaMorphFactory.address
    );
    await originalImplementation.deployed();

    const ExploitorImplementation = await ethers.getContractFactory(
      'Exploitor'
    );
    const exploitorImplementation = await ExploitorImplementation.deploy(
      metaMorphFactory.address
    );
    await exploitorImplementation.deployed();

    return {
      zeroByte,
      metaMorphFactory,
      originalImplementation,
      strange,
      exploitorImplementation,
      owner,
      otherAccount,
    };
  }

  describe('Strange Exercise', function () {
    it('Solve the strangev4 puzzle with the metamorph pattern', async function () {
      const {
        owner,
        metaMorphFactory,
        originalImplementation,
        strange,
        exploitorImplementation,
        zeroByte,
      } = await loadFixture(deployContractsFixture);

      //create salt with address of metaMorphFactory first and a random number second
      const salt = owner.address.concat('02', '0000000000000000000000');

      //create metamorphic contract
      const tx =
        await metaMorphFactory.deployMetamorphicContractFromExistingImplementation(
          salt,
          originalImplementation.address,
          zeroByte
        );

      //get metamorphic contract address (IMPORTANT: after transaction get receipt with wait() on the transaction)
      const receipt = await tx.wait();
      let metamorphAddress = receipt.events?.filter((x) => {
        return x.event == 'Metamorphosed';
      })[0].args.metamorphicContract;

      //initialize the strange contract
      await strange.initialize(metamorphAddress);

      //get metamorphic contract (see other methods at the end of the test)
      let metamorph = await ethers.getContractAt(
        'Original',
        metamorphAddress,
        owner
      );

      expect(await metamorph.addTwo(3)).to.equal(5);
      await metamorph.kill();
      await expect(metamorph.addTwo(1)).to.be.reverted;

      await metaMorphFactory.deployMetamorphicContractFromExistingImplementation(
        salt,
        exploitorImplementation.address,
        zeroByte
      );

      expect(await metamorph.addTwo(3)).to.equal(7);

      //call success on strange contract
      await expect(strange.success(metamorphAddress)).to.changeEtherBalance(
        owner,
        ethers.utils.parseEther('1')
      );
    });
  });
});

/*
  other method to get metamorphic contract

  //method two
  const metamorph = await new hre.ethers.Contract(
    tx.to,
    originalImplementation.interface,
    owner
  );

  //method three
  const Original = await ethers.getContractFactory('Original');
  const metamorph = await Original.attach(metamorphAddress);
*/
```
