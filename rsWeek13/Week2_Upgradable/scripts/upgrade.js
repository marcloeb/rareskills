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
