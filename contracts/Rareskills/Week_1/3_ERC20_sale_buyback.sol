// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./1_ERC20_with_sanctions.sol";

contract ERC20SaleBuyback is ERC20withSanction {
    uint8 constant LOSS_BY_SALE = 10;
    uint8 constant LINEAR_BONDING_CURVE_MULTIPLE = 1;
    uint256 constant MULTIPLIER = 1;

    mapping(address=>uint256) public losses;
    uint256 internal allLosses;
    
    event Logging(string, uint, uint);

    constructor() ERC20withSanction("TokenBonding", "TBK",0) {         
    }
    
    function buyTokens()external payable{ //value is in wei
        //given price, searched amount
        uint tokens = calculateTokenAmountForPrice();

        //log
        emit Logging("buying", tokens, 0);

        //mint
        //_mint(msg.sender, tokens);
        _mint(msg.sender, tokens);
    }

    
    function sellTokens(uint amount)external payable{ 
        uint price = calculateSellingPrice(amount);
        
        //calculate 10% loss
        uint loss = price / LOSS_BY_SALE;
        losses[msg.sender]+= loss;
        allLosses += loss;

        //log
         emit Logging("sell", price, loss);

        //burn coins
        _burn(msg.sender, amount);

        //send back ether with 10% loss
        //payable(msg.sender).transfer(price - loss);
        
        payable(msg.sender).transfer(price - loss);

    }


    /**
    * calculetes amount of tokens to mint for give Eth amount
    * area = (x*y)/2 <-- x=Y therefore x ^ 2, but even when y!=x, y can be defined as x*m, making next line
    * area = m * 1/2 * x ^ 2 <- total price of all tokens
    * poolBalance + msg.value = m * 1/2 * (totalSupply_ + newTokens) ^ 2 <-- reserve (ether) = f(supply +new tokens), linear bonding curve
    * (poolBalance + msg.value)*2/m = (totalSupply_ + newTokens) ^ 2
    * sqrt((poolBalance + msg.value)*2/m)= (totalSupply_ + newTokens)
    */
    function calculateTokenAmountForPrice() private view returns(uint256 tokenAmount) {
        //important: 
        //value sent is included in contract balance -> no need to add
        //all losses need to be substracted from pool balance.
        tokenAmount = sqrt((address(this).balance - allLosses) * 2 / LINEAR_BONDING_CURVE_MULTIPLE) - totalSupply() ;
    }

    /**
    * calculetes amount of Ether to pay back
    * Total price for totalSupply (tokens)  => m * 1/2 * x ^ 2
    * where x is the new totalSupply of tokens ./. the selling amount of tokens
    * poolvalue in Ether on contract ./. the calculated value is what we give back
    */
    function calculateSellingPrice(uint amount)private view returns (uint){        
        uint newMarketCap = LINEAR_BONDING_CURVE_MULTIPLE * (totalSupply()- amount) * (totalSupply()- amount) / 2 ;
        uint sellingPrice = address(this).balance - allLosses - newMarketCap;
        return sellingPrice;
    }

    function sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}