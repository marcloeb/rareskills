# Task 1: Before You Begin

Learn with Chainlink how Oracles work through code, by getting a random Number.

## The Task Intro

Let’s start by writing code that integrates with other on chain smart contracts,
specifically the chainlink VRF.
Build a contract, and deploy to any of the supported networks here:
https://docs.chain.link/vrf/v2/subscription/supported-networks
Your code should mint someone an ERC721 with id from 0 to 100 based on the
outcome of the VRF. Put some thought into how you will handle a number already being
minted.

## Solution

Creating a NFT is easy, but not with a random tokenID thats quite difficult. The blockchain is a deterministic system and randomness is not created by a function. We are adviced to use an Oracle for randomness.

So how to start? As always, google. I worked through a chainlink Example for the VRF Oracle. I found a good [tutorial named
"Getting A Random Number with Chainlink VRF | Chainlink Engineering Tutorials"](https://www.youtube.com/watch?v=JqZWariqh5s) on youtube from Patrick Collins. This was made for the VRF version 1.0.

So I checked the online [chainlink documention for VRF 2.0](https://docs.chain.link/vrf/v2/direct-funding/examples/get-a-random-number). I found a good example for the VRF 2.0. I used this example to create my own contract.

To test the solution locally with hardhat I found a chainlink tutorial [How to Use Chainlink With Hardhat](https://blog.chain.link/using-chainlink-with-hardhat/). I worked through this code and realized the complexity of chainlink.

I revisited the documentation and found [Exploring Chainlink VRF v2 | Developer Walkthrough](https://www.youtube.com/watch?v=rdJ5d8j1RCg&t=374s). I decided not to use a subscription method, because this would add too much complexity and use the chainlink documentation with the example of get a random number.

So I put a project together BeforeYouBegin. It is a ERC721 token that generates a random tokenID with the VRF Oracle. Important take away is that the VRF Oracle is not free. You have to pay for the request. The request is paid with LINK tokens. So you have to have LINK tokens on your account. I used the Sepolia Test Network. The second important take away is that a oracle needs to be requested and a while later a response is given. So you have to wait for the response. My mint function triggers the request for a random number and the response generates the ID and mints the NFT. While generating the ID it checks if the ID is already minted. and moves to the next free number or if all is already minted it reverts.

## Conclusion

Quite a good introduction. I realize I could learn much more but then I would run out of time. I look forward reading the whitepaper of Chainlink and study other facets of chainlink.
