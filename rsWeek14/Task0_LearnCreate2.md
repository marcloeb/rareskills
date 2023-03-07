# Task 0: Learn about Create2

How to deploy a contract to a deterministic address

## The Task Intro

Understanding Create2 as a task was not explicitly mentioned, but needed to understand the following work, therefore I started here.

## The Solution

I watched a video about [Create2](https://www.youtube.com/watch?v=883-koWrsO4) on youtube and read the [solidity docs for create2](https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2). I went through the sample of the video step by step - you see the code below. What I learned is this:

- Create2 enables to deploy a contract to one deterministic address
- This deterministic address cannot be set, but it is calculated
- The calculation works by new address = first 20 bytes of keccak256(0xff + address(this) + s + keccak256(mem[p…(p+n))) // where s = salt 256-bit uint
- The exists an init Bytecode = Code of the Constructor that does initialization work and returns the runtime ByteCode, getting stored on the blockchain as contract
- create2 can be called in solidity only by creating a new class and adding a salt in curly braces
- create2 can be called in assembly/YUL as described in [evm.codes](https://www.evm.codes/)

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Factory {
    // Returns the address of the newly deployed contract
    function deploy(
        address _owner,
        uint _salt
    ) public payable returns (address) {
        // This syntax is a newer way to invoke create2 without assembly, you just need to pass salt
        // https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
        return address(new TestContract{salt: bytes32(_salt)}(_owner));
    }
}

// This is the older way of doing it using assembly
contract FactoryAssembly {
    event Deployed(address addr, uint salt);

    // 1. Get bytecode of contract to be deployed
    // NOTE: _owner and _foo are arguments of the TestContract's constructor
    function getBytecode(address _owner) public pure returns (bytes memory) {
        bytes memory bytecode = type(TestContract).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_owner));
    }

    // 2. Compute the address of the contract to be deployed
    // NOTE: _salt is a random number used to create an address
    function getAddress(
        address sender,
        bytes memory bytecode,
        uint _salt
    ) public pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), sender, _salt, keccak256(bytecode))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }

    // 3. Deploy the contract
    // NOTE:
    // Check the event log Deployed which contains the address of the deployed TestContract.
    // The address in the log should equal the address computed from above.
    function deploy(bytes memory bytecode, uint _salt) public payable {
        address addr;

        /*
        NOTE: How to call create2

        create2(v, p, n, s)
        create new contract with code at memory p to p + n
        and send v wei
        and return the new address
        where new address = first 20 bytes of keccak256(0xff + address(this) + s + keccak256(mem[p…(p+n)))
              s = big-endian 256-bit value
        */
        assembly {
            addr := create2(
                callvalue(), // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(bytecode, 0x20),
                mload(bytecode), // Load the size of code contained in the first 32 bytes
                _salt // Salt from function arguments
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, _salt);
    }
}

contract TestContract {
    address public owner;
    uint public foo;

    constructor(address _owner) payable {
        owner = _owner;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
```

## Conclusion

The following tasks of methamorphic and dimond contract pattern, as well the exploit constructor build on the understanding of create2. It took me quite some time to understand create2, but it was worth it in hindsight - it is not an obvious function.
