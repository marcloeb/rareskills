// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "remix_tests.sol"; 
import "remix_accounts.sol";
import "../../../contracts/Rareskills/Week_1/1_ERC20_with_sanctions.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract ERC20withSanctionTest {
    ERC20withSanction token;
    address acc0; //owner by default
    
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        token = new ERC20withSanction("Token with Sanctions","TWS");
        acc0 = TestsAccounts.getAccount(0);
    }

    function checkBannUser()public{
        token.bannUser(address(0xdD870fA1b7C4700F2BD7f44238821C26f7392148));
        Assert.equal(token.banned(address(0xdD870fA1b7C4700F2BD7f44238821C26f7392148)), true, "User was banned but is not showing.");
    }

    function checkUnBannUser()public{
        token.unBannUser(address(0xdD870fA1b7C4700F2BD7f44238821C26f7392148));
        Assert.equal(token.banned(address(0xdD870fA1b7C4700F2BD7f44238821C26f7392148)), false, "User was un-banned but is not showing.");
    }

    function checkNotExisitingBannUser()public{             
        Assert.equal(token.banned(address(0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC)), false, "Not existing User shows returns not false from banned array.");
    }

    /// #value: 100000
    /// #sender: account-0
    function checkBannedUserCannotTransfer() public payable{
        token.buyTokens{value: 100000}();
        token.transfer(address(0xdD870fA1b7C4700F2BD7f44238821C26f7392148), 100); 
        token.bannUser(address(0xdD870fA1b7C4700F2BD7f44238821C26f7392148));

       //receive tokens
         try token.transfer(address(0xdD870fA1b7C4700F2BD7f44238821C26f7392148), 100) {
            Assert.ok(false, "A banned user should not be able to receive tokens.");
        } catch {
            Assert.ok(true,"");
        }
    }

    function checkOnlyOwnerCanBann()public{
        token.transferOwnership(address(0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC));
        //bann
        try token.bannUser(address(0xdD870fA1b7C4700F2BD7f44238821C26f7392148)) {
            Assert.ok(false, "Bann a user should only be possible by a admin.");
        } catch {
            Assert.ok(true, "");
        } 

        //un-bann
        try token.unBannUser(address(0xdD870fA1b7C4700F2BD7f44238821C26f7392148)) {
            Assert.ok(false, "Un-Bann a user should only be possible by a admin.");
        } catch {
            Assert.ok(true,"");
        } 
    }


}
    