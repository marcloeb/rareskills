// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./1_ERC20_with_sanctions.sol";
import "hardhat/console.sol";

contract ERC20SaleBuyback is ERC20withSanction {
    uint8 public constant LOSS_BY_SALE = 10;
    uint8 public constant LINEAR_BONDING_CURVE_MULTIPLE = 1;
    uint256 public constant MULTIPLIER = 1;
    uint256 constant MAX_SUPPLY_SBB = 1 * 10**18;

    mapping(address => uint256) public losses;
    uint256 internal allLosses;

    //Purchase event with amount and price
    event Purchase(uint, uint);

    //Sell event with amount, price and loss
    event Sell(uint, uint, uint);

    // solhint-disable-next-line
    constructor() ERC20withSanction("TokenBonding", "TBK") {}

    function buyTokens() external payable override {
        //value is in wei
        //given price, searched amount
        uint tokens = calculateTokenAmountForPrice();
        console.log(tokens);

        //max minting of 100 Mio
        require((totalSupply() + tokens) <= MAX_SUPPLY_SBB, "cannot mint - max supply reached");

        //log
        emit Purchase(msg.value, tokens);

        //mint
        //_mint(msg.sender, tokens);
        _mint(msg.sender, tokens);
    }

    function sellTokens(uint amount) external payable override {
        uint price = calculateSellingPrice(amount);

        //calculate 10% loss
        uint loss = price / LOSS_BY_SALE;
        losses[msg.sender] += loss;
        allLosses += loss;

        //log
        emit Sell(amount, price, loss);

        //burn coins
        _burn(msg.sender, amount);

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
    function calculateTokenAmountForPrice() private view returns (uint256 tokenAmount) {
        //important:
        //value sent is included in contract balance -> no need to add
        //all losses need to be substracted from pool balance.
        //Important 2nd
        //do always multiply FRIST!
        //Comment from Jeffery to be gas efficient: use parameter to give value back, not separate variable
        tokenAmount = sqrt(((address(this).balance - allLosses) * 2) / LINEAR_BONDING_CURVE_MULTIPLE) - totalSupply();
    }

    /**
     * calculetes amount of Ether to pay back
     * Total price for totalSupply (tokens)  => m * 1/2 * x ^ 2
     * where x is the new totalSupply of tokens ./. the selling amount of tokens
     * poolvalue in Ether on contract ./. the calculated value is what we give back
     */
    function calculateSellingPrice(uint amount) private view returns (uint sellingPrice) {
        //Comment from Jeffery to be gas efficient: use parameter to give value back, not separate variable
        sellingPrice =
            address(this).balance -
            allLosses -
            (LINEAR_BONDING_CURVE_MULTIPLE * (totalSupply() - amount) * (totalSupply() - amount)) /
            2;
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
