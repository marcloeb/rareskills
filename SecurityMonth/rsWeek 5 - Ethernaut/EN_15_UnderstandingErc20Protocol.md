# Ethernaut 15: Naught Coin - understanding the ERC20 protocol

Imports can be tricky, if you dont understand them fully, you might think avoided a certain behaviour of the contract, leaving another alternative way out.

## The Task Intro

When using code that's not your own, it's a good idea to familiarize
yourself with it to get a good understanding of how everything fits
together. This can be particularly important when there are multiple
levels of imports (your imports have imports) or when you are
implementing authorization controls, e.g. when you're allowing or
disallowing people from doing things. In this example, a developer might
scan through the code and think that `transfer` is the only
way to move tokens around, low and behold there are other ways of
performing the same operation with a different implementation.

## The Task Code

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'openzeppelin-contracts-08/token/ERC20/ERC20.sol';

 contract NaughtCoin is ERC20 {

  // string public constant name = 'NaughtCoin';
  // string public constant symbol = '0x0';
  // uint public constant decimals = 18;
  uint public timeLock = block.timestamp + 10 * 365 days;
  uint256 public INITIAL_SUPPLY;
  address public player;

  constructor(address _player)
  ERC20('NaughtCoin', '0x0') {
    player = _player;
    INITIAL_SUPPLY = 1000000 * (10**uint256(decimals()));
    // _totalSupply = INITIAL_SUPPLY;
    // _balances[player] = INITIAL_SUPPLY;
    _mint(player, INITIAL_SUPPLY);
    emit Transfer(address(0), player, INITIAL_SUPPLY);
  }

  function transfer(address _to, uint256 _value) override public lockTokens returns(bool) {
    super.transfer(_to, _value);
  }

  // Prevent the initial owner from transferring tokens until the timelock has passed
  modifier lockTokens() {
    if (msg.sender == player) {
      require(block.timestamp > timeLock);
      _;
    } else {
     _;
    }
  }
}
```

## The Solution

The developer in this contract thought, that he can avoid the transfer of tokens for 10 years - a 10 year staking. Unfortunately there is another transfer method, transferFrom, that allows a user to transfer these tokens. First he needs to approve another account, then the other account can transfer these tokens on behave of the first account.

The right way would have been to override the \_transfer function, that is called by transfer or transferFrom.

Lesson learned: Always read the imported contracts.
