async function main() {
  let owner = await ethers.getSigner(network.config.from);
  console.log(`Deploying contracts with the account: ${owner.address}`);
  console.log('Account balance:', (await owner.getBalance()).toString());

  const NftAirdrop = await ethers.getContractFactory('NftAirdrop');
  const nftAirdrop = await NftAirdrop.deploy(
    'NFT with Airdrop',
    'NFTAD',
    5000,
    1024,
    '0x89c7b258591ebbd0b909c231d76cae91623faae44010c236b372a56c18ab20c1',
    '0x6277b402a85f4050fba731bef9d5401f39631d7beb5d285fb811ee8b480d857b'
  );

  await nftAirdrop.deployed();

  await nftAirdrop.setMintingType(2); // 0 = not set, 1 = mapping, 2 = bitmap

  console.log('NFT Airdrop address:', nftAirdrop.address);
  console.log('Deployment completed.');

  console.log('Transferring ownership of the contract to the multisig...');
  const gnosis_safe_address = '0x0AB42f823bBc16BAFc22823f553dDd46e644b528';
  await nftAirdrop.transferOwnership(gnosis_safe_address);

  console.log('✓ Ownership transferred to the multisig at: ', await nftAirdrop.owner());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
