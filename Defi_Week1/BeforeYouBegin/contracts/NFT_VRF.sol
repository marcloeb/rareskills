// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UNAUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract NFT_VRF is ERC721, VRFV2WrapperConsumerBase, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords, uint256 paid);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment);
    event TokenIDGenerated(uint256 indexed tokenId);
    error InsufficientFunds(uint256 balance, uint256 paid);
    error RequestNotFound(uint256 requestId);
    error LinkTransferError(address sender, address receiver, uint256 amount);

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 550000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 1;

    // Address LINK - hardcoded for Sepolia
    address linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    // address WRAPPER - hardcoded for Sepolia
    address wrapperAddress = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

    //mapping for tokenIds
    mapping(uint256 => bool) public tokenIds;

    //isMInting
    bool public isMinting = false;

    // isMinting EOA
    address public isMintingEOA;

    // configuration: https://docs.chain.link/vrf/v2/direct-funding/supported-networks#configurations
    constructor() ERC721("MarcToken", "MCT") ConfirmedOwner(msg.sender) VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) {}

    function mint() external {
        require(isMinting == false, "Minting is already in progress");
        isMinting = true;
        isMintingEOA = msg.sender;
        requestRandomWords();
    }

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    // The default is 3, but you can set this higher.
    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    function requestRandomWords() internal returns (uint256 requestId) {
        requestId = requestRandomness(callbackGasLimit, requestConfirmations, numWords);
        uint256 paid = VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit);
        uint256 balance = LINK.balanceOf(address(this));
        if (balance < paid) revert InsufficientFunds(balance, paid);
        s_requests[requestId] = RequestStatus({paid: paid, randomWords: new uint256[](0), fulfilled: false});
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords, paid);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        RequestStatus storage request = s_requests[_requestId];
        if (request.paid == 0) revert RequestNotFound(_requestId);
        request.fulfilled = true;
        request.randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords, request.paid);

        if (isMinting) {
            uint256 idOriginal = _randomWords[0] % 101;
            uint256 id = idOriginal;
            while (tokenIds[id] == true) {
                id += 1;
            }
            if (id > 100) {
                id = 0;
                while (tokenIds[id] == true && id < idOriginal) {
                    id += 1;
                }
                if (id == idOriginal) revert("No more tokens available");
            }
            tokenIds[id] = true;
            emit TokenIDGenerated(id);
            _mint(isMintingEOA, id);
            isMinting = false;
            isMintingEOA = address(0);
        }
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink(address _receiver) public onlyOwner {
        bool success = LINK.transfer(_receiver, LINK.balanceOf(address(this)));
        if (!success) revert LinkTransferError(msg.sender, _receiver, LINK.balanceOf(address(this)));
    }

    function kill() public onlyOwner {
        selfdestruct(payable(owner()));
    }
}
