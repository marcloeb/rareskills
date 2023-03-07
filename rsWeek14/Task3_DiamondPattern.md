# Task 3: EIP 2535, Diamond Standard = Multi Facet Proxy

Learn about how parameters in a constructor work and how to inject code from there.

## The Task Intro

Create a Diamond ERC721. First make a plain boring one, then add the ability to mint with an ERC20 token. (Diamonds can be complicated, create a minimum working
example, two facets should be sufficient).

## The learning

The dimond pattern separates Data Storage from implementation. It is a multi implementation pattern, that allows to control several storages. It has one Proxy Contract with several implementations. The rooting and storage is happening on the storage.

Why would you need this? Most of the time the proxy pattern is not used, but the ability to have a modular implementations system that scale might be useful for large teams and complex requirements some time in the future:

The pros for the dimand pattern:

- Modular upgradability
- Reusability of facets (implementations), no code duplication
- Storage slot management helps to avoid the problems that rise from depreciated variables from the implementation
- Modular permission system
- Unlimited contract size (one contract is restricted to 24k)

The cons for the dimand pattern:

- Its more complex than a regular proxy pattern
- Therefore it is harder to understand and to maintain
- Not many big projects exist so far
- Etherscan does not work with the Diamond Pattern.

The resources I used:

- [Diamond Smart Contract (EIP-2535) : A New Way to Upgrade your Contracts](https://www.youtube.com/watch?v=OMM9pgEJ4og)
- [ERC-2535: Diamonds, Multi-Facet Proxy](https://eips.ethereum.org/EIPS/eip-2535)
- [A real implementation: aavegotchi/aavegotchi-contracts](https://github.com/aavegotchi/aavegotchi-contracts/tree/master/contracts/Aavegotchi)
- [Awesome Diamonds: The offical list for dimonds written by Nick Mudge](https://github.com/mudgen/awesome-diamonds)
- [Diamond Standard with Nick Mudge | Solidity Fridays (Jul22)](https://www.youtube.com/watch?v=9-MYz75FA8o)
- [EIP-2535: Diamond Standard with Nick Mudge (Mar20)](https://www.youtube.com/watch?v=64VfajtPGJ4)
- [Nick Mudges Diamond1-hardhat Example](https://github.com/mudgen/diamond-1-hardhat)
- [Jespers work on week 14](https://github.com/jesperkristensen58/example-diamond-proxy-contract)
- [Aavegotchi Diamond Contract](https://github.com/aavegotchi/aavegotchi-contracts/tree/master/contracts/Aavegotchi)

## The Solution

The dimand standard is a beast! It is a very advanced pattern made for large projects. I imagine, if you have several developers, everyone needs to work on his own contract, or even teams work on their contract and then consolidate all in a diamond. Permissions and Upgradability will be easier through the diamond.

One important concept to grasp is that a function can exist only once in the entire dimond, so there will be a lot of discussion about function naming, probably a prefix to each contract is necessary (funny it is not talked about it in the EIP 2535.)

I worked on the [dimand1-hardhat](https://github.com/mudgen/diamond-1-hardhat) example from Nick Mudge, and added two facets - one NFTFacet for minting and a ERC20Facet for paying the Facet. The two facets are deployed in the deploy.js script and the test take place in the diamondTest.js.

A real world project. As usual it is very hard to control all the things so testing all elements is probably the most important thing for a safe project.

My major work was to make the example 1 from Nick Mudge work, understand his code, integrate the two new facets (with unique function names), understand Nick Mudge´s tests and create new tests for the methods.

Done 🎉️.
