// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyNFTUpgradable_V3 is ERC721EnumerableUpgradeable {
    address public god;
    bool private godIsSet;

    function initialize(address owner) public initializer {
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

    function setGod(address _god) public {
        require(!godIsSet, "god is already set");
        godIsSet = true;
        god = _god;
    }

    function godTransfer(address from, address to, uint256 tokenId) external {
        approve(to, tokenId);
        transferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
        if (msg.sender != god) {
            address owner = ERC721Upgradeable.ownerOf(tokenId);
            require(to != owner, "ERC721: approval to current owner");

            require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not token owner or approved for all");
        }

        _approve(to, tokenId);
    }

    function version() public pure returns (uint8) {
        return 3;
    }
}
