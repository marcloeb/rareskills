// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "remix_tests.sol"; 
import "remix_accounts.sol";
import "../../../contracts/Rareskills/Week_1/3_ERC20_sale_buyback.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract ERC20SaleBuybackTest {
    ERC20SaleBuyback token;
    
    address acc0; //owner by default
    address acc1;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        token = new ERC20SaleBuyback();
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
    }

    /// #value: 1000
    /// #sender: account-1
    function checkBuyTokensByAccount()public payable{

        Assert.equal(msg.sender, acc1, "The message owner should be account 0.");
        Assert.equal(msg.value, 1000, "value should be 100 wei");

        token.buyTokens{value: 1000}();

        //msg sender is used to store tokens, cannot send address in a parameter or tx.origin due to security risk
        Assert.equal(token.balanceOf(address(this)), 44 ,"The token balance of account 1 should be 44");
    }

    function checkTokenTotalSupply() public{
       Assert.equal(token.totalSupply(),44,"The total supply of Token should be 44");
    }

    /// #value: 0
    /// #sender: account-1
    function checkTokenSell() public payable {
        token.sellTokens(44);
        //msg sender is used to store tokens, cannot send address in a parameter or tx.origin due to security risk
        Assert.equal(address(this).balance,900, "The returned value needs to be 900.");
    }

    receive() external payable{

    }
}
    