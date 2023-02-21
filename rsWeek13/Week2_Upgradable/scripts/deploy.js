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
