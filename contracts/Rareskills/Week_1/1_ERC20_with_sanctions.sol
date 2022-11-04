// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20withSanction is ERC20, Ownable {
    //Nothing on the blockchain is private, therefore a getter is not necessary.
    //Important: Public variables cannot be changed, just read confusion;-)! So it is more efficient to use public without getter
    //As well parent-child relationship - technically when deploying the parent and child get compressed in one file, so parent variables or functions cannot get accessed by other contracts
    mapping (address=> bool) public banned;
    uint constant internal MAX_SUPPLY=100_000_000 * 10**18; //18 decimals allowed for 100 Mio. tokens ?? this means all transfers happen with lowest level, to transfer one token, an amount of 10**18 needs to be transfered.

    constructor(string memory desc, string memory abr) ERC20(desc,abr) {
    }

    function bannUser(address adr) external onlyOwner{
        require(adr!=owner(),"The owner is not allowed to bann himself.");
        banned[adr] = true;
    }

    function unBannUser(address adr) external onlyOwner {
        require(adr!=owner(),"The owner is not allowed to un-bann himself.");
        banned[adr] = false;
    }

    //if address is banned. In final contracts do not use virtual.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        //max minting of 100 Mio
        require(totalSupply()+amount<=MAX_SUPPLY, "The maximum Token number of 100 Mio. is reached, no more Token can be minted.");
        
        //not allow banned users. to transfer
        require(banned[from]==false,"The user is banned and not able to send tokens.");
        require(banned[to]==false,"The user is banned and not able to receive tokens.");
        
        //call parent
        super._beforeTokenTransfer(from, to, amount);
    }

    function buyTokens()external virtual payable {
        //Conversion 1:1
        _mint(msg.sender, msg.value);
    }

    function sellTokens(uint amount)external virtual payable{   
        //Conversion 1:1      
        require (amount > address(this).balance, "Not enough ether on the contract to make this payout.");
        payable(msg.sender).transfer(amount);
    }

    //this function is quite common, as well a function to get out ether to the owner.
    function getContractBalance()external view onlyOwner virtual returns (uint){
        return address(this).balance;
    }

    //Jeffery commented a payout function commonly used in contracts, so I added this
    function sendEtherToOwner(uint amount)external payable onlyOwner {
        require (amount > address(this).balance, "Not enough ether on the contract to make this payout.");
        payable(owner()).transfer(amount);
    }

    function transferOwnership(address ) public pure override  {
        require(false,"transfer ownership is not allowed");
    }

    function renounceOwnership() public pure override  {
        require(false,"renounce ownership is not allowed");
    }
}