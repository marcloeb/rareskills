# Task 1: EIP721 ERC20Permit

## Scaffold Eth

To test a ERC20 Permit contract I need a website that integrates with a smart contract. It is suggested to use scaffold-eth, because I do not know this, I watched a [Scaffold-eth Intro Workshop](https://www.youtube.com/watch?v=k3Lj5FKjZeA&t=1854s).

## ERC20 Permit Example

To speed up development time I investigated two project that solved that problem:

- [Jesper Kristensen - ERC20 Permit](https://github.com/jesperkristensen58/ERC712-Permit-Example)
- [Raul Martin - ERC20 Permit](https://github.com/Ramarti/rareskills-permit/tree/main/web)

## ERC20 Permit Learnings:

ERC20 Permit is an extension to the ERC20 Token Standard. Instead of a user signing an approve transaction, he signs the data "approve(spender, amount)". The result can be passed by anyone. This other user calls the permit function where we simply retrieve the signer address using ecrecover, followed by approve(signer, spender, amount).

Implementation of the ERC20 Permit extension allowing approvals to be made via signatures. By not relying on {IERC20-approve}, the token holder account doesn't need to send a transaction, and thus is not required to hold Ether at all, which eliminates the initial gas cost of approval, it is just a sign of the inital user.

This means signing a message is cheaper than sending a transaction, and the user does not need to hold Ether to pay for gas.

Done 🎉️.

## How to use Scaffold-eth

1. yarn install: install all dependencies
2. yarn chain: start a local blockchain
3. yarn watch: complile and deploy contracts constantly
4. yarn start: Start the react frontend. Check all console log in the browser console.
