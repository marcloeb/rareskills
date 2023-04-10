// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/GaslessExchange.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SigUtils.sol";

contract GaslessExchangeTest is Test {
    using ECDSA for bytes32;
    GaslessExchange exchange;
    MyERC20 tokenA;
    MyERC20 tokenB;
    MinimalForwarder forwarder;
    address public trader1;
    address public trader2;
    SigUtils internal sigUtilsTokenA;
    SigUtils internal sigUtilsTokenB;

    function setUp() public {
        //create 2 tokens with ERC20Permit
        tokenA = new MyERC20("Token A", "TKA");
        tokenB = new MyERC20("Token B", "TKB");

        //create 2 sigUtils from foundry for tokenA and tokenB
        sigUtilsTokenA = new SigUtils(tokenA.DOMAIN_SEPARATOR());
        sigUtilsTokenB = new SigUtils(tokenB.DOMAIN_SEPARATOR());

        //create a forwarder and a gasless exchange
        forwarder = new MinimalForwarder();
        exchange = new GaslessExchange(address(tokenA), address(tokenB), address(forwarder));

        //create 2 traders and mint tokens for them
        trader1 = vm.addr(1);
        trader2 = vm.addr(2);

        tokenA.mint(trader1, 1e18);
        tokenB.mint(trader1, 2e18);

        tokenA.mint(trader2, 9e18);
        tokenB.mint(trader2, 18e18);
    }

    function testPlaceOrdersAndMatch() public {
        //trader1 wants to buy 1 tokenA for 2 tokenB and he creates a signature for it
        SigUtils.Permit memory permitToken = SigUtils.Permit({owner: trader1, spender: address(exchange), value: 2e18, nonce: 0, deadline: 1 days});
        bytes32 digestTokenB = sigUtilsTokenB.getTypedDataHash(permitToken);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digestTokenB);
        bytes memory signature = abi.encodePacked(r, s, v);

        //trader1 places the order
        bool result = exchange.placeOrder(trader1, true, 1e18, 2e18, 1 days, signature, 0);
        assertEq(result, true);

        //check balances of exchange and trader1 after the order placement
        assertEq(tokenB.balanceOf(address(exchange)), 2e18);
        assertEq(tokenB.balanceOf(trader1), 0);

        //trader2 wants to sell 9 tokenA for 18 tokenB and he creates a signature for it
        SigUtils.Permit memory permitToken2 = SigUtils.Permit({owner: trader2, spender: address(exchange), value: 9e18, nonce: 0, deadline: 1 days});
        bytes32 digestTokenA = sigUtilsTokenA.getTypedDataHash(permitToken2);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(2, digestTokenA);
        bytes memory signature2 = abi.encodePacked(r2, s2, v2);

        //trader2 places the order
        bool result2 = exchange.placeOrder(trader2, false, 9e18, 18e18, 1 days, signature2, 0);
        assertEq(result2, true);

        //check balances of exchange and trader2 after the order placement
        assertEq(tokenA.balanceOf(address(exchange)), 9e18);
        assertEq(tokenA.balanceOf(trader2), 0);

        //do the matching
        exchange.matchOrders();
    }
}

contract MyERC20 is ERC20Permit, Ownable {
    constructor(string memory name, string memory symbol) ERC20Permit(name) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
