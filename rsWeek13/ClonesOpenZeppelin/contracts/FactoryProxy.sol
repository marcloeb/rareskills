// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetFixedSupplyUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract FactoryProxy {
    address immutable tokenImplementation;

    constructor() {
        tokenImplementation = address(new ERC20PresetFixedSupplyUpgradeable());
    }

    function createToken(string calldata name, string calldata symbol, uint256 initialSupply) external returns (address) {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            tokenImplementation,
            address(this),
            abi.encodeWithSelector(ERC20PresetFixedSupplyUpgradeable.initialize.selector, name, symbol, initialSupply, msg.sender)
        );
        return address(proxy);
    }
}
