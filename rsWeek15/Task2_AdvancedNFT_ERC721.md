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

## Conclusion

Done 🎉️.
