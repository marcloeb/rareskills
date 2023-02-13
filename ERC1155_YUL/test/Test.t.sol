// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";

contract ContractBTest is Test {
    uint256 testNumber;

    function setUp() public {
        testNumber = 42;
        emit log("setUp");
        emit log_uint(testNumber);
    }

    function testFailSubtract43() public {
        //vm.expectRevert(stdError.arithmeticError);
        testNumber -= 43;
        emit log("testFailSubtract43");
        emit log_uint(testNumber);
    }

    function testNumberIs42() public {
        assertEq(testNumber, 42);
        emit log("testNumberIs42");
        emit log_uint(testNumber);
    }
}
