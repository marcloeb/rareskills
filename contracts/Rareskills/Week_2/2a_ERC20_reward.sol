// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../Week_1/1_ERC20_with_sanctions.sol";


contract RewardToken is ERC20withSanction{
    address minter;
    constructor(address _minter)ERC20withSanction("Rewards For NFT Staking","RFNFT"){
        minter=_minter;
    }

    modifier minterOnly(){
        require(msg.sender==minter,"only a minter can execute a call to this function")    ;
        _;
    }

    function mint(address user, uint256 amount) external minterOnly{
        _mint(user, amount);
    }

}