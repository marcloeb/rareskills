# EVM_Puzzles 12: Volt

Understanding solidity storage

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
  bool public locked;
  bytes32 private password;

  constructor(bytes32 _password) {
    locked = true;
    password = _password;
  }

  function unlock(bytes32 _password) public {
    if (password == _password) {
      locked = false;
    }
  }
}
```

This Ethernaut Puzzle asks to read out storage location 1, the private password and initiate the unlock function. I do it in web3 from the firefox console:

1. To get the password I use: await web3.eth.getStorageAt(contract.address, 1)
2. To unlock the contract I use the result:
   await contract.unlock("0x412076657279207374726f6e67207365637265742070617373776f7264203a29")

Done!!!
