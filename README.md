# Rareskills https://www.rareskills.io

These are my solutions to the assignments at Rareskills. This bootcamp has the value proposition "Get personal coaching for four months from blockchain industry experts, then get recruited to top web3 companies". I applied, because it is one of the few bootcamps out there. I passed the coding test and Jeffrey Scholz and his team convinced me with their knowldege and industry expertise - so I joined the October cohort 2022. I am happy to be part of the bootcamp.

--- Week one: ERC 20 ---

I created ERC 20 Token contracts with OpenZeppelin, worked on user management, and finally on a linear bonding curve for setting a price for buying and selling a token. I got to know the Remix Dev Environemnt, all browser based. At the end of the week I added test case to debug. A very cool feature is Solidity debugging, which helped me a lot.
worked with Remix and Solidity testing.

--- Week two: ERC 721 ---

This week I had to create first a some images, that I placed to the ipfs. From there I created my first NFT ERC721 contract and deployed my nfts, now visible on polygon (https://mumbai.polygonscan.com/address/0x7093CFC26ea2C1a41165e1C9D88173603375027F). I named them Prime Cats ;-). Of course I know the NFT boom is already over, but still a cool thing! Important to verify the contract on polygon. The second task was the most challenging one, a staking contract for NFTs and rewarding the user with 10 tokens every 24h. Not sure how I did this, we will see. A contract gets fast complex and with remix alone it is hard to debug and ensure quality. I assume that's why the next week we go into testing and other tools than remix. Great ;-).

--- Week three: All about hardhat testing ---

Hardhat is a cool tool to learn. It is created by a foundation that wants to make the tool the best ones and it seems to be so good, that developer start to prefer it over truffle. I don't know truffle, so I cannot tell. I was doing my first 2 weeks only in Remix and was starting to miss the browser environment with included debugging feature. But hey, that's how you feel when you like something and do not want to learn something new - hardhat revealed itself to me as a stable tool that does its job. It integrates in VS Code and its command line is extensible. In one week of course I did not grasp everything, but I was able to migrate from remix and write several tests and found quite some bugs I still had in the assignments of week 1 and 2. Smart Contract development is hard and impossible without tests. And writing tests in hardhat is much more flexible than in remix, and more stable. We worked with solhint and prettier to find bugs and format the code to a pro level, finally used static code analysis with slither. Used mutation testing (wow, kill the mutants) and finally played ethernaut. A quite busy week. I feel gain streched ;-).

--- Week four: Integrate smart contracts with a web frontend ---

Week 4 was the toughest for me. We got the task to create a webapp for a smart contract - a game where you can mint and burn tokens, this time an ERC1155 Multitoken standard, that can store multiple tokens of ERC20 or ERC721 - The idea behind this contract is to reduce transaction costs when you need to create/burn/transfer multiple tokens. The work on the contract was not that hard, openzeppelin quite fast read. The big challenge, and this was mentioned, was creating a working webapp. I have a database, PHP, Wordpress background - here we agreed to work on Next.js. It was open to us what to use, but hey, why not learn more? We were encouraged to learn something new, but not overinvest with tutorials. That was a tough one, because I love to learn with videos. Still one thing is clear, after watching 20h of video you have not created anything and still have to create your first app, so why not create it immediately???

Well, I managed after working through 4h tutorials on react and starting with a sample that I copied together from many places. I learned react piece by piece myself. Finally the difficult parts of integrating with metamask was necessary, connecting with hardhat development server. I prefered this over Ganage, that I read does not give stack traces back. It was a good choice. So I was able to create a working solution locally, debug issues, understand metamask and I think this was a fair approach on reading docs, listening to tutorials and working on code myself in try and error - combined with grabbing code samples and understanding these.

It was a long week, I hope the next ones are a bit less intense. Here you see my solution - that was the best, with Vercel you are able to deploy very easy from your git repository to a website. Open Source Pure.

https://rareskills.vercel.app

--- Week five: Advance concepts of Solidity ---

**\*** Follows **\***
