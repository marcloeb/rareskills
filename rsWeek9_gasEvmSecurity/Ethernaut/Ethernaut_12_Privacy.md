# Ehternaut 12: Privacy

Understanding solidity storage

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {

  bool public locked = true;
  uint256 public ID = block.timestamp;
  uint8 private flattening = 10;
  uint8 private denomination = 255;
  uint16 private awkwardness = uint16(block.timestamp);
  bytes32[3] private data;

  constructor(bytes32[3] memory _data) {
    data = _data;
  }

  function unlock(bytes16 _key) public {
    require(_key == bytes16(data[2]));
    locked = false;
  }
}

```

This is a variation of the previous exercise 8. Here we learn about the storage slots, that they are packed if they are less than 256 - if they are in a row.
First thing to notice is that the data is stored beginning from storage slot 3, and we are interested in storage slot 5.

await web3.eth.getStorageAt(contract.address, 5)
0xc63a8e889300078bd9341476370563d83108c020e3f4a5dbffedf3e10e2f43f3

But this is a 32 byte value, the function parameter from unlock asks for a bytes 16. Solidity handles this that it uses the first 16 bytes. In my case 0xc63a8e889300078bd9341476370563d8.

To unlock the contract I needed to call
await contract.unlock("0xc63a8e889300078bd9341476370563d8")

Done!
