//https://github.com/OpenZeppelin/merkle-tree
//prepare merkle root and proof for presale

const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { StandardMerkleTree } = require('@openzeppelin/merkle-tree');
const hre = require('hardhat');

describe('AdvancedNFT', function () {
  async function deployTokenFixture() {
    // 5000 NFTs total supply, 1024 NFTs for presale

    const addresses = [];
    const addressNumber = [];
    let userAllowedAirdrop;

    for (let i = 0; i < 1023; i++) {
      let signer = ethers.Wallet.createRandom().connect(hre.ethers.provider); // a minter
      addresses.push([signer.address]);
      addressNumber.push([signer.address, i]);
    }

    //smart contract
    addresses.push(['0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496']);
    addressNumber.push(['0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496', 1023]);
    userAllowedAirdrop = '0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496';

    return {
      addresses,
      addressNumber,
      userAllowedAirdrop,
    };
  }
  describe('Deployment', async () => {
    it('Should deploy as expected', async function () {
      const { addresses, addressNumber, userAllowedAirdrop } = await loadFixture(deployTokenFixture);

      const treeAddressOnly = StandardMerkleTree.of(addresses, ['address']);
      console.log('Merkle Root for "Mapping" Presale: ', treeAddressOnly.root);

      const treeAddressNumber = StandardMerkleTree.of(addressNumber, ['address', 'uint256']);
      console.log('Merkle Root for "Bitmap" Presale: ', treeAddressNumber.root);

      for (const [i, v] of treeAddressOnly.entries()) {
        if (v[0] === userAllowedAirdrop) {
          // (3)
          const proof = treeAddressOnly.getProof(i);
          console.log('Value:', v);
          console.log('Proof Address Only:', proof);
        }
      }
      for (const [i, v] of treeAddressNumber.entries()) {
        if (v[0] === userAllowedAirdrop) {
          // (3)
          const proof = treeAddressNumber.getProof(i);
          console.log('Value:', v);
          console.log('Proof Address and Number:', proof);
        }
      }
    });
  });
});
