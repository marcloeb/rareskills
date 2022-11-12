const { time, loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { ethers } = require('hardhat');
const { BigNumber, utils } = ethers;
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs');
const { expect } = require('chai');

describe('ERC20SaleBuyback', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function getContract() {
    const transferValue = '1000000000000000000';

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount, thirdAccount] = await ethers.getSigners();

    const ERC20 = await ethers.getContractFactory('ERC20SaleBuyback');
    const erc20 = await ERC20.deploy();

    return { erc20, transferValue, owner, otherAccount, thirdAccount };
  }

  describe('Deployment', function () {
    it('Check Name and Symbol of Contract', async function () {
      const { erc20 } = await loadFixture(getContract);

      expect(await erc20.name())
        .to.be.a('string')
        .equal('TokenBonding');

      expect(await erc20.symbol())
        .to.be.a('string')
        .equal('TBK');
    });

    it('Should set the right owner', async function () {
      const { erc20, owner } = await loadFixture(getContract);

      expect(await erc20.owner()).to.equal(owner.address);
    });
  });

  describe('Buy Tokens overrided function', function () {
    it('a regular buy works without reverting and a Purchase Event is emitted', async function () {
      const { erc20, owner } = await loadFixture(getContract);
      amount = utils.parseEther('1');
      await expect(erc20.buyTokens({ value: amount })).to.not.be.reverted;
      await expect(erc20.buyTokens({ value: amount })).to.emit(erc20, 'Purchase');
    });

    it('All supply used', async function () {
      const { erc20, owner } = await loadFixture(getContract);
      zeroEtherInHex = utils.hexStripZeros(utils.parseEther('10000000000000000000').toHexString());
      await ethers.provider.send('hardhat_setBalance', [
        owner.address, //this address is clear
        zeroEtherInHex,
      ]);
      const val = new BigNumber.from('1000000000000000000000000000000000001'); //100_000_000_000_000_000 eth omg
      await expect(erc20.buyTokens({ value: val })).to.be.revertedWith('cannot mint - max supply reached');
    });
  });

  describe('Sell Tokens overrided function', function () {
    it('a regular sell works without reverting and Sell Event is emitted', async function () {
      const { erc20, owner } = await loadFixture(getContract);

      amount = utils.parseEther('1');
      await expect(erc20.buyTokens({ value: amount })).to.not.be.reverted;
      await expect(erc20.buyTokens({ value: amount })).to.not.be.reverted;

      const tokenBalance = await erc20.balanceOf(owner.address);

      await expect(erc20.sellTokens(tokenBalance / 2)).to.not.be.reverted;
      await expect(erc20.sellTokens(tokenBalance / 2)).to.emit(erc20, 'Sell');
    });
  });
});
