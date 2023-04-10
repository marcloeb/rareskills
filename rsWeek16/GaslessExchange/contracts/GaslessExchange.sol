// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract GaslessExchange is ERC2771Context, ReentrancyGuard {
    ERC20Permit public tokenA;
    ERC20Permit public tokenB;

    struct Order {
        address trader;
        bool isBuyTokenA;
        uint256 tokenAamount;
        uint256 tokenBamount;
        uint256 expires;
        bytes signatureApprove;
        uint256 nonce;
        bool exists;
    }

    Order[] public orders;

    constructor(address tokenA_, address tokenB_, address trustedForwarder_) ERC2771Context(trustedForwarder_) {
        tokenA = ERC20Permit(tokenA_);
        tokenB = ERC20Permit(tokenB_);
    }

    function placeOrder(
        address trader,
        bool isBuyTokenA,
        uint256 tokenAamount,
        uint256 tokenBamount,
        uint256 expires,
        bytes calldata signatureApprove,
        uint256 nonce
    ) external nonReentrant returns (bool success) {
        //split signature into r, s, v
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signatureApprove);

        if (isBuyTokenA) {
            // Execute permit function of tokenB
            tokenB.permit(trader, address(this), tokenBamount, expires, v, r, s); //owner, spender, value, deadline, v, r, s

            // Transfer tokenB to the contract
            tokenB.transferFrom(trader, address(this), tokenBamount);
        } else {
            // Execute permit function of tokenA
            tokenA.permit(trader, address(this), tokenAamount, expires, v, r, s); //owner, spender, value, deadline, v, r, s

            // Transfer tokenA to the contract
            tokenA.transferFrom(trader, address(this), tokenAamount);
        }
        // Save the order in a struct and push it to the orders array
        Order memory newOrder = Order({
            trader: trader,
            isBuyTokenA: isBuyTokenA,
            tokenAamount: tokenAamount,
            tokenBamount: tokenBamount,
            expires: expires,
            signatureApprove: signatureApprove,
            nonce: nonce,
            exists: true
        });

        orders.push(newOrder);
        success = true;
    }

    // There are many issues with this implementation and this is not thought for production. I will not fix because I first want to see other exchanges and
    // second because this task was not requested in my challenge and just a plus.abi
    // the issues I see are:
    // 1) Arrays get quickly expensive 2) there is no delete mechanism, the standard way would change the order book order, which is not what I want
    // 3) the order book is not sorted, so the matching is not optimal 4) the matching is not optimal, it is a simple O(n^2) algorithm, which is not good for a real exchange
    function matchOrders() external nonReentrant {
        uint256 tradeAmountA;
        uint256 tradeAmountB;
        // Remove expired orders
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].expires < block.timestamp) {
                orders[i].exists = false;
            }
        }

        // Search for matching orders
        bool tradeCompleted;
        for (uint256 i = 0; i < orders.length && !tradeCompleted; i++) {
            // check if i order is not empty
            if (orders[i].exists == false) continue;
            for (uint256 j = i + 1; j < orders.length && !tradeCompleted; j++) {
                // check if j order is not empty
                if (orders[j].exists == false) continue;

                // Check if orders have the same price and opposite order types
                if (orders[i].isBuyTokenA != orders[j].isBuyTokenA && orders[i].tokenAamount * orders[j].tokenBamount == orders[i].tokenBamount * orders[j].tokenAamount) {
                    // Calculate the trade amounts
                    if (orders[i].isBuyTokenA) {
                        tradeAmountA = min(orders[i].tokenAamount, orders[j].tokenAamount);
                        tradeAmountB = (tradeAmountA * orders[i].tokenBamount) / orders[i].tokenAamount;
                    } else {
                        tradeAmountB = min(orders[i].tokenBamount, orders[j].tokenBamount);
                        tradeAmountA = (tradeAmountB * orders[i].tokenAamount) / orders[i].tokenBamount;
                    }

                    // Execute trade
                    if (orders[i].isBuyTokenA) {
                        tokenA.transfer(orders[i].trader, tradeAmountA);
                        tokenB.transfer(orders[j].trader, tradeAmountB);
                    } else {
                        tokenA.transfer(orders[j].trader, tradeAmountA);
                        tokenB.transfer(orders[i].trader, tradeAmountB);
                    }

                    // Update orders amounts
                    orders[i].tokenAamount -= tradeAmountA;
                    orders[j].tokenAamount -= tradeAmountA;
                    orders[i].tokenBamount -= tradeAmountB;
                    orders[j].tokenBamount -= tradeAmountB;

                    // Remove orders with zero amounts
                    if (orders[i].tokenAamount == 0 && orders[i].tokenBamount == 0) {
                        orders[i].exists = false;
                    }
                    if (orders[j].tokenAamount == 0 && orders[j].tokenBamount == 0) {
                        orders[j].exists = false;
                    }

                    // Set tradeCompleted to true to exit the loops
                    tradeCompleted = true;
                }
            }
        }
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}
