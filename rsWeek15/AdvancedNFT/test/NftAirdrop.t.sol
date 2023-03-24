// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";

import {NftAirdrop} from "contracts/NftAirdrop.sol";
import {NftWrapper} from "contracts/NftWrapper.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NftAirdropTest is Test {
    NftAirdrop nftAirdrop;
    NftWrapper nftWrapper;

    bytes32[] public hashes;

    function setUp() public {
        nftAirdrop = new NftAirdrop(
            "NFT with Airdrop",
            "NFTAD",
            5000,
            1024,
            0x89c7b258591ebbd0b909c231d76cae91623faae44010c236b372a56c18ab20c1,
            0x6277b402a85f4050fba731bef9d5401f39631d7beb5d285fb811ee8b480d857b
        );
        // console.log("NftAirdrop deployed at: ", address(nftAirdrop));
        // console.log("NftAirdrop owner: ", nftAirdrop.owner());
        nftWrapper = new NftWrapper(address(nftAirdrop));
        vm.roll(100);
    }

    function testPublicMint() public {
        nftAirdrop.changeState(NftAirdrop.NftState.PUBLIC);
        nftAirdrop.mint{value: 0.1 ether}();
        assertEq(nftAirdrop.ownerOf(0), address(this));

        vm.expectRevert("Insufficient ether sent");
        nftAirdrop.mint();
    }

    function testMuliTransfer() public {
        nftAirdrop.changeState(NftAirdrop.NftState.PUBLIC);
        bytes[] memory data = new bytes[](3);

        for (uint i = 0; i < 3; i++) {
            nftAirdrop.mint{value: 0.1 ether}();
            data[i] = abi.encodeWithSelector(nftAirdrop.transferFrom.selector, address(this), vm.addr(i + 1), i);
        }

        nftAirdrop.multiTransfer(data);
        assertEq(nftAirdrop.ownerOf(0), address(vm.addr(1)));
        assertEq(nftAirdrop.ownerOf(1), address(vm.addr(2)));
        assertEq(nftAirdrop.ownerOf(2), address(vm.addr(3)));
    }

    function testMerkleProofMapping() public view {
        nftAirdrop._verifyWithMapping(merkleProofMapping());
    }

    function testMerkleProofBitmap() public view {
        nftAirdrop._verifyWithBitmap(merkleProofBitmap(), 1023);
    }

    function testMintWithMapping() public {
        nftAirdrop.mintWithMapping{value: 0.1 ether}(merkleProofMapping());
        assertEq(nftAirdrop.ownerOf(0), address(this));

        vm.expectRevert("Already claimed airdrop NFT");
        nftAirdrop.mintWithMapping{value: 0.1 ether}(merkleProofMapping());
    }

    function testMintWithBitMap() public {
        vm.expectRevert("Unauthorized mint!");
        nftAirdrop.mintWithBitMap{value: 0.1 ether}(merkleProofBitmap(), 0);

        nftAirdrop.mintWithBitMap{value: 0.1 ether}(merkleProofBitmap(), 1023);
        assertEq(nftAirdrop.ownerOf(0), address(this));

        vm.expectRevert("Already claimed airdrop NFT");
        nftAirdrop.mintWithBitMap{value: 0.1 ether}(merkleProofBitmap(), 1023);

        vm.expectRevert("Unauthorized mint!");
        nftAirdrop.mintWithBitMap{value: 0.1 ether}(merkleProofBitmap(), 1022);
    }

    function testNickNames() public {
        //name is set correctly
        nftAirdrop.changeState(NftAirdrop.NftState.PUBLIC);
        nftAirdrop.mint{value: 0.1 ether}();
        nftAirdrop.setTokenURI(0, "This is my token");
        assertEq(nftAirdrop.tokenURI(0), "This is my token");

        //not owner changes name, revert
        nftAirdrop.mint{value: 0.1 ether}();
        vm.prank(address(0x1));
        vm.expectRevert("ERC721URIStorage: caller is not the owner");
        nftAirdrop.setTokenURI(1, "This is my token");
        vm.stopPrank();

        //name is too long, revert
        nftAirdrop.mint{value: 0.1 ether}();
        vm.expectRevert("URI too long");
        nftAirdrop.setTokenURI(2, "This is my too long tokenURI");
    }

    function testSetProvenanceHash() public {
        nftAirdrop.setProvenanceHash("This is my provenance hash");
    }

    function testSetBaseURI() public {
        nftAirdrop.setBaseURI("This is my base URI");
        assertEq(nftAirdrop.baseURI(), "This is my base URI");
    }

    function testSetStartingIndex() public {
        nftAirdrop.setBaseURI("https://nftairdrop.com/");
        assertEq(nftAirdrop.baseURI(), "https://nftairdrop.com/");

        vm.expectRevert("Starting index block must be set");
        nftAirdrop.setStartingIndex();

        nftAirdrop.changeState(NftAirdrop.NftState.PUBLIC);
        nftAirdrop.mint{value: 0.1 ether}();
        assertEq(nftAirdrop.tokenURI(0), "https://nftairdrop.com/0");

        vm.roll(110);
        nftAirdrop.mint{value: 0.1 ether}();
        vm.roll(111);
        nftAirdrop.setStartingIndex();

        assertEq(nftAirdrop.startingIndex(), 2202);
    }

    function testLeadingZeros() private view {
        (uint256 nonce, address addressWithLeadingZeros) = nftAirdrop.mineAddress(address(nftAirdrop));
        console.log("Nonce: ", nonce);
        console.log("Address with leading zeros: ", addressWithLeadingZeros);
    }

    function testWrappingContract() public {
        nftAirdrop.changeState(NftAirdrop.NftState.PUBLIC);
        nftAirdrop.mint{value: 0.1 ether}();
        nftAirdrop.approve(address(nftWrapper), 0);
        assertEq(nftAirdrop.ownerOf(0), address(this));

        nftWrapper.wrap(0);
        assertEq(nftWrapper.balanceOf(address(this), 0), 1);
        assertEq(nftAirdrop.ownerOf(0), address(nftWrapper));

        vm.expectRevert("ERC721: invalid token ID");
        nftWrapper.wrap(1);

        nftWrapper.unwrap(0);
        assertEq(nftWrapper.balanceOf(address(this), 0), 0);
        assertEq(nftAirdrop.ownerOf(0), address(this));
    }

    // function testMultisigWallet() public {}

    /** Helpers **/

    function merkleProofMapping() private pure returns (bytes32[] memory) {
        bytes32[] memory proof = new bytes32[](10);

        proof[0] = 0xa71575cbb748f11208f3044a6392c0461bf1df706586b380a0f26d9fc68e0a71;
        proof[1] = 0xb31b47140e9aafd0c369bf6460cd080783b68e0135f63650d0e59dd800ba789a;
        proof[2] = 0xaa1fb3e4ccda0e184cb4f52b0967ff22c04eb85eae9534815d2e853b02eab178;
        proof[3] = 0x241c6e1119472348fc7f64895da48ee5222a7d49e642eaf0e366cd29dea4a208;
        proof[4] = 0xb0a14f616abe7dceac41085505f21c1ac4214c2c41d4f4ec1a7d613667cfa668;
        proof[5] = 0xd9e754c890357b782129e9c0a2fa465627207ad627a1a9bd45d560cb040e44b2;
        proof[6] = 0x5a8e02400fffc06c96bbf5fc9938145d4f6692140d07fb04455a9b4b8d57e469;
        proof[7] = 0xebff56ec58ca397425bb4d8c4ad585c7cf99ebe9d00a8b66f92e6e69d6973b47;
        proof[8] = 0x1334d37e5e972878c5c0cb6b1d4e621a04207f92496a1d9bdc350a3ae5d5109c;
        proof[9] = 0x090a2d40b1940045a4a62943d67fb9c4c99401e76fabe943827bcbbd91c5147e;
        return proof;
    }

    function merkleProofBitmap() private pure returns (bytes32[] memory) {
        bytes32[] memory proof = new bytes32[](10);

        proof[0] = 0x3981695cab9c737631006de85f0ce78e32049bbce75f80f57a6f0cd952f74246;
        proof[1] = 0x049bb98666e7dc92fa5fb78eacfb32f2e53be06f0f4701b5bf03345ffe5e464c;
        proof[2] = 0x81582e37af28ebdae250c07d41160786bb1096daa73ce15fb838c08744f04bc2;
        proof[3] = 0x691cc6ac1163619e256860d3cfed9f8d74e2d2fc273edb94731b6647770e736e;
        proof[4] = 0x6fabf821d2012f8fa7b41949eb38661eb5054afa1f85ac01157f1619eaec12ec;
        proof[5] = 0x03bc585cda20aa9b5eca781645310010f6378833e4a5e4bbfda7659029790af2;
        proof[6] = 0xd780942c6d8304d0b452468d30200aac5d8aa0429b0aa100a0558ad40e7438a2;
        proof[7] = 0x5021775b4196cc7635feb1678ae437f588ada42fc455a19c81eb1e1f9b342415;
        proof[8] = 0x98bb864fc3b4b11e8cd7aab5637cf09b5db9902cdd8a6e55d036947ed65a8dca;
        proof[9] = 0xca6310d91a3f05e84ff1c460a3ed7ee72734c93b4bacddcad6cf9c169a4b1eed;

        return proof;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
