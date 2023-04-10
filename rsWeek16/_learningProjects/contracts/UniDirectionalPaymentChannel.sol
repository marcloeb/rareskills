// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
https://solidity-by-example.org/app/uni-directional-payment-channel/

Payment channels allow participants to repeatedly transfer Ether off chain.

Here is how this contract is used:

Alice deploys the contract, funding it with some Ether:
- Alice authorizes a payment by signing a message (off chain) and sends the signature to Bob.
- Bob claims his payment by presenting the signed message to the smart contract.
- If Bob does not claim his payment, Alice get her Ether back after the contract expires

This is called a uni-directional payment channel since the payment can go only in a single direction from Alice to Bob.
*/

contract UniDirectionalPaymentChannel is ReentrancyGuard {
    using ECDSA for bytes32;

    address payable public sender;
    address payable public receiver;

    uint private constant DURATION = 7 * 24 * 60 * 60;
    uint public expiresAt;

    constructor(address payable _sender, address payable _receiver) payable {
        require(_receiver != address(0), "receiver = zero address");
        sender = payable(_sender);
        receiver = _receiver;
        expiresAt = block.timestamp + DURATION;
    }

    function _getHash(uint _amount) private view returns (bytes32) {
        // NOTE: sign with address of this contract to protect agains
        // replay attack on other contracts
        return keccak256(abi.encodePacked(address(this), _amount));
    }

    function _getEthSignedHash(uint _amount) private view returns (bytes32) {
        return _getHash(_amount).toEthSignedMessageHash();
    }

    function _verify(uint _amount, bytes memory _sig) private view returns (bool) {
        return _getEthSignedHash(_amount).recover(_sig) == sender;
    }

    function close(uint _amount, bytes memory _sig) external nonReentrant {
        require(msg.sender == receiver, "!receiver");
        require(_verify(_amount, _sig), "invalid sig");

        (bool sent, ) = receiver.call{value: _amount}("");
        require(sent, "Failed to send Ether");
        selfdestruct(sender);
    }

    function cancel() external {
        require(msg.sender == sender, "!sender");
        require(block.timestamp >= expiresAt, "!expired");
        selfdestruct(sender);
    }

    function getHash(uint _amount) external view returns (bytes32) {
        return _getHash(_amount);
    }

    function getEthSignedHash(uint _amount) external view returns (bytes32) {
        return _getEthSignedHash(_amount);
    }

    function verify(uint _amount, bytes memory _sig) external view returns (bool) {
        return _verify(_amount, _sig);
    }
}
