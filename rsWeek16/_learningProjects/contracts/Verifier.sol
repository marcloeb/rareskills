// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Verifier {
    using ECDSA for bytes32;

    address public verifyingAddress;

    constructor(address _verifyingAddress) {
        verifyingAddress = _verifyingAddress;
    }

    function verifyV1(string calldata message, bytes32 r, bytes32 s, uint8 v) public view {
        bytes32 signedMessageHash = keccak256(abi.encode(message)).toEthSignedMessageHash();
        require(signedMessageHash.recover(v, r, s) == verifyingAddress, "signature not valid v1");
    }

    function verifyV2(string calldata message, bytes calldata signature) public view {
        bytes32 signedMessageHash = keccak256(abi.encode(message)).toEthSignedMessageHash();
        require(signedMessageHash.recover(signature) == verifyingAddress, "signature not valid v2");
    }
}
