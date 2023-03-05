// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract StrangeV4 {
    bool check1;
    address private strangeContract;
    bytes32 private codeHash;
    uint256 private codeLength;

    constructor() payable {
        require(msg.value == 1 ether);
    }

    function initialize(address _contract) external {
        require(_contract.code.length != 0, "target must be a contract");
        codeHash = _contract.codehash;
        strangeContract = _contract;
    }

    function success(address _contract) external {
        require(_contract.code.length != 0, "must be a contract");
        require(_contract == strangeContract, "must be the same contract");
        require(_contract.codehash != codeHash, "contract isn't strange");
        uint256 bal;
        assembly {
            bal := selfbalance()
        }
        payable(msg.sender).transfer(bal);
    }
}
