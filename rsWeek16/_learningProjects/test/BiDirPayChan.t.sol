// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/BiDirectionalPaymentChannel.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console.sol";

contract BiDirectionalPaymentChannelTest is Test {
    using ECDSA for bytes32;
    BiDirectionalPaymentChannel channel;
    address public user1;
    address public user2;
    uint private constant CALLENGEPERIOD = 1 days;
    uint private constant EXPIRESAT = 7 days;

    function setUp() public {
        user1 = vm.addr(1);
        user2 = vm.addr(2);
        address payable[2] memory users = [payable(user1), payable(user2)];
        uint[2] memory balances = [uint(5 ether), uint(5 ether)];

        channel = new BiDirectionalPaymentChannel{value: 10 ether}(users, balances, EXPIRESAT, CALLENGEPERIOD);
    }

    function testGenerateSignatureAndCloseChannel() public {
        uint[2] memory amounts = [uint(1 ether), uint(9 ether)];
        uint nonce = 1;
        bytes32 hashMessage = keccak256(abi.encodePacked(address(channel), amounts, nonce)).toEthSignedMessageHash();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hashMessage);
        bytes memory signature1 = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(2, hashMessage);
        bytes memory signature2 = abi.encodePacked(r, s, v);

        assertEq(signature1.length, 65);
        assertEq(signature2.length, 65);

        console.log("Signature1: ");
        console.logBytes(signature1);
        console.log("Signature2: ");
        console.logBytes(signature2);

        vm.startPrank(user1);
        channel.challengeExit(amounts, nonce, [signature1, signature2]);

        vm.warp(block.timestamp + 2 days);

        channel.withdraw();
        vm.stopPrank();

        assertEq(user1.balance, 1 ether);

        vm.startPrank(user2);
        channel.withdraw();

        assertEq(user2.balance, 9 ether);

        vm.stopPrank();
    }
}
