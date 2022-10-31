// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "remix_tests.sol"; 
import "remix_accounts.sol";
import "../../../contracts/Rareskills/Week_1/2_ERC20_token_sell.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract ERC20withSanctionTest {
    ERC20TokenSell token;
    
    address acc0 = TestsAccounts.getAccount(0); //owner by default
    address acc1 = TestsAccounts.getAccount(1);

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        token = new ERC20TokenSell();
    }

    /// #value: 200
    /// #sender: account-1
    function checkBuyTokensByAccount()public payable{
        Assert.equal(msg.sender, acc1, "The message owner should be account 1.");
        Assert.equal(msg.value, 200, "value should be 200 wei");

        token.buyTokens{value: 200}();

        //contract address is used for call to method token buyTokens. Why?
        Assert.equal(token.balanceOf(address(this)), 2_000_000,"The token balance of account 1 should be 2000000");
    }

    function checkTokenTotalSupply() public{
       Assert.equal(token.totalSupply(),2_000_000,"The total supply of Token should be 20_0000");
    }

}
    