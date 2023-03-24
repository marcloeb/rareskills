// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import {console} from "forge-std/console.sol";

contract MultiDelegatecall {
    mapping(bytes4 => bool) allowedFunctions;
    error DelegatecallFailed();
    error InvalidCall();

    constructor(bytes4[] memory _allowedFunctions) {
        for (uint i; i < _allowedFunctions.length; i++) {
            allowedFunctions[_allowedFunctions[i]] = true;
        }
    }

    function multiDelegatecall(bytes[] memory data) internal returns (bytes[] memory results) {
        results = new bytes[](data.length);

        for (uint i; i < data.length; i++) {
            if (!allowedFunctions[bytes4(data[i])]) revert InvalidCall();

            (bool ok, bytes memory res) = address(this).delegatecall(data[i]);
            if (!ok) {
                revert DelegatecallFailed();
            }
            results[i] = res;
        }
    }
}

contract NftAirdrop is ERC721, ERC721URIStorage, ReentrancyGuard, Ownable, MultiDelegatecall {
    /** Initialization **/
    //NFT
    uint256 totalSupply;
    uint256 airDropSupply;
    uint256 tokenIdCounter;
    uint256 private constant NFT_COST = 0.1 ether;

    //Commit Reveal
    string public NFT_PROVENANCE = "";
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public REVEAL_AFTER_BLOCK = 10;
    string public baseURI;

    //NFT State Machine
    enum NftState {
        PRESALE,
        PUBLIC,
        NOSUPPLY
    }

    NftState public state;

    // AirDrop Approach 1: regular mapping to store claimed NFTs
    mapping(address => uint256) private claimedMapping;

    // AirDrop Approach 2: bitmap to store claimed NFTs with MerkleProof
    bytes32 private merkleRootMapping;
    bytes32 private merkleRootBitmap;

    using BitMaps for BitMaps.BitMap; // (make bitmap library easier to use)
    BitMaps.BitMap private claimedBitmap;

    // commit/reveal
    uint256 public blockBaseUrlSet;

    // Efficient address with leading zeros
    using Clones for address;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _airDropSupply,
        bytes32 _merkleRootMapping,
        bytes32 _merkleRootBitmap
    ) ERC721(_name, _symbol) MultiDelegatecall(init()) {
        totalSupply = _totalSupply;
        merkleRootMapping = _merkleRootMapping;
        merkleRootBitmap = _merkleRootBitmap;

        airDropSupply = _airDropSupply;
        for (uint256 i = 0; i < _airDropSupply; i++) {
            claimedBitmap.set(i); // this sets the bitmap for our 1024 airdrop NFTs, we need 1024 Nfts / 256 bits = 4 storage slots
        }

        state = NftState.PRESALE;
    }

    function init() private pure returns (bytes4[] memory allowedMulticallFunctions) {
        allowedMulticallFunctions = new bytes4[](1);
        allowedMulticallFunctions[0] = bytes4(abi.encodeWithSelector(transferFrom.selector));
    }

    /** Airdrops and regular minting **/

    modifier mintingAllowed(NftState _state) {
        if (msg.sender != owner()) {
            require(_msgSender() == tx.origin, "Only EOA can mint");
        }
        require(tokenIdCounter <= totalSupply);
        require(msg.value >= NFT_COST, "Insufficient ether sent");
        if (_state != state || state == NftState.NOSUPPLY) {
            revert("NFT State does not allow minting");
        }

        _;

        // Adjust state based on bitmap
        if (state == NftState.PRESALE && (tokenIdCounter + 1) == airDropSupply) {
            state = NftState.PUBLIC;
        }

        if (state == NftState.PUBLIC && tokenIdCounter == totalSupply) {
            state = NftState.NOSUPPLY;
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block

        if (startingIndexBlock == 0 && blockBaseUrlSet != 0 && (tokenIdCounter == totalSupply || block.number - blockBaseUrlSet >= REVEAL_AFTER_BLOCK)) {
            startingIndexBlock = block.number;
        }
    }

    function mint() external payable nonReentrant mintingAllowed(NftState.PUBLIC) {
        return _mint(_msgSender(), tokenIdCounter++);
    }

    function mintWithMapping(bytes32[] calldata proof) external payable nonReentrant mintingAllowed(NftState.PRESALE) {
        _verifyWithMapping(proof);

        require(claimedMapping[_msgSender()] == 0, "Already claimed airdrop NFT");
        claimedMapping[_msgSender()] = 1;

        return _mint(_msgSender(), tokenIdCounter++);
    }

    function mintWithBitMap(bytes32[] calldata proof, uint256 ticketNumber) external payable nonReentrant mintingAllowed(NftState.PRESALE) {
        _verifyWithBitmap(proof, ticketNumber);

        require(claimedBitmap.get(ticketNumber), "Already claimed airdrop NFT");
        claimedBitmap.unset(ticketNumber);

        return _mint(_msgSender(), tokenIdCounter++);
    }

    function _verifyWithMapping(bytes32[] calldata proof) public view {
        //console.log("The message sender in the contract is %s", _msgSender());
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_msgSender()))));
        require(MerkleProof.verify(proof, merkleRootMapping, leaf), "Not authorized for airdrop");
    }

    function _verifyWithBitmap(bytes32[] calldata proof, uint256 bitmapIndex) public view {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_msgSender(), bitmapIndex)))); // here we hash the address AND the bitmap index
        require(MerkleProof.verify(proof, merkleRootBitmap, leaf), "Unauthorized mint!");
    }

    /**  MULTIDELEGATECALL **/

    function multiTransfer(bytes[] memory data) external {
        super.multiDelegatecall(data);
    }

    function helperGetCallData(address from, address to, uint256 _tokenId) external pure returns (bytes memory) {
        return abi.encodeWithSelector(transferFrom.selector, from, to, _tokenId);
    }

    function helperGetWrongCallData(bytes32[] calldata proof) external pure returns (bytes memory) {
        return abi.encodeWithSignature("mintWithMapping(bytes32[])", proof);
    }

    /** NIKNAMES IN URI STORAGE **/

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
        require(ownerOf(tokenId) == _msgSender(), "ERC721URIStorage: caller is not the owner");
        require(strlen(_tokenURI) <= 20, "URI too long");
        _setTokenURI(tokenId, _tokenURI);
    }

    //code from https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/StringUtils.sol
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }

    /** Commit and Reveal **/
    // Like BAYC  https://boredapeyachtclub.com/#/provenance:
    // https://medium.com/coinmonks/the-elegance-of-the-nft-provenance-hash-solution-823b39f99473
    // https://github.com/nftchef/art-engine/discussions/65
    // https://dev.to/brodan/learning-nft-provenance-by-example-a-bored-ape-investigation-hfe

    // Create a list of NFTs, with original numberin from eg from 0 to 9,999.
    // Provinance Hash: Calculate the hash of each image, concatinate hashes from 0 to 9,999 and calculate hash again.
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        NFT_PROVENANCE = provenanceHash;
    }

    /* Calculate Startindex */
    // 1) get block 12344391 (https://etherscan.io/block/12344391) / and Blockhash https://dashboard.alchemy.com/composer
    // 2) calculate int(blockhash) % 10000 (totalSupply) => Startindex (8853 in BAYC)
    // 3) (tokenId + 8853) % 10000 → Initial Sequence Index => 0 () is 8853, 147 is 9000, 1147 is 0
    // MEANING: the token id 0 in the NFT numbering is the token with original numbering id 8853
    // The token id 1147 in the NFT numbering is the tokenid with original numbering id 0
    // IMPORTANT: Mapping of nft numbering to original numbering happens off-chain in Metadata on ipfs or as a json file on a website

    // Example for 0 id in original mapping:
    // Metadata: https://us-central1-bayc-metadata.cloudfunctions.net/api/tokens/0 or ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/0
    // Images: https://ipfs.io/ipfs/QmRRPWG96cmgTn2qSzjwr2qvfNEuhunv6FNeMFGa9bx6mQ,https://bafybeibnzhc7vp4hnfcocw7s2jej2tj5xqpwseyz3ifylismh47cr45rhm.ipfs.dweb.link/

    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint(blockhash(startingIndexBlock)) % totalSupply;

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % totalSupply;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    //will be set by the owner after deployment
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _revealBaseURI) public onlyOwner {
        baseURI = _revealBaseURI;
        blockBaseUrlSet = block.number;
    }

    /** Mine a efficient address **/
    // brute force to find an efficient address with 6 leading zeros with create2 by changing the salt in a while loop
    function mineAddress(address implementation) external view returns (uint256, address) {
        address addressWithLeadingZeros;
        uint256 leadingZeros = 0;
        uint256 nonce = 0;

        while (leadingZeros < 3) {
            addressWithLeadingZeros = implementation.predictDeterministicAddress(bytes32(abi.encode(nonce)));
            leadingZeros = countLeadingZerosHex(addressWithLeadingZeros);
            nonce++;
            console.log("nonce from token", nonce);
            console.log("address with leading zeros from token", addressWithLeadingZeros);
            console.log("gas left: ", gasleft());
        }
        return (nonce, addressWithLeadingZeros);
    }

    function countLeadingZerosHex(address addr) public pure returns (uint256) {
        return (159 - mostSignificantBit(uint256(uint160(addr)))) / 4;
    }

    // from Uniswap v3 BitMath library (https://docs.uniswap.org/contracts/v3/reference/core/libraries/BitMath)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    /** HELPERS **/

    function changeState(NftState _state) external onlyOwner {
        state = _state;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
