// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";

import "contracts/MerkleTree.sol";

contract MerkleTreeTest is Test {
    MerkleProof merkleProof;
    bytes32[] public hashes;

    /*
                     0                (root)
            0        -        1       (1st level))  
        0   -   1         2   -   3   (leafs)

        Verify that 3rd leaf element with index 2 is in the tree. Proof needed:
        1. 4th leaf hash with index 3
        2. 1st level hash with index 0
    */
    function setUp() public {
        merkleProof = new MerkleProof();
        string[4] memory transactions = ["alice -> bob", "bob -> dave", "carol -> alice", "dave -> bob"];

        for (uint i = 0; i < transactions.length; i++) {
            hashes.push(keccak256(abi.encodePacked(transactions[i])));
        }

        uint n = transactions.length;
        uint offset = 0;

        while (n > 0) {
            for (uint i = 0; i < n - 1; i += 2) {
                hashes.push(keccak256(abi.encodePacked(hashes[offset + i], hashes[offset + i + 1])));
            }
            offset += n;
            n = n / 2;
        }
    }

    function testMerkleProof() public {
        //proof
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = get4rdLeaf();
        proof[1] = get1stLevel1();

        //verify 3rd leaf is in the tree
        assertTrue(merkleProof.verify(proof, getRoot(), verify3rdIsInTree(), 2));
    }

    function getRoot() private view returns (bytes32) {
        return hashes[hashes.length - 1]; // 0xcc086fcc038189b4641db2cc4f1de3bb132aefbd65d510d817591550937818c7
    }

    function verify3rdIsInTree() private view returns (bytes32) {
        return hashes[2]; // 0xdca3326ad7e8121bf9cf9c12333e6b2271abe823ec9edfe42f813b1e768fa57b
    }

    function get4rdLeaf() private view returns (bytes32) {
        return hashes[3]; //    0x8da9e1c820f9dbd1589fd6585872bc1063588625729e7ab0797cfc63a00bd950
    }

    function get1stLevel1() private view returns (bytes32) {
        return hashes[4]; //    0x995788ffc103b987ad50f5e5707fd094419eb12d9552cc423bd0cd86a3861433
    }
}
