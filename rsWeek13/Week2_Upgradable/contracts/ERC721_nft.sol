// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyNFTUpgradable is ERC721EnumerableUpgradeable {
    function initialize(address owner) public initializer {
        //address owner = msg.sender;
        __ERC721Enumerable_init();
        __ERC721_init("NFTme", "NME");
        //owner is smart contract ;-)
        _mint(owner, 1); // mint nft to owner
        _approve(msg.sender, 1);
        _mint(owner, 2);
        _approve(msg.sender, 2);
        _mint(owner, 3);
        _approve(msg.sender, 3);
        _mint(owner, 4);
        _approve(msg.sender, 4);
        _mint(owner, 5);
        _approve(msg.sender, 5);
        _mint(owner, 6);
        _approve(msg.sender, 6);
        _mint(owner, 7);
        _approve(msg.sender, 7);
        _mint(owner, 8);
        _approve(msg.sender, 8);
        _mint(owner, 9);
        _approve(msg.sender, 9);
        _mint(owner, 10);
        _approve(msg.sender, 10);
    }

    function version() public pure returns (uint8) {
        return 1;
    }
}
