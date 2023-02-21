// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ERC20_reward.sol";
import "./ERC721_nft.sol";

contract VaultUpgradable_V2 is Initializable, IERC721ReceiverUpgradeable {
    //ownership
    address public owner;
    mapping(uint256 => address) public originalOwner;

    //NFT and reward token
    MyNFTUpgradable public nft;
    RewardTokenUpgradable public token;
    bool public partialPayment;

    //reward constants
    uint256 public constant DAY_IN_SECONDS = 1 days;
    uint256 public constant REWARD_RATE_SEC = (10 * 1e18) / uint256(DAY_IN_SECONDS); //const reward

    //reward recording
    mapping(address => mapping(uint => uint)) public startStakingTime;
    mapping(address => uint256) public rewardTimes;

    //logging
    event DepositNFT(address, uint256);
    event NftReceived(address, uint256);
    event WidthdrawNFT(address, uint256);

    function initialize(bool _partialPayment, MyNFTUpgradable _myNft, RewardTokenUpgradable _token) public initializer {
        owner = msg.sender;
        nft = _myNft;
        token = _token;
        partialPayment = _partialPayment;
    }

    function depositNFT(uint256 tokenId) external {
        //Vault contract needs to have permission by the owner
        emit DepositNFT(msg.sender, tokenId);
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    //After receiving a NFT through deposit NFT
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        originalOwner[tokenId] = from;

        startStakingTime[from][tokenId] = block.timestamp;

        emit NftReceived(from, tokenId);

        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    //Withdraw an NFT and calculate reward time
    function widthdrawNFT(uint256 tokenId) external {
        require(msg.sender == originalOwner[tokenId], "A token can only be withdrawn by original owner");

        //cumulate reward time
        calculateRewardTime(tokenId);

        //cleanup owner and starttime
        delete originalOwner[tokenId];
        delete startStakingTime[msg.sender][tokenId];

        emit WidthdrawNFT(msg.sender, tokenId);

        //transfer
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    //users can withdraw Tokens withdraw 10 ERC20 tokens every 24hours, addition: Time not lost
    function widthdrawTokens() external {
        //calculate current time for all owned tokens
        calculateTotalReward();

        //get reward time
        uint256 rewardTime = rewardTimes[msg.sender];
        require(rewardTime > 0, "No staking happened so far");

        //calculate 24h payout, but do keep the leftover
        uint256 timeRounded = (rewardTime / DAY_IN_SECONDS) * DAY_IN_SECONDS;
        uint256 tokensNeeded = 0;

        //calculate tokens to transfer
        if (partialPayment == true) {
            rewardTimes[msg.sender] = 0;
            tokensNeeded = rewardTime * REWARD_RATE_SEC;
        } else {
            if (timeRounded == 0) return;
            rewardTimes[msg.sender] = rewardTime - timeRounded;
            tokensNeeded = timeRounded * REWARD_RATE_SEC;
        }

        //transfer tokens
        token.mint(msg.sender, tokensNeeded);
    }

    function earnedTokens() external returns (uint256) {
        return earnedTime() * REWARD_RATE_SEC;
    }

    function earnedTime() public returns (uint256) {
        //calculate current time for all owned tokens
        calculateTotalReward();

        //get reward time depending on partial/continuous payment
        uint256 rewardTime = rewardTimes[msg.sender];
        if (partialPayment) {
            return rewardTime;
        } else {
            return ((rewardTime / DAY_IN_SECONDS) * DAY_IN_SECONDS);
        }
    }

    function calculateTotalReward() private {
        //iterate over all tokens of a owner and get each tokenId
        uint256 nftCount = nft.balanceOf(msg.sender);
        for (uint256 i; i < nftCount; i++) {
            uint256 tokenId = nft.tokenOfOwnerByIndex(msg.sender, i);

            //if this tokenId is staked then calculate the reward
            if (startStakingTime[msg.sender][tokenId] > 0) {
                calculateRewardTime(tokenId);
            }
        }
    }

    function calculateRewardTime(uint256 tokenId) public {
        rewardTimes[msg.sender] += (block.timestamp - startStakingTime[msg.sender][tokenId]);
        startStakingTime[msg.sender][tokenId] = block.timestamp;
    }

    function version() public pure returns (uint8) {
        return 2;
    }
}
