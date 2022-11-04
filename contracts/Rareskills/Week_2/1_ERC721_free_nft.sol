// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract PrimeCatsNFT is ERC721{
    address public immutable owner;
    uint256 public tokenSupply = 0;
    uint256 public constant MAX_SUPPLY = 5;
    uint256 public constant PRICE = 0;

    constructor()ERC721("PrimeCats","PCS"){
        owner = msg.sender;
    }

    function mint()external payable{
        require (tokenSupply< MAX_SUPPLY,"The supply of Prime Cats is used up");
        require (msg.value==PRICE, "wrong Price sent");

        _mint(msg.sender, tokenSupply);
        tokenSupply++;
    }

    function viewBalance() external view returns (uint256){
       return address(this).balance;
    }

    function withdraw() external {
        payable(owner).transfer(address(this).balance);
    }

    function _baseURI() internal pure override returns (string memory) {
        //place metadata Ipfs hash
        return "ipfs://QmWWt3SSntqzxBwnEVfx3reHr6R2ysz7rqiHjrEVLNDQB3/";
    }

}