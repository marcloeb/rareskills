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
