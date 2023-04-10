// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/UniDirectionalPaymentChannel.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console.sol";

contract UniDirectionalPaymentChannelTest is Test {
    using ECDSA for bytes32;
    UniDirectionalPaymentChannel channel;
    address public receiver;
    address public sender;

    function setUp() public {
        sender = vm.addr(1);
        receiver = vm.addr(2);
        channel = new UniDirectionalPaymentChannel{value: 1 ether}(payable(sender), payable(receiver));
    }

    function testGenerateSignatureAndCloseChannel() public {
        bytes32 hashMessage = keccak256(abi.encodePacked(address(channel), uint(1 ether))).toEthSignedMessageHash();
        //bytes32 hashMessage = channel.getEthSignedHash(1000000000000000000);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hashMessage);
        bytes memory signature = abi.encodePacked(r, s, v);
        console.log("Signature: ");
        console.logBytes(signature);

        bool result = channel.verify(1000000000000000000, signature);
        console.log("Verify result: ", result);

        assertEq(signature.length, 65);
        vm.startPrank(receiver);
        channel.close(1 ether, signature);
        vm.stopPrank();

        assertEq(receiver.balance, 1 ether);
    }
}
