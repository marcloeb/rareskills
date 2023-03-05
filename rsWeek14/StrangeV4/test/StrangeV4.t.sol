// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "contracts/StrangeV4.sol";
import "contracts/OriginalExploitor.sol";

import "contracts/MetamorphicContractFactory.sol";

contract StrangeTest is Test {
    StrangeV4 strange;
    MetamorphicContractFactory factory;
    Original original;
    Exploitor exploitor;
    bytes32 salt;
    bytes zeroBytes = new bytes(0);

    function setUp() public {
        strange = new StrangeV4{value: 1 ether}();
        strange.initialize(address(strange));

        factory = new MetamorphicContractFactory(zeroBytes);
        salt = bytes32(bytes20(address(this)));
        console.logBytes32(salt);

        original = new Original(address(factory));
        exploitor = new Exploitor(address(factory));
    }

    function testOtherContract() public {
        //deploy a metamorphic contract
        address metamorphic = factory
            .deployMetamorphicContractFromExistingImplementation(
                bytes32(salt),
                address(original),
                zeroBytes
            );

        assertEq(Original(metamorphic).addTwo(2), 4);
        Original(metamorphic).kill();
        vm.roll(block.number + 1);
        console.log(
            "The value after kill of addTwo to 2 is: ",
            Original(original).addTwo(2)
        );

        //==>>>>>>> Foundry does not support self destruct, stop working here
        //https://github.com/foundry-rs/foundry/issues/1543

        // metamorphic = factory
        //     .deployMetamorphicContractFromExistingImplementation(
        //         bytes32(salt),
        //         address(exploitor),
        //         zeroBytes
        //     );
        // assertEq(Exploitor(metamorphic).addTwo(2), 6);
    }
}
