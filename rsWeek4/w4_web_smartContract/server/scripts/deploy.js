// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require('hardhat');

async function main() {
  const Forging = await hre.ethers.getContractFactory('Forging');
  const forging = await Forging.deploy();
  await forging.deployed();

  console.log('Forging contract deployed to address: ' + forging.address);

  const CatsToken = await hre.ethers.getContractFactory('CatsToken');
  const catToken = await CatsToken.deploy(forging.address);
  await catToken.deployed();

  console.log('CatsToken contract deployed to address: ' + catToken.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
