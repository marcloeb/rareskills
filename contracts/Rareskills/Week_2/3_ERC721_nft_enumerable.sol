// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NftEnumerable is ERC721Enumerable{
    address public game;
    constructor()ERC721("NFTme","NME"){
        //owner is smart contract ;-)
        _mint(msg.sender, 1);
        _mint(msg.sender, 2);
        _mint(msg.sender, 3);
        _mint(msg.sender, 4);
        _mint(msg.sender, 5);
        _mint(msg.sender, 6);
        _mint(msg.sender, 7);
        _mint(msg.sender, 8);
        _mint(msg.sender, 9);
        _mint(msg.sender, 10);
        _mint(msg.sender, 11);
        _mint(msg.sender, 12);
        _mint(msg.sender, 13);
        _mint(msg.sender, 14);
        _mint(msg.sender, 15);
        _mint(msg.sender, 16);
        _mint(msg.sender, 17);
        _mint(msg.sender, 18);
        _mint(msg.sender, 19);
        _mint(msg.sender, 20);
    }
}

contract Second {
    ERC721Enumerable nft;
    event Prime(uint256);

    constructor(ERC721Enumerable _nft){
        nft = _nft;
    }

    function ownedNFTsFilterPrimeNumber(address adr) external returns (uint){
        //result variable
        uint primeCount;

        //iterate (check https://www.youtube.com/watch?v=hL5uPgEAuIo for details)
        uint256 tokenCount = nft.balanceOf(adr); //total owned tokens
        for(uint256 i; i< tokenCount; i++){
            //gets tokenid at index i
            uint256 tokenId = nft.tokenOfOwnerByIndex(adr,i); 
            
            //ignore tokenId of 0 and 1, these are no prime numbers.
            if(tokenId==0 || tokenId==1)continue; 

            //check prime numbers
            if(isPrime(tokenId)==true){
                primeCount++;
                emit Prime(tokenId);
            }
        }
        return primeCount;
    }


    function isPrime(uint256 n) private pure returns (bool) {
        for (uint256 i = 2; i < n; i++) {
            if (n % i == 0) {
                return false;
            }
        }
        return true;
    }
}