// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UNAUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract NFT_VRF_HH is ERC721, VRFV2WrapperConsumerBase, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords, uint256 paid);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment);
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

    // configuration: https://docs.chain.link/vrf/v2/direct-funding/supported-networks#configurations
    constructor(address _linkAddress, address _wrapperAddress) ERC721("MarcToken", "MCT") ConfirmedOwner(msg.sender) VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress) {}

    function mint() external {
        require(isMinting == false, "Minting is already in progress");
        isMinting = true;
        requestRandomWords(callbackGasLimit, requestConfirmations, numWords);
    }

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    // The default is 3, but you can set this higher.
    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    function requestRandomWords(uint32 _callbackGasLimit, uint16 _requestConfirmations, uint32 _numWords) public onlyOwner returns (uint256 requestId) {
        requestId = requestRandomness(_callbackGasLimit, _requestConfirmations, _numWords);
        uint256 paid = VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit);
        uint256 balance = LINK.balanceOf(address(this));
        if (balance < paid) revert InsufficientFunds(balance, paid);
        s_requests[requestId] = RequestStatus({paid: paid, randomWords: new uint256[](0), fulfilled: false});
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, _numWords, paid);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        RequestStatus storage request = s_requests[_requestId];
        if (request.paid == 0) revert RequestNotFound(_requestId);
        request.fulfilled = true;
        request.randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords, request.paid);

        if (isMinting) {
            console.log("fulfillRandomWords: %s", _randomWords[0]);
            uint8 id = uint8(_randomWords[0] % 101);
            console.log("current id by mod 101: %s", id);

            while (tokenIds[id] == true) {
                id += 1;
            }
            if (id > 100) {
                revert("No more tokens available");
            }
            console.log("Id after while loop: %s", id);
            tokenIds[id] = true;
            _mint(msg.sender, id);
            isMinting = false;
        }
    }

    function getNumberOfRequests() external view returns (uint256) {
        return requestIds.length;
    }

    function getRequestStatus(uint256 _requestId) external view returns (uint256 paid, bool fulfilled, uint256[] memory randomWords) {
        RequestStatus memory request = s_requests[_requestId];
        if (request.paid == 0) revert RequestNotFound(_requestId);
        return (request.paid, request.fulfilled, request.randomWords);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink(address _receiver) public onlyOwner {
        bool success = LINK.transfer(_receiver, LINK.balanceOf(address(this)));
        if (!success) revert LinkTransferError(msg.sender, _receiver, LINK.balanceOf(address(this)));
    }
}
