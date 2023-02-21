# Week 2 redone: Upgradable Contracts with OpenZeppelin and the Hardhat

Learn how to use the OpenZeppelin Upgrades Plugins, which allows:

- Deploy upgradable contracts
- Upgrade deployed upgradable contracts
- Manage proxy admin rights

## 1. The Task

Make the three contracts from the Rareskills Bootcamp Week 2 - the NFT, ERC20 token, and staking contract - upgradeable using Openzeppelin upgradability plugin. Deploy it from hardhat.

Build a new version of the NFT that adds god mode to the NFT (ability to transfer NFTs between accounts forcefully).

Etherscan should show the previous version and the new version

## 2. The Solution

OpenZeppelin has a trusted library called [Upgrades Plugins](https://docs.openzeppelin.com/upgrades-plugins/1.x/) for upgrading contracts that we can rely on. All OpenZeppelin contract are forked into the @openzeppelin/contracts-upgradeable. The plugin takes care of deployment, upgrade a deployment, access rights and testing. A [step-by-step tutorial](https://forum.openzeppelin.com/t/openzeppelin-upgrades-step-by-step-tutorial-for-hardhat/3580) helped me understanding. When switching a project to an upgradable project we need to:

- Variable assignments and Constructors of a smart contract implementation do not work in a proxy pattern, because the implemetation contract inizialized its state during contruction and is held on the implementation storage. But the values should be on the proxy storage. Therefore we use initializer functions, where all assignment work should happen -> I need to do this manually
- Inside this initalize function we need to call the initalizer of the classes my contract inherits from, move all variable assignments and the content of the constructor
- Initializer functions should be called only once -> Apply the initializer modifier to the initialize function
- OpenZeppelin contracts need to be changed to the contracts-upgradeable version

I my naming convention I upgraded the ERC721_nft.sol, changing the imports to contract-upgradable, adding Initializable, change the inherited classes to the Upgradeable ones, move the constructor to a newly created initialize function with the initializer modifier, calling the initializer from the parent.

The RewardToken in my ERC20_reward.sol same procedure, change the imports to contract-upgradable, adding Initializable import, change the inherited classes, add a function initialize with the initializer modifier. Move the content of the constructor to this function and remove it.

Finally the Vault, my implementation of the staking contract, in the file Vault.sol. Same procedure here with changing the imports to contract-upgradable, adding the Initializable import, change the inherited classes, add a function initialize with the initializer modifier and move the content of the constructor to this function, remove the constructor. Important here to remove the arguments to the constructor of the NFT and Vault in the initializer of the vault and instead call the initalize function.

To find the detailed instructions I used this [OpenZeppelin API Reference](https://docs.openzeppelin.com/upgrades-plugins/1.x/api-hardhat-upgrades#common-options). Thats it! I tested the code locally first with this setup:

- VaultUpgradable, myNFTUpgradable and RewardTokenUpgradable have a version V1 and V2 - the ony difference is the version function
- In the fixture I setup for each class 2 factories - for version one and two - followed by the creation of a proxy for each class
- This is followed by a test for each class - checking for the version of the current version, do a upgrade of the implementation and then check the version 2
- At the end the god function of MyNFTUpgradable is tested

```àpache
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { ethers, upgrades } = require('hardhat');
const { expect } = require('chai');

async function deployOneYearLockFixture() {
  const [owner] = await ethers.getSigners();

  const MyNFT = await ethers.getContractFactory('MyNFTUpgradable');
  const MyNFT_V2 = await ethers.getContractFactory('MyNFTUpgradable_V2');
  const nftProxy = await upgrades.deployProxy(MyNFT, [owner.address]);

  const Token = await ethers.getContractFactory('RewardTokenUpgradable');
  const Token_V2 = await ethers.getContractFactory('RewardTokenUpgradable_V2');
  const tokenProxy = await upgrades.deployProxy(Token, ['Rewards For NFT Staking', 'RFNFT', owner.address]);

  const Vault = await ethers.getContractFactory('VaultUpgradable');
  const VaultV2 = await ethers.getContractFactory('VaultUpgradable_V2');
  const vaultProxy = await upgrades.deployProxy(Vault, [false, nftProxy.address, tokenProxy.address]);

  return { nftProxy, MyNFT_V2, tokenProxy, Token_V2, vaultProxy, VaultV2 };
}

describe('Week2 redone', function () {
  it('MyNFTUpgradable', async () => {
    const { nftProxy, MyNFT_V2 } = await loadFixture(deployOneYearLockFixture);

    let value = await nftProxy.version();
    expect(value.toString()).to.equal('1');

    const upgraded = await upgrades.upgradeProxy(nftProxy.address, MyNFT_V2);
    value = await upgraded.version();
    expect(value.toString()).to.equal('2');
  });

  it('RewardTokenUpgradable', async () => {
    const { tokenProxy, Token_V2 } = await loadFixture(deployOneYearLockFixture);

    let value = await tokenProxy.version();
    expect(value.toString()).to.equal('1');

    const upgraded = await upgrades.upgradeProxy(tokenProxy.address, Token_V2);
    value = await upgraded.version();
    expect(value.toString()).to.equal('2');
  });

  it('VaultUpgradable', async () => {
    const { vaultProxy, VaultV2 } = await loadFixture(deployOneYearLockFixture);

    let value = await vaultProxy.version();
    expect(value.toString()).to.equal('1');

    const upgraded = await upgrades.upgradeProxy(vaultProxy.address, VaultV2);
    value = await upgraded.version();
    expect(value.toString()).to.equal('2');
  });
  it('MyNFT Version 3', async () => {
    const { owner, god, other, nftProxy, MyNFT_V3 } = await loadFixture(deployOneYearLockFixture);

    let value = await nftProxy.version();
    expect(value.toString()).to.equal('1');

    const upgraded = await upgrades.upgradeProxy(nftProxy.address, MyNFT_V3, { call: { fn: 'setGod', args: [god.address] } });
    value = await upgraded.version();
    expect(value.toString()).to.equal('3');

    // transferFrom a person that does not own a token
    await expect(upgraded.connect(other).transferFrom(god.address, other.address, 1)).to.be.revertedWith(
      'ERC721: caller is not token owner or approved'
    );

    // valid transfer from owner to other
    expect(await upgraded.ownerOf(1)).to.equal(owner.address);
    await upgraded.connect(owner).transferFrom(owner.address, other.address, 1);
    expect(await upgraded.ownerOf(1)).to.equal(other.address);

    // valid transfer from other to god
    await upgraded.connect(other).transferFrom(other.address, god.address, 1);
    expect(await upgraded.ownerOf(1)).to.equal(god.address);

    // valid transfer initalized by god from owner to other for token 2
    expect(await upgraded.ownerOf(2)).to.equal(owner.address);
    await upgraded.godTransfer(owner.address, other.address, 2);
    expect(await upgraded.ownerOf(2)).to.equal(other.address);
  });
});
```

I created a deployment script to deploy to Goerli:

```apache
const hre = require('hardhat');

async function main() {
  let owner = await ethers.getSigner(network.config.from);
  console.log(`Deploying contracts with the account: ${owner.address}`);

  const MyNFT = await ethers.getContractFactory('MyNFTUpgradable');
  const nftProxy = await upgrades.deployProxy(MyNFT, [owner.address]);
  await nftProxy.deployed();
  console.log(`nftProxy deployed to ${nftProxy.address}`);

  const Token = await ethers.getContractFactory('RewardTokenUpgradable');
  const tokenProxy = await upgrades.deployProxy(Token, ['Rewards For NFT Staking', 'RFNFT', owner.address]);
  await tokenProxy.deployed();
  console.log(`tokenProxy deployed to ${tokenProxy.address}`);

  const Vault = await ethers.getContractFactory('VaultUpgradable');
  const vaultProxy = await upgrades.deployProxy(Vault, [false, nftProxy.address, tokenProxy.address]);
  await vaultProxy.deployed();
  console.log(`vaultProxy deployed to ${vaultProxy.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

Here are the contract addresses of my proxis from the code above:

```apache
//deploying
Deploying contracts with the account: 0xe04F800c924FeD4cb7a30A4d6Ae21e630cA5385B
nftProxy deployed to 0x61938201C966429f198cc3845ac51087F871BD4E
tokenProxy deployed to 0xb8bF4352ddbd1581F4Ca70452d1dFe3a16FA7338
vaultProxy deployed to 0x3bdDA397c333320CBcAE3Ec3fA36E8A3Dc4b99D6

//upgrading
Upgrading contract with the account: 0xe04F800c924FeD4cb7a30A4d6Ae21e630cA5385B
nftProxy current:  0x61938201C966429f198cc3845ac51087F871BD4E
nftProxy upgraded at 0x61938201C966429f198cc3845ac51087F871BD4E
```

I wanted the contracts to be verified, so I needed to get the implementation address and run hh verify in the terminal. [This guide from Chainlink](https://blog.chain.link/how-to-verify-smart-contract-on-etherscan-hardhat/) helped me to refresh my knowledge.

```àpache
//nftProxy implementation
await web3.eth.getStorageAt("0x61938201C966429f198cc3845ac51087F871BD4E","0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc")
'0x00000000000000000000000079729957a6225db733e40d5b3522634fc8296f95'

hh verify 0x79729957a6225db733e40d5b3522634fc8296f95

//tokenProxy implementation
await web3.eth.getStorageAt("0xb8bF4352ddbd1581F4Ca70452d1dFe3a16FA7338","0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc")
'0x0000000000000000000000005689eff8308b861465ece2a52f1d0f0eb04f6df8'

hh verify 0x5689eff8308b861465ece2a52f1d0f0eb04f6df8

//tokenProxy implementation
await web3.eth.getStorageAt("0x3bdDA397c333320CBcAE3Ec3fA36E8A3Dc4b99D6","0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc")
'0x0000000000000000000000000ebf0a4cec6c7fedb4817465f148b0d61782a17a'

hh verify 0x0ebf0a4cec6c7fedb4817465f148b0d61782a17a

//nftProxy implementation after upgrade to v3
await web3.eth.getStorageAt("0x61938201C966429f198cc3845ac51087F871BD4E","0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc")
'0x00000000000000000000000079729957a6225db733e40d5b3522634fc8296f95'
0x000000000000000000000000ae7c456e1694fc4ecded0c81dacae339a9c0b309

hh verify 0xae7c456e1694fc4ecded0c81dacae339a9c0b309
```

After running the script, I realized I could have printed out the implementation address of a proxy through the [getImplementation function](https://docs.openzeppelin.com/upgrades-plugins/1.x/api-hardhat-upgrades), but never mind.

```àpache
import { ethers, upgrades } from "hardhat";

const currentImplAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
```

Last task is to create a Version 3 of myNFT with god mode for the transfer, to upgrade the proxy, get the implementation address and do verify it. I struggled to set the god parameter, because initalizers already ran, I found in a blog a [workaround](https://forum.openzeppelin.com/t/upgrade-contract-by-adding-new-parameter-to-initialize/10737) with the call option of the upgradeProxy function.

```àppache
const { ethers, upgrades } = require('hardhat');

async function main() {
  let owner = await ethers.getSigner(network.config.from);
  console.log(`Upgrading contract with the account: ${owner.address}`);

  const MyNFT_V3 = await ethers.getContractFactory('MyNFTUpgradable_V3');
  const upgraded = await upgrades.upgradeProxy('0x61938201C966429f198cc3845ac51087F871BD4E', MyNFT_V3, {
    call: { fn: 'setGod', args: ['0x7F6A0991a92eD8F2d228E319465f751cECba2CF2'] },
  });
  await upgraded.deployed();
  console.log('nftProxy current: ', '0x61938201C966429f198cc3845ac51087F871BD4E');
  console.log(`nftProxy upgraded at ${upgraded.address}`);
  const currentImplAddress = await upgrades.erc1967.getImplementationAddress(upgraded.address);
  console.log(`nftProxy upgraded to ${currentImplAddress.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

The results of the MyNFTUpgradable_V3 can be seen on [Goerli Etherscan](https://goerli.etherscan.io/address/0x61938201C966429f198cc3845ac51087F871BD4E#internaltx).

## 3. Conclusion

Wow, done 🎉️ . What a work. This task looked easy at first, just adding a few uprgradable to the inheriting class names. But hey, understanding the code and all the small difficulties made me work on this task for many hours. Someone once told me in IT there is no shortcut, you can plan wisely, but in execution the tasks that need to be done, are needed to be done.

Still - I learned about upgradable contracts from OpenZeppelin and how to work with their plugin, do scripting for testing and deployment! Cool Stuff, the contracts can be seen on the Goeri network! What a learning!
