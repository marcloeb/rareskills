# Task 1: Reading the Docs

Learn the weeks theory. The week is about Multicall, Multidelegatecall (with exploits), Iterable maps and sets, only EOA contract execution, String length, Commit reveal, merkle Trees and a revisit of multisig.

## Multidelegate Call

Is tought through a [Video](https://www.youtube.com/watch?v=NkTWU6tc9WU) and a [Solidity by Example Code](https://solidity-by-example.org/app/multi-delegatecall/). I replicated the sample in the MultiDelegateCall folder. Learnings here are watch out for msg.value - it can easily be duplicated.

## msg.sender and tx.origin

Jeff made a nice [video](https://www.youtube.com/watch?v=FKgLqsMrURE) about this: In certain situations it is important to make sure that the caller is an externally owned account (EOA). There are two possiblitities to do this:

- msg.sender == tx.origin
- msg.sender.code.length == 0

The first needs to be used with caution, because multisig wallets cannot be used. The second allows multisig wallets, but it is not possible to use it in a constructor.

## Merkle Trees for gas efficient airdrops

> Merkle tree allows you to cryptographically prove that an element is contained in a set without revealing the entire set.
>
> You can create a cryptographic proof, that a transaction was included in a block, without creating a hash over all transaction, a fraction of log2 is necessary, eg. with 1000 transaction just about 10 would be enough.

With merkle trees I was supplied with a GitHub sample [PrivateSaleBenchmark](https://github.com/DonkeVerse/PrivateSaleBenchmark/blob/main/contracts/Benchmark.sol). Our tasks is to watch videos about merkle trees. I watched:

- [Merkle Tree in Blockchain: What is it, How does it work and Benefits](https://www.simplilearn.com/tutorials/blockchain-tutorial/merkle-tree-in-blockchain)
- [Blockchain Basics Explained - Hashes with Mining and Merkle trees](https://www.youtube.com/watch?v=lik9aaFIsl4)
- [Learn Solidity (0.5) - Merkle Tree](https://www.youtube.com/watch?v=n6nEPaE7KZ8)
- [Merkle Tree Solidity By Example](https://solidity-by-example.org/app/merkle-tree/)
- [Merkle tree on Wiki](https://en.wikipedia.org/wiki/Merkle_tree)
- [Solidity RSA signatures for aidrops and presales: Beating ECDSA and Merkle Trees in Gas Efficiency](https://hackernoon.com/using-solidity-rsa-signatures-for-presales-and-airdrops)

Merkle Trees have the advantage over [Hash Lists](https://en.wikipedia.org/wiki/Hash_list), that you can verify a single leaf without having to verify the whole tree, just a part of it. This makes Merkle Trees more efficient than Hash Lists (log2 of hashlist). I added a MerkleTree.sol file to the contract folder and a corresponging test file

## OpenZeppelin Bitmap for gas efficient airdrops

BitMaps are used in NFT Minting to safe gas, as Jeffrey Scholz discusses in his 3 part post [Hardcore Gas Savings in NFT Minting](https://medium.com/donkeverse/hardcore-gas-savings-in-nft-minting-part-3-save-30-000-in-presale-gas-c945406e89f0). The OpenZeppelin Bitmap is used to store the NFTs. The Bitmap is a library and can be found [here](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/BitMaps.sol).

Airdrops allow a limited number of people to claim a token or nft. There are 3 ways to do this:

- With an accessList (mapping) -> problem: gas costs for writing to the mapping (MStore is very expensive in gas)
- With a bitmap -> Much better, because it uses only one bit

# Alternative to ECDSA and Merkle trees with better Gas efficiency

A few fellows of Rareskills understood in week 15, the week that I am working on, that there is an alternative way for airdrops: using RSA signatures and metamorph contracts. They achieved better gas efficency than the other two algorithms. In the remaining weeks of the bootcamp I will learn about elliptic curve encryption and RSA encryption. Therefore this is just for inormation purposes, not to solve the task of the week. I read the following posts:

- [Beating ECDSA and Merkle Trees in Gas Efficiency](https://hackernoon.com/using-solidity-rsa-signatures-for-presales-and-airdrops)
- [RSA Algorithm - How does it work? - I'll PROVE it with an Example!](https://www.youtube.com/watch?v=Pq8gNbvfaoM)
- [RareSkills/RSA-presale-allowlist: Project implementing the metamorphic contracts](https://github.com/RareSkills/RSA-presale-allowlist?ref=hackernoon.com)
- [A JavaScript library to generate merkle trees and merkle proofs](https://github.com/OpenZeppelin/merkle-tree)

One thing I realized while working - I did not find a foundry library for generating Merkle Trees and Merkle Proofs. There is a library for javascript from OpenZeppelin, but not for Solidity. Funny fact, would be an interesting project to do myself.

## Gnosis Safe revisited

I was working with Gnosis safe 3 weeks ago in a Damn Vulnerable Defi project. I revisited the code and the [documentation](https://docs.gnosis-safe.io). I also watched the [intro video](https://www.youtube.com/watch?v=y9zNmlzg8AI) about the Gnosis Safe.

## Vanity address and String length

> **Vanity addresses, or vanity addresses, are cryptocurrency addresses personalized and created respecting a series of parameters given by the users of said addresses. This with the aim of making them more personal and easily identifiable, but without giving up the security they provide. [What is a Vanity Address?](https://academy.bit2me.com/en/que-es-una-vanity-address/)**

How are addresses created? I read [How to generate a vanity address for a smart contract to be deployed on](https://ethereum.stackexchange.com/questions/10241/how-to-generate-a-vanity-address-for-a-smart-contract-to-be-deployed-on)

String length are not available by default, but the Ethereum Naming Service created a function public on [github](https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/StringUtils.sol), explained in depth by [pateldeep.eth How to Find Length of String in Solidity](https://betterprogramming.pub/in-the-world-of-javascript-finding-the-length-of-string-is-such-an-easy-thing-just-do-str-length-4b4b33dbed09)

## Commit Reveal Scheme on Ethereum

Sometimes it is not good to reveal all information when you make the transaction, because metadata of NFTs show. There is a [Commit Reveal Scheme](https://go.gitcoin.co/blog/commit-reveal-scheme-on-ethereum) used on Ethereum, presented by Gitcoin Labs.

The Boared Ape Commit Reveal can be checkt on [Etherscan](https://etherscan.io/address/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d#code)

Provenence Hashes are a solution for the commit reveal scheme discussed by [Richmond Lee](https://medium.com/coinmonks/the-elegance-of-the-nft-provenance-hash-solution-823b39f99473)

Done 🎉️.
