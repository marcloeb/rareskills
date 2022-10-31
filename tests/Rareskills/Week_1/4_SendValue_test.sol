// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;
import "remix_tests.sol"; 
import "../../../contracts/Rareskills/Week_1/4_SendValue.sol";

contract ValueTest{
    Value v;
    
    function beforeAll() public {
        // create a new instance of Value contract
        v = new Value();
    }
    
    /// Test initial balance
    function testInitialBalance() public {
        // initially token balance should be 0
        Assert.equal(v.getTokenBalance(), 0, 'token balance should be 0 initially');
    }
    
    /// For Solidity version greater than 0.6.1
    /// Test 'addValue' execution by passing custom ether amount 
    /// #value: 200
    function addValueOnce() public payable {
        // check if value is same as provided through devdoc
        Assert.equal(msg.value, 200, 'value should be 200');
        // execute 'addValue'
        v.addValue{gas: 40000, value: 200}(); // introduced in Solidity version 0.6.2
        // As per the calculation, check the total balance
        Assert.equal(v.getTokenBalance(), 20, 'token balance should be 20');
    }
    

}