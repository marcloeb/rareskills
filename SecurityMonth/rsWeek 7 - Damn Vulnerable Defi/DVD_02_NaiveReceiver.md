# Damn Vulnerable Defi 2: Naive Receiver

As with every first exercise of a new type of concept the second one gets easier in the how to. Lessons to learn: A receiver must check who iniciated the contract.

## The Task Intro

Tere's a lending pool offering quite expensive flash loans of Ether, which has 1000 ETH in balance. You also see that a user has deployed a contract with 10 ETH in balance, capable of interacting with the lending pool and receiveing flash loans of ETH. Drain all ETH funds from the user's contract. Doing it in a single transaction is a big plus ;)

## The Task Code

THE LENDER POOL

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title NaiveReceiverLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract NaiveReceiverLenderPool is ReentrancyGuard {

    using Address for address;

    uint256 private constant FIXED_FEE = 1 ether; // not the cheapest flash loan

    function fixedFee() external pure returns (uint256) {
        return FIXED_FEE;
    }

    function flashLoan(address borrower, uint256 borrowAmount) external nonReentrant {

        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= borrowAmount, "Not enough ETH in pool");


        require(borrower.isContract(), "Borrower must be a deployed contract");
        // Transfer ETH and handle control to receiver
        borrower.functionCallWithValue(
            abi.encodeWithSignature(
                "receiveEther(uint256)",
                FIXED_FEE
            ),
            borrowAmount
        );

        require(
            address(this).balance >= balanceBefore + FIXED_FEE,
            "Flash loan hasn't been paid back"
        );
    }

    // Allow deposits of ETH
    receive () external payable {}
}
```

BORROWER

```apache
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title FlashLoanReceiver
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FlashLoanReceiver {
    using Address for address payable;

    address payable private pool;

    constructor(address payable poolAddress) {
        pool = poolAddress;
    }

    // Function called by the pool during flash loan
    function receiveEther(uint256 fee) public payable {
        require(msg.sender == pool, "Sender must be pool");

        uint256 amountToBeRepaid = msg.value + fee;

        require(address(this).balance >= amountToBeRepaid, "Cannot borrow that much");

        _executeActionDuringFlashLoan();

        // Return funds to pool
        pool.sendValue(amountToBeRepaid);
    }

    // Internal function where the funds received are used
    function _executeActionDuringFlashLoan() internal { }

    // Allow deposits of ETH
    receive () external payable {}
}
```

## The Solution

Understanding what the code is intended to do seems to be the major task in understanding/auditing smart contracts.

Here we have a lender and a receiver that operates with ETH, no tokens as in the last exercise.

The problem arises that anyone can initiate a flashloan for the receiver, because there are no checks who is allowed. Therefore an attacker can call the contract 10 times and every time one Eth of fee is due.

At the end, the receiver does not have any eth anymore - in this case he lost about $12.000. Ok we are in a crypto winter, still, that exploit will never happen with me :-)

```apache
for (let i = 0; i < 10; i++) {
   await this.pool.connect(attacker).flashLoan(this.receiver.address, 10);
}
```

Sending a
