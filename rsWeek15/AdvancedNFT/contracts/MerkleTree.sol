// // SPDX-License-Identifier: MIT

// pragma solidity 0.8.18;


// library StandardMerkleTree {
//     struct Data {
//         string format;
//         string[] tree;
//         Value[] values;
//         string[] leafEncoding;
//     }

//     struct Value {
//         bytes[] value;
//         uint256 treeIndex;
//     }

//     struct Tree {
//         mapping(bytes32 => uint256) hashLookup;
//         bytes32[] tree;
//         Value[] values;
//         string[] leafEncoding;
//     }

//     function standardLeafHash(bytes[][] memory value, string[] memory types) internal pure returns (bytes32) {
//         return keccak256(abi.encodePacked(keccak256(defaultAbiCoder.encode(types, value))));
//     }

//     // function of(bytes[][] memory values, string[] memory leafEncoding) internal pure returns (Tree memory) {
//     //     bytes32[][] memory hashedValues = new bytes32[][](values.length);
//     //     for (uint256 i = 0; i < values.length; i++) {
//     //         hashedValues[i] = [standardLeafHash([values[i]], leafEncoding)];
//     //     }

//     //     bytes32[] memory tree = makeMerkleTree(hashedValues);

//     //     Value[] memory indexedValues = new Value[](values.length);
//     //     for (uint256 i = 0; i < hashedValues.length; i++) {
//     //         uint256 leafIndex = hashedValues.length - i - 1;
//     //         indexedValues[i].value = values[i];
//     //         indexedValues[i].treeIndex = tree.length - leafIndex - 1;
//     //     }

//     //     Tree memory t;
//     //     t.tree = tree;
//     //     t.values = indexedValues;
//     //     t.leafEncoding = leafEncoding;

//     //     for (uint256 i = 0; i < indexedValues.length; i++) {
//     //         bytes32 leafHash = keccak256(abi.encodePacked(standardLeafHash([indexedValues[i].value], leafEncoding)));
//     //         t.hashLookup[leafHash] = i;
//     //     }

//     //     return t;
//     // }

//     function load(Data memory data) internal pure returns (Tree memory) {
//         require(keccak256(bytes(data.format)) == keccak256(bytes("standard-v1")), "Unknown format");

//         bytes32[] memory tree = new bytes32[](data.tree.length);
//         for (uint256 i = 0; i < data.tree.length; i++) {
//             tree[i] = hexToBytes(data.tree[i]);
//         }

//         Tree memory t;
//         t.tree = tree;
//         t.values = data.values;
//         t.leafEncoding = data.leafEncoding;

//         for (uint256 i = 0; i < t.values.length; i++) {
//             bytes32 leafHash = keccak256(abi.encodePacked(standardLeafHash([t.values[i].value], t.leafEncoding)));
//             t.hashLookup[leafHash] = i;
//         }

//         return t;
//     }

//     function verify(string memory root, string[] memory leafEncoding, bytes[][] memory leaf, string[] memory proof) internal pure returns (bool) {
//         bytes32 impliedRoot = processProof(keccak256(abi.encodePacked(standardLeafHash(leaf, leafEncoding))), proof);
//         return equalsBytes(impliedRoot, hexToBytes(root));
//     }

//     function dump(Tree memory self) internal pure returns (Data memory) {
//         Data memory data;
//         data.format = 'standard-v1';
//         data.tree = new string[](self.tree.length);
//         for (uint256 i = 0; i < self.tree.length; i++) {
//             data.tree[i] = (self.tree[i]);
//         }
//         data.values = self.values;
//         data.leafEncoding = self.leafEncoding;
//         return data;
//     }

//     function root(Tree memory self) internal view returns (string memory) {
//         return (self.tree[0]);
//     }

//     function entries(Tree memory self) internal pure returns (Value[] memory) {
//         return self.values;
//     }

//     function validate(Tree memory self) internal view {
//         for (uint256 i = 0; i < self.values.length; i++) {
//             validateValue(self, i);
//         }
//         require(isValidMerkleTree(self.tree), "Merkle tree is invalid");
//     }

//     function leafHash(Tree memory self, bytes[][] memory leaf) internal pure returns (bytes32) {
//         return keccak256(abi.encodePacked(standardLeafHash(leaf, self.leafEncoding)));
//     }

//     function leafLookup(Tree memory self, bytes[][] memory leaf) internal view returns (uint256) {
//         bytes32 leafHash = keccak256(abi.encodePacked(standardLeafHash(leaf, self.leafEncoding)));
//         require(self.hashLookup[leafHash] != 0, "Leaf is not in tree");
//         return self.hashLookup[leafHash] - 1;
//     }

//     function getProof(Tree memory self, uint256 leaf) internal view returns (string[] memory) {
//         validateValue(self, leaf);

//         uint256 treeIndex = self.values[leaf].treeIndex;
//         bytes32[] memory proof = getProof(self.tree, treeIndex);

//         require(_verify(self.tree[treeIndex], proof), "Unable to prove value");

//         string[] memory proofHex = new string[](proof.length);
//         for (uint256 i = 0; i < proof.length; i++) {
//             proofHex[i] = (proof[i]);
//         }

//         return proofHex;
//     }

//     function getMultiProof(Tree memory self, uint256[] memory leaves) internal view returns (string memory, bytes[] memory ) {
//         Value[] memory values = new Value[](leaves.length);
//         bytes32[] memory hashes = new bytes32[](leaves.length);
//         for (uint256 i = 0; i < leaves.length; i++) {
//             uint256 valueIndex = leaves[i];
//             validateValue(self, valueIndex);

//             values[i] = self.values[valueIndex];
//             hashes[i] = keccak256(abi.encodePacked(standardLeafHash([values[i].value], self.leafEncoding)));
//         }

//         uint256[] memory indices = new uint256[](leaves.length);
//         for (uint256 i = 0; i < leaves.length; i++) {
//             indices[i] = self.values[leaves[i]].treeIndex;
//         }

//         MultiProof<bytes32, bytes32> memory proof = getMultiProof(self.tree, indices);

//         require(_verifyMultiProof(proof), "Unable to prove values");

//         bytes[][] memory leafValues = new bytes[][](leaves.length);
//         for (uint256 i = 0; i < leaves.length; i++) {
//             leafValues[i] = values[i].value;
//         }

//         string[] memory proofHex = new string[](proof.proof.length);
//         for (uint256 i = 0; i < proof.proof.length; i++) {
//             proofHex[i] = hex(proof.proof[i]);
//         }

//         return MultiProof<string memory, bytes[] memory>({
//             leaves: leafValues,
//             proof: proofHex,
//             proofFlags: proof.proofFlags,
//         });
//     }

//     function verify(Tree memory self, bytes[][] memory leaf, string[] memory proof) internal view returns (bool) {
//         return _verify(self, keccak256(abi.encodePacked(standardLeafHash(leaf, self.leafEncoding))), proof);
//     }

//     function _verify(Tree memory self, bytes32 leafHash, bytes32[] memory proof) internal view returns (bool) {
//         bytes32 impliedRoot = processProof(leafHash, proof);
//         return equalsBytes(impliedRoot, self.tree[0]);
//     }

//     function verifyMultiProof(MultiProof<string, number | T> memory multiproof) public view returns (bool) {
//         Bytes[] memory leaves = new Bytes[](multiproof.leaves.length);
//         for (uint i = 0; i < multiproof.leaves.length; i++) {
//             leaves[i] = getLeafHash(multiproof.leaves[i]);
//         }
//         return _verifyMultiProof(MultiProof<Bytes, Bytes>(leaves, multiproof.proof.map(hexToBytes), multiproof.proofFlags));
//     }

//     function _verifyMultiProof(MultiProof<Bytes, Bytes> memory multiproof) private view returns (bool) {
//         Bytes memory impliedRoot = processMultiProof(multiproof);
//         return equalsBytes(impliedRoot, tree[0]);
//     }

//     function validateValue(uint valueIndex) private view returns (Bytes memory) {
//         checkBounds(values, valueIndex);
//         Value storage val = values[valueIndex];
//         checkBounds(tree, val.treeIndex);
//         Bytes memory leaf = standardLeafHash(val.value, leafEncoding);
//         if (!equalsBytes(leaf, tree[val.treeIndex])) {
//             revert('Merkle tree does not contain the expected value');
//         }
//         return leaf;
//     }

//     function getLeafHash(uint leaf) private view returns (Bytes memory) {
//         return validateValue(leaf);
//     }

//     function getLeafHash(T leaf) private view returns (Bytes memory) {
//         return standardLeafHash(leaf, leafEncoding);
//     }
// }

// contract MerkleTree {
//     /** **/

//     /** Utils **/
//     function checkBounds(uint[] memory array, uint index) public pure {
//         if (index < 0 || index >= array.length) {
//             revert("Index out of bounds");
//         }
//     }

//     function throwError(string memory message) public pure {
//         revert(message);
//     }
// }
