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

## How to use Scaffold-eth

1. yarn install: install all dependencies
2. yarn chain: start a local blockchain
3. yarn watch: complile and deploy contracts constantly
4. yarn start: Start the react frontend. Check all console log in the browser console.

Done 🎉️.

# 🏗 Scaffold-ETH

> everything you need to build on Ethereum! 🚀

🧪 Quickly experiment with Solidity using a frontend that adapts to your smart contract:

![image](https://user-images.githubusercontent.com/2653167/124158108-c14ca380-da56-11eb-967e-69cde37ca8eb.png)

# 🏄‍♂️ Quick Start

Prerequisites: [Node (v18 LTS)](https://nodejs.org/en/download/) plus [Yarn (v1.x)](https://classic.yarnpkg.com/en/docs/install/) and [Git](https://git-scm.com/downloads)

🚨 If you are using a version < v18 you will need to remove `openssl-legacy-provider` from the `start` script in `package.json`

> 1️⃣ clone/fork 🏗 scaffold-eth:

```bash
git clone https://github.com/scaffold-eth/scaffold-eth.git
```

> 2️⃣ install and start your 👷‍ Hardhat chain:

```bash
cd scaffold-eth
yarn install
yarn chain
```

> 3️⃣ in a second terminal window, start your 📱 frontend:

🚨 if your contracts are not deployed to localhost, you will need to update the default network in `App.jsx` to match your default network in `hardhat-config.js`.

```bash
cd scaffold-eth
yarn start
```

> 4️⃣ in a third terminal window, 🛰 deploy your contract:

🚨 if you are not deploying to localhost, you will need to run `yarn generate` first and then fund the deployer account. To view account balances, run `yarn account`. You will aslo need to update `hardhat-config.js` with the correct default network.

```bash
cd scaffold-eth
yarn deploy
```

🔏 Edit your smart contract `YourContract.sol` in `packages/hardhat/contracts`

📝 Edit your frontend `App.jsx` in `packages/react-app/src`

💼 Edit your deployment scripts in `packages/hardhat/deploy`

📱 Open http://localhost:3000 to see the app

🚨📡 To deploy to a public domain, use `yarn surge`. You will need to have a surge account and have the surge CLI installed. There is also the option to deploy to IPFS using `yarn ipfs` and `yarn s3` to deploy to an AWS bucket 🪣 There are scripts in the `packages/react-app/src/scripts` folder to help with this.`

# 📚 Documentation

Documentation, tutorials, challenges, and many more resources, visit: [docs.scaffoldeth.io](https://docs.scaffoldeth.io)

# 🍦 Other Flavors

- [scaffold-eth-typescript](https://github.com/scaffold-eth/scaffold-eth-typescript)
- [scaffold-eth-tailwind](https://github.com/stevenpslade/scaffold-eth-tailwind)
- [scaffold-nextjs](https://github.com/scaffold-eth/scaffold-eth/tree/scaffold-nextjs)
- [scaffold-chakra](https://github.com/scaffold-eth/scaffold-eth/tree/chakra-ui)
- [eth-hooks](https://github.com/scaffold-eth/eth-hooks)
- [eth-components](https://github.com/scaffold-eth/eth-components)
- [scaffold-eth-expo](https://github.com/scaffold-eth/scaffold-eth-expo)
- [scaffold-eth-truffle](https://github.com/trufflesuite/scaffold-eth)

# 🔭 Learning Solidity

📕 Read the docs: https://docs.soliditylang.org

📚 Go through each topic from [solidity by example](https://solidity-by-example.org) editing `YourContract.sol` in **🏗 scaffold-eth**

- [Primitive Data Types](https://solidity-by-example.org/primitives/)
- [Mappings](https://solidity-by-example.org/mapping/)
- [Structs](https://solidity-by-example.org/structs/)
- [Modifiers](https://solidity-by-example.org/function-modifier/)
- [Events](https://solidity-by-example.org/events/)
- [Inheritance](https://solidity-by-example.org/inheritance/)
- [Payable](https://solidity-by-example.org/payable/)
- [Fallback](https://solidity-by-example.org/fallback/)

📧 Learn the [Solidity globals and units](https://docs.soliditylang.org/en/latest/units-and-global-variables.html)

# 🛠 Buidl

Check out all the [active branches](https://github.com/scaffold-eth/scaffold-eth/branches/active), [open issues](https://github.com/scaffold-eth/scaffold-eth/issues), and join/fund the 🏰 [BuidlGuidl](https://BuidlGuidl.com)!

- 🚤 [Follow the full Ethereum Speed Run](https://medium.com/@austin_48503/%EF%B8%8Fethereum-dev-speed-run-bd72bcba6a4c)

- 🎟 [Create your first NFT](https://github.com/scaffold-eth/scaffold-eth/tree/simple-nft-example)
- 🥩 [Build a staking smart contract](https://github.com/scaffold-eth/scaffold-eth/tree/challenge-1-decentralized-staking)
- 🏵 [Deploy a token and vendor](https://github.com/scaffold-eth/scaffold-eth/tree/challenge-2-token-vendor)
- 🎫 [Extend the NFT example to make a "buyer mints" marketplace](https://github.com/scaffold-eth/scaffold-eth/tree/buyer-mints-nft)
- 🎲 [Learn about commit/reveal](https://github.com/scaffold-eth/scaffold-eth-examples/tree/commit-reveal-with-frontend)
- ✍️ [Learn how ecrecover works](https://github.com/scaffold-eth/scaffold-eth-examples/tree/signature-recover)
- 👩‍👩‍👧‍👧 [Build a multi-sig that uses off-chain signatures](https://github.com/scaffold-eth/scaffold-eth/tree/meta-multi-sig)
- ⏳ [Extend the multi-sig to stream ETH](https://github.com/scaffold-eth/scaffold-eth/tree/streaming-meta-multi-sig)
- ⚖️ [Learn how a simple DEX works](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90)
- 🦍 [Ape into learning!](https://github.com/scaffold-eth/scaffold-eth/tree/aave-ape)

# 💌 P.S.

🌍 You need an RPC key for testnets and production deployments, create an [Alchemy](https://www.alchemy.com/) account and replace the value of `ALCHEMY_KEY = xxx` in `packages/react-app/src/constants.js` with your new key.

📣 Make sure you update the `InfuraID` before you go to production. Huge thanks to [Infura](https://infura.io/) for our special account that fields 7m req/day!

# 🏃💨 Speedrun Ethereum

Register as a builder [here](https://speedrunethereum.com) and start on some of the challenges and build a portfolio.

# 💬 Support Chat

Join the telegram [support chat 💬](https://t.me/joinchat/KByvmRe5wkR-8F_zz6AjpA) or buidlguidl [discord](https://discord.gg/pRsr6rwG) to ask questions and find others building with 🏗 scaffold-eth!

---

🙏 Please check out our [Gitcoin grant](https://gitcoin.co/grants/2851/scaffold-eth) too!

### Automated with Gitpod

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#github.com/scaffold-eth/scaffold-eth)
