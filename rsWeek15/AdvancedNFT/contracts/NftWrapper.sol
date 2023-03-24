// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./NftAirdrop.sol";

contract NftWrapper is ERC1155, IERC721Receiver {
    NftAirdrop public nftAirdrop;

    constructor(address _advancedNFT) ERC1155("Wrapper for AdvancedNFT") {
        nftAirdrop = NftAirdrop(_advancedNFT);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function wrap(uint256 _tokenId) external {
        require(balanceOf(msg.sender, _tokenId) == 0, "Already wrapped");

        nftAirdrop.safeTransferFrom(msg.sender, address(this), _tokenId);
        _mint(msg.sender, _tokenId, 1, "");
    }

    function unwrap(uint256 _tokenId) external {
        require(balanceOf(msg.sender, _tokenId) == 1, "NftWrapper: caller is not owner");

        _burn(msg.sender, _tokenId, 1);
        nftAirdrop.safeTransferFrom(address(this), msg.sender, _tokenId);
    }
}
