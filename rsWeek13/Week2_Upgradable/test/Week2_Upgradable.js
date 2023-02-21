const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { ethers, upgrades } = require('hardhat');
const { expect } = require('chai');

async function deployOneYearLockFixture() {
  const [owner, god, other] = await ethers.getSigners();

  const MyNFT = await ethers.getContractFactory('MyNFTUpgradable');
  // const MyNFT = await MyNFT_Factory.deploy();
  // await MyNFT.deployed();
  const MyNFT_V2 = await ethers.getContractFactory('MyNFTUpgradable_V2');
  const MyNFT_V3 = await ethers.getContractFactory('MyNFTUpgradable_V3');
  const nftProxy = await upgrades.deployProxy(MyNFT, [owner.address]);

  const Token = await ethers.getContractFactory('RewardTokenUpgradable');
  const Token_V2 = await ethers.getContractFactory('RewardTokenUpgradable_V2');
  const tokenProxy = await upgrades.deployProxy(Token, ['Rewards For NFT Staking', 'RFNFT', owner.address]);

  const Vault = await ethers.getContractFactory('VaultUpgradable');
  const VaultV2 = await ethers.getContractFactory('VaultUpgradable_V2');
  const vaultProxy = await upgrades.deployProxy(Vault, [false, nftProxy.address, tokenProxy.address]);

  return { owner, god, other, nftProxy, MyNFT_V2, MyNFT_V3, tokenProxy, Token_V2, vaultProxy, VaultV2 };
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
