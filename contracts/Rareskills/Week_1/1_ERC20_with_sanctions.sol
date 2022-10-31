// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20withSanction is ERC20, Ownable {
    mapping (address=> bool) private banned;
    uint constant internal MAX_SUPPLY=100_000_000 * 10**18; //18 decimals allowed for 100 Mio. tokens ?? this means all transfers happen with lowest level, to transfer one token, an amount of 10**18 needs to be transfered.

    constructor(string memory desc, string memory abr, uint tokensToMint) ERC20(desc,abr) {
        if(tokensToMint>0)_mint(owner(),tokensToMint);
    }

    function bannUser(address adr) external onlyOwner{
        //require(adr!=owner(),"The owner is not allowed to bann himself.");
        banned[adr] = true;
    }

    function unBannUser(address adr) external onlyOwner {
        require(adr!=owner(),"The owner is not allowed to un-bann himself.");
        banned[adr] = false;
    }

    function isUserBanned(address adr) external view onlyOwner returns (bool){
        if(banned[adr]==true){
            return true;
        }else{
            return false;
        }
    }

    //if address is banned, fail
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        //max minting of 100 Mio
        require(totalSupply()+amount<=MAX_SUPPLY, "The maximum Token number of 100 Mio. is reached, no more Token can be minted.");
        
        //not allow banned users. to transfer
        require(banned[from]==false,"The user is banned and not able to send tokens.");
        require(banned[to]==false,"The user is banned and not able to receive tokens.");
        
        //call parent
        super._beforeTokenTransfer(from, to, amount);
    }
    
}