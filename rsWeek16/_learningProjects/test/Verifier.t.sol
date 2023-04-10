// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/Verifier.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console.sol";

contract VerifierTest is Test {
    using ECDSA for bytes32;
    Verifier verifier;

    address owner;
    uint256 privateKey = 0x1010101010101010101010101010101010101010101010101010101010101010;

    function setUp() public {
        owner = vm.addr(privateKey); // public key is generated from private key and first 20 bytes of the public key are used as address
        verifier = new Verifier(owner);
    }

    function testVerifyV1andV2() public {
        string memory message = "attack at dawn";

        bytes32 msgHash = keccak256(abi.encode(message)).toEthSignedMessageHash();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(signature.length, 65);

        console.logBytes(signature);
        verifier.verifyV1(message, r, s, v);
        verifier.verifyV2(message, signature);
    }
}
