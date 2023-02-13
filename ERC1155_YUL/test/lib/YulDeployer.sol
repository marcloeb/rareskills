// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";

contract YulDeployer is Test {
    ///@notice Compiles a Yul contract and returns the address that the contract was deployeod to
    ///@notice If deployment fails, an error will be thrown
    ///@param fileName - The file name of the Yul contract. For example, the file name for "Example.yul" is "Example"
    ///@return deployedAddress - The address that the contract was deployed to
    function deployContract(string memory fileName) public returns (address) {
        // $(echo solc --yul yul/example.yul --bin) | tail -2
        // solc --yul yul/Example.yul --bin
        // $(echo solc --yul yul/example.yul --bin)
        // /usr/local/Homebrew/Cellar/solidity/0.8.17/bin/solc --yul /Users/marcloeb/hardhat/ERC1155_YUL/yul/Example.yul --bin
        // /usr/local/Homebrew/Cellar/solidity/0.8.17/bin/solc --yul /Users/marcloeb/hardhat/ERC1155_YUL/yul/Example.yul --bin | tail -1
        // cast abi-encode "f(bytes)" $(/usr/local/Homebrew/Cellar/solidity/0.8.17/bin/solc --yul /Users/marcloeb/hardhat/ERC1155_YUL/yul/Example.yul --bin | tail -1)
        // bash -c cast abi-encode "f(bytes)" $(/usr/local/Homebrew/Cellar/solidity/0.8.17/bin/solc --yul /Users/marcloeb/hardhat/ERC1155_YUL/yul/Example.yul --bin | tail -1)

        string memory bashCommand = string.concat('cast abi-encode "f(bytes)" $(solc --strict-assembly yul/', string.concat(fileName, ".yul --bin | tail -2)"));

        emit log("bash command: ");
        emit log(bashCommand);

        string[] memory inputs = new string[](3);
        inputs[0] = "bash";
        inputs[1] = "-c";
        inputs[2] = bashCommand;

        bytes memory bytecode = abi.decode(vm.ffi(inputs), (bytes));

        emit log("Bytecode: ");
        emit log_bytes(bytecode);

        ///@notice deploy the bytecode with the create instruction
        address deployedAddress;
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        emit log("Address: ");
        emit log_address(deployedAddress);

        ///@notice check that the deployment was successful
        require(deployedAddress != address(0), "YulDeployer could not deploy contract");

        ///@notice return the address that the contract was deployed to
        return deployedAddress;
    }
}
