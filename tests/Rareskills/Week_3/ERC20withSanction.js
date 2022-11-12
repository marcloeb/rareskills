const { time, loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { ethers } = require('hardhat');
const { BigNumber, utils } = ethers;
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs');
const { expect } = require('chai');

describe('ERC20with Sanctions', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function getContract() {
    const transferValue = '1000000000000000000';

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount, thirdAccount] = await ethers.getSigners();

    const ERC20 = await ethers.getContractFactory('ERC20withSanction');
    const erc20 = await ERC20.deploy('ERC 20 with Sanctions', 'SWS');

    return { erc20, transferValue, owner, otherAccount, thirdAccount };
  }

  describe('Deployment', function () {
    it('Check Name and Symbol of Contract', async function () {
      const { erc20 } = await loadFixture(getContract);

      expect(await erc20.name())
        .to.be.a('string')
        .equal('ERC 20 with Sanctions');

      expect(await erc20.symbol())
        .to.be.a('string')
        .equal('SWS');
    });

    it('Should set the right owner', async function () {
      const { erc20, owner } = await loadFixture(getContract);

      expect(await erc20.owner()).to.equal(owner.address);
    });
  });

  describe('Contract - Banning', function () {
    describe('Banning and unbanning Users', function () {
      it('Bann a user', async function () {
        const { erc20, otherAccount } = await loadFixture(getContract);
        expect(await erc20.banned(otherAccount.address)).to.equal(false);
        expect(await erc20.bannUser(otherAccount.address)).to.not.be.reverted;
        expect(await erc20.banned(otherAccount.address)).to.equal(true);
      });

      it('Unbann a user', async function () {
        const { erc20, otherAccount } = await loadFixture(getContract);
        expect(await erc20.bannUser(otherAccount.address)).to.not.be.reverted;
        expect(await erc20.banned(otherAccount.address)).to.equal(true);
        expect(await erc20.unBannUser(otherAccount.address)).to.not.be.reverted;
        expect(await erc20.banned(otherAccount.address)).to.equal(false);
      });
    });

    describe('Access rights are working properly', function () {
      it('Admin cannot ban or unban himself', async function () {
        const { erc20, owner } = await loadFixture(getContract);
        await expect(erc20.bannUser(owner.address)).to.be.revertedWith('owner cannot bann himself');
        await expect(erc20.unBannUser(owner.address)).to.be.revertedWith('owner cannot un-bann himself');
      });
      it('A user cannot ban or unbann other users', async function () {
        const { erc20, otherAccount, thirdAccount } = await loadFixture(getContract);
        await expect(erc20.connect(otherAccount).bannUser(thirdAccount.address)).to.be.revertedWith(
          'Ownable: caller is not the owner'
        );
        await expect(erc20.connect(otherAccount).unBannUser(thirdAccount.address)).to.be.revertedWith(
          'Ownable: caller is not the owner'
        );
      });
    });

    describe('Transfer with banning', function () {
      it('Transfer of a unbanned user is possible', async function () {
        const { erc20, transferValue, otherAccount, thirdAccount } = await loadFixture(getContract);
        await erc20.connect(otherAccount).buyTokens({ value: transferValue });
        await expect(erc20.connect(otherAccount).transfer(thirdAccount.address, 10000)).to.not.be.reverted;
      });
      it('Receive of a unbanned user is possible', async function () {
        const { erc20, transferValue, otherAccount } = await loadFixture(getContract);
        await erc20.buyTokens({ value: transferValue });
        await erc20.bannUser(otherAccount.address);
        await expect(erc20.transfer(otherAccount.address, 10000)).to.be.revertedWith('user banned, no receive tokens');
      });
      it('Send of a unbanned user is possible', async function () {
        const { erc20, transferValue, otherAccount } = await loadFixture(getContract);
        await erc20.connect(otherAccount).buyTokens({ value: transferValue });
        await erc20.bannUser(otherAccount.address);
        await expect(erc20.connect(otherAccount).transfer(otherAccount.address, 10)).to.be.revertedWith(
          'user banned, no send tokens'
        );
      });
      it('All supply used', async function () {
        const { erc20, owner } = await loadFixture(getContract);
        zeroEtherInHex = utils.hexStripZeros(utils.parseEther('100000000000').toHexString());
        await ethers.provider.send('hardhat_setBalance', [
          owner.address, //this address is clear
          zeroEtherInHex,
        ]);
        const val = new BigNumber.from('100000000000000000000000001'); //100_000_000 eth
        await expect(erc20.buyTokens({ value: val })).to.be.revertedWith('cannot mint - max supply reached');
      });
    });

    //another user cannot be banned
    describe('get Contract balance', function () {
      it('call balance', async function () {
        const { erc20 } = await loadFixture(getContract);
        expect(await erc20.getContractBalance()).to.equal(0);

        const amount = new BigNumber.from('1000000000000000000');
        await erc20.buyTokens({ value: amount });
        expect(await erc20.getContractBalance()).to.equal(amount);
      });
    });

    describe('send Eth from owner to contract and back', function () {
      it('buy tokens, check balance and send money back to owner', async function () {
        //check contract eth balance is 0
        const { erc20, owner } = await loadFixture(getContract);
        expect(await erc20.getContractBalance()).to.equal(0);

        //why here is no gas token away? Because full amount is deposited, and the sender pays free gas
        const amount = new BigNumber.from('1000000000000000000');
        await erc20.buyTokens({ value: amount });
        expect(await erc20.getContractBalance()).to.equal(amount);

        //owner balance
        const ownerBalance = await ethers.provider.getBalance(owner.address);

        //contract sends to owner -> is that true?
        const amountMinusGas = amount.sub(2000000000); //2gwei
        await erc20.sendEtherToOwner(amountMinusGas); //calling this function costs gas as well

        //check if amountMinusGas arrived.
        const ownerBalanceAfter = await ethers.provider.getBalance(owner.address);
        expect(ownerBalanceAfter.sub(ownerBalance)).to.closeTo(amountMinusGas, 200000 * 1000000000); //minus gas price from making the transaction
      });
    });

    describe('sell Tokens', function () {
      it('balanceOf token is greater than asked amount', async function () {
        const { erc20 } = await loadFixture(getContract);
        await expect(erc20.sellTokens(5)).to.be.revertedWith('not enough tokens');
      });
      it('check if enough ether (1:1 conversion)', async function () {
        const { erc20, owner } = await loadFixture(getContract);
        //console.log('ContractEth: ' + (await erc20.getContractBalance()));

        //buy tokens
        const amount = new BigNumber.from(utils.parseEther('1'));
        await erc20.buyTokens({ value: amount });
        //console.log('ContractEth: ' + (await erc20.getContractBalance()));
        //console.log('Token:       ' + (await erc20.balanceOf(owner.address)));

        //send eth to owner
        await erc20.sendEtherToOwner(amount); //0.1 gwei for transaction
        //console.log('ContractEth: ' + (await erc20.getContractBalance()));
        //console.log('Token:       ' + (await erc20.balanceOf(owner.address)));

        //sell 5 tokens
        await expect(erc20.sellTokens(amount)).to.be.revertedWith('Not enough ether for payout');
      });

      it('regular sell after a buy', async function () {
        const { erc20, owner } = await loadFixture(getContract);
        //buy tokens
        const amount = new BigNumber.from(utils.parseEther('1'));
        await erc20.buyTokens({ value: amount });
        await expect(erc20.sellTokens(amount)).to.not.be.reverted;
      });
    });

    describe('transfer and renaunce Ownership not possible', function () {
      it('check the transfer', async function () {
        const { erc20, owner } = await loadFixture(getContract);
        await expect(erc20.transferOwnership(owner.address)).to.revertedWith('transfer ownership not allowed');
      });
      it('check the renounce', async function () {
        const { erc20 } = await loadFixture(getContract);
        await expect(erc20.renounceOwnership()).to.revertedWith('renounce ownership not allowed');
      });
    });
  });
});
//events and transfers
