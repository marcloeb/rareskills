# Task 2: Advanced NFT, ERC721, bitmap-based airdrop presale

An Effective NFT Launch, that is gas Efficient. Background is the [Paradigm Guide](https://www.paradigm.xyz/2021/10/a-guide-to-designing-effective-nft-launches) to design an effective NFT Launch

## The Task Intro

1. Your token should make it impossible for smart contracts to mint from
   Done!
2. NFTs should have a nonzero ether cost, so you can withdraw the funds later.
   Done!
3. The NFT should use a state machine to determine if mints can happen, the
   presale is active, or the public sale is active, or the supply has run out. Require
   statements should only depend on the state (except when checking input
   validity)
   Done!
4. Implement a merkle tree airdrop where addresses in the merkle tree are
   allowed to mint once. Measure the gas cost of using a mapping to track if an
   address already minted vs tracking each address with a bit in a bitmap. Hint:
   the merkle leaf should be the hash of the address and its index in the bitmap.
   Use the bitmaps from OpenZeppelin
   Done!
5. Add delegatemulticall to the NFT so people can transfer several NFTs in one
   transaction (make sure people can’t abuse minting!)
   Done!
6. People should be able to assign nicknames to their NFT. The string should not
   be more than 20 characters long. Beware that solidity’s notion of string length
   is very tricky
   Done!
7. Use commit reveal to allocate NFT ids randomly. The reveal should be 10 blocks
   ahead of the commit. Think carefully about how you will handle randomly re-allocating metadata
   Done!
8. Your NFT smart contract address should have 6 or more leading zeros.
   Done!
9. The contract should be owned by a multisignature wallet and only the
   multisignature wallet should be able to withdraw the funds. It is recommended
   to use gnosis safe on polygon
10. Build a wrapping contract that allows people to submit an ERC721 and get an
    ERC1155 back. If they transfer back the ERC1155, they should get back their
    original ERC721. If they transfer the ERC1155 token to another address, and
    that user transfers that ERC1155 token to the wrapper, they should get back
    the original ERC721
    Done!

## The Solution

The solution is found in code. The results of the deployment script for the task 9 is:

```àpache
hh run scripts/deploy.js
Deploying contracts with the account: 0xe04F800c924FeD4cb7a30A4d6Ae21e630cA5385B
Account balance: 13260294097256761935
NFT Airdrop address: 0x9E2cBbe18126dA985278DDbaFb671D46358c80e1
Deployment completed.
Transferring ownership of the contract to the multisig...
✓ Ownership transferred to the multisig at:  0xe04F800c924FeD4cb7a30A4d6Ae21e630cA5385B
```

The contract can be found on [Polygon](https://goerli.etherscan.io/address/0x9E2cBbe18126dA985278DDbaFb671D46358c80e1)

## Conclusion

Wow what a week. As always in software development I think I know most of it and then I get overwhelmed by details - that I finally solve. Here it was not different. The begining was reading, quite a lot, it was about multidelegate call, msg.sender and tx.origin, and a lot about merkle trees, how we can use these for allowlists. And this opened a whole universe of how gas efficient you can do nft presales/airdrops, which are quite common. Merkle trees are not difficult finally, but you need to understand how they are created and how the libraries from openzeppelin work. I am trying to work with foundry and this created an issue because creating merkle proofs and the merkle root is only possible from javascript with hardhat (oh no!). I cannot call javascript from a smart contract so I passed the necessary values, as text to foundry. Together with merkle trees I learned about bitmaps that contain a hash of the address and the index of the nft. This is a very gas efficient way to store the allowlist. That was really cool! Two guys from our course used calldata and metamorphic contract to be even better with gas efficiency for allowlist, but because selfdestruct is depreciated and I lack of time I stopped reading (maybe if I have a really large airdrop I will use this again).

After reading I created a Advanced ERC721, and I checked it is not possible for a smart contract to mint (but foundry is a smart contract so I excluded the owner from this rule). I added the need of the cost of an nft and added the state of the nft (presale, public, out of run). I implemented the merkle tree and check the proof in a bitmap to safe gas. Added a multidelegatecall by leting the nft inherit from a multidelegatecall. Added the possilbility to add nicknames for NFTs through erc721metadata extension. What really took a long time was a commit reveal scheme, understanding what it is. I used the Bored Apes Yacht Club as a template that uses a provenence string over all nfts and calculates a startposition after all nfts are minted. All NFTs can be seen through the metadata, but you dont know the startposition, therefore you cannot speculate to get a better nft with rare traits. I needed to take care about leading zeros in addresses which safe gas and created some with 3 leading zeros. I deployed the smart contract to Poligon and gave the ownership to a gnosis multisig. Finally I created a ERC1155 that wraps a ERC721 token and gives you for this a ERC1155 token back. WHAT A WEEK! COOL! DONE!
Done 🎉️.
