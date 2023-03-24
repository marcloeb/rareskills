// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";

import "contracts/MultiDelegateCall.sol";

contract MultiDelegateTest is Test {
    TestMultiDelegateCall testMultiDelegatecall;
    event Log(address caller, string func, uint i);

    function setUp() public {
        testMultiDelegatecall = new TestMultiDelegateCall();
    }

    function testMultiDelegateCallFuncs() public {
        vm.expectEmit(true, true, false, true);
        emit Log(address(this), "func1", 3);

        vm.expectEmit(true, true, false, true);
        emit Log(address(this), "func2", 2);

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(TestMultiDelegateCall.func1.selector, 1, 2);
        data[1] = abi.encodeWithSelector(TestMultiDelegateCall.func2.selector);

        bytes[] memory results = testMultiDelegatecall.multiDelegatecall(data);

        console.log("Results 0:");
        console.logBytes(results[0]);
        console.log("Results 1:", abi.decode(results[1], (uint)));

        assertEq(results[0].length, 0); // test for empty bytes
        assertEq(abi.decode(results[1], (uint)), 111);
    }

    function testMultiDelegatecallMints() public {
        bytes[] memory data = new bytes[](4);
        data[0] = abi.encodeWithSelector(TestMultiDelegateCall.mint.selector);
        data[1] = abi.encodeWithSelector(TestMultiDelegateCall.mint.selector);
        data[2] = abi.encodeWithSelector(TestMultiDelegateCall.mint.selector);
        data[3] = abi.encodeWithSelector(TestMultiDelegateCall.mint.selector);

        testMultiDelegatecall.multiDelegatecall{value: 1 ether}(data);

        console.log("balanceOf: ", testMultiDelegatecall.balanceOf(address(this)));
        console.log("eth balance TestMultiDelegateCall contract: ", address(testMultiDelegatecall).balance);
    }
}
