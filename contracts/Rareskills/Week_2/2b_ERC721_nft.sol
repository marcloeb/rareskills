// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MyNFT is ERC721Enumerable{
    constructor(address owner)ERC721("NFTme","NME"){
        //owner is smart contract ;-)
        _mint(owner, 1); // mint nft to owner
        _approve(msg.sender,1);
        _mint(owner, 2);
        _approve(msg.sender,2);
        _mint(owner, 3);
        _approve(msg.sender,3);
        _mint(owner, 4);
        _approve(msg.sender,4);
        _mint(owner, 5);
        _approve(msg.sender,5);
        _mint(owner, 6);
        _approve(msg.sender,6);
        _mint(owner, 7);
        _approve(msg.sender,7);
        _mint(owner, 8);
        _approve(msg.sender,8);
        _mint(owner, 9);
        _approve(msg.sender,9);
        _mint(owner, 10);
        _approve(msg.sender,10);
    }
}