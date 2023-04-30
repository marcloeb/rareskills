// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require('hardhat');

// async function main() {
//   const NFT_VRF = await hre.ethers.getContractFactory('NFT_VRF');
//   const nft_vrf = await NFT_VRF.deploy();

//   await nft_vrf.deployed();

//   console.log(`NFT_VRF deployed to ${nft_vrf.address}`);
// }

async function main() {
  const PriceFeed = await hre.ethers.getContractFactory('PriceFeed');
  const priceFeed = await PriceFeed.deploy();

  await priceFeed.deployed();

  console.log(`Price Feed deployed to ${priceFeed.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
