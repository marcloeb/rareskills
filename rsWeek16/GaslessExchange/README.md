# Task 3: Gasless Exchange

Build an order book exchange where the users never have to pay gas

## The Task Intro

1. Given two ERC20 permit token A and B
2. The order book is done off-chain (simulate not implement its behavior)
3. The users sign approvals and orders.
4. These approval and orders are sent to the exchange
5. Offchain, people can sign (for example) an order Sell token 100 token A for 50 token B, order expires by time T.
6. If another order comes in for Buy token 10 token A for 5 token B expires by time T’, the off-chain exchange can forward the pair of orders to the smart contract
7. The smart contract will verify both the buyer and the seller have the appropriate approvals, and the signatures are valid, and the approvals and orders have not expired.
8. Essentially, all you have to worry about however is the smart contract being presented:
   a. two orders and
   b. making sure they match with each other
   c. the traders have enough balance to execute it.
9. Use the openzeppelin library for signatures. Doing it directly with ecrecover can lead to vulnerabilities you will learn about in the following two weeks. If you need a reference implementation, you can copy the hardhat reference code [here](https://github.com/DonkeVerse/PrivateSaleBenchmark/blob/main/test/benchmark-test.js).

   10.There are a lot of corner cases. Think them through!

## Solution

This was a horrible and fun exercise the same time. Horrible, because I do currently 2 courses at the same time - the Defi course and the end of the solidity bootcamp. So I am totally time starved. Fun, because I decided to use CHAT-GPT4 and created a on-chain order book exchange. Chat-GPT seduced me to do it because it was that simple.

WEll first: DONT use this code in production, it is not efficient! I use 2 for loops with an array for the order book, which can be very expensive. I also do not have a sorting mechanism for the order book, so the matching is not optimal. I also do not have a mechanism to delete filled or expired orders. I also do not have a mechanism to cancel orders. I also do not have a mechanism to notify users of order updates, such as order placement, order matching, and order cancellation. I also do not have a mechanism to check if the order has not been canceled or filled before executing the trade in the `matchOrders` function.

Still! I created this code in 2 hours with Chat-GPT4 in an interative session, asking questions and fixing hallucinations. I asked Chat-GPT for a review and a score. I got a 3.2/5. I am happy with that. Even that my Ego asks for a 4.6 minimum, I think for a 2 hour session, this is a good result. If I had more time, I would have implemented the missing features, following the advice of Chat-GPT4. I presented my results to experienced Solidity developers, and they were impressed mainly with the process and the quality of the code.

Still, it is strongly recommended to use a off-chain matching engine that periodically submits matched orders to the on-chain contract for execution. This can reduce the on-chain computation and gas costs.

Wooohaaaaa! Done 🎉️. Below you find Chat-GPT4's review and score.

### Gasless exchange Smart Contract CHAT-GPT4 Review:

1. The code utilizes OpenZeppelin libraries for ERC20, ERC20Permit, ReentrancyGuard, and ERC2771Context. This is a good practice for reducing security risks and improving the overall quality of the code.

2. The `placeOrder` function reads the signature, executes the permit function for tokenB, transfers the tokenB to the contract, and stores the order in an array.

3. As you have mentioned in the comments, there are several issues with the `matchOrders` function:
   - Using arrays can be expensive, and there is no mechanism to delete filled or expired orders.
   - The order book is not sorted, making the matching suboptimal.
   - The matching algorithm has O(n^2) complexity, which is not efficient for a real exchange.
4. It's a good practice to use `nonReentrant` modifier to prevent reentrancy attacks in the `placeOrder` and `matchOrders` functions.

Overall, the code provides a basic implementation of a gasless exchange using ERC20Permit for off-chain approvals. However, it is not recommended for use in production without addressing the issues mentioned
in the comments and optimizing the order matching algorithm. To improve this implementation, you could consider the following:

1. Utilize a different data structure, such as a mapping with a linked list or a priority queue, to store and manage orders. This would allow for more efficient order management and matching.

2. Implement a sorting mechanism for the order book to improve the matching algorithm's efficiency.

3. Consider using an off-chain matching engine that periodically submits matched orders to the on-chain contract for execution. This can reduce the on-chain computation and gas costs.

4. Implement an event emission system to notify users of order updates, such as order placement, order matching, and order cancellation.

5. Add additional checks, such as ensuring that the order has not been canceled or filled before executing the trade in the `matchOrders` function.

6. Implement a function for users to cancel their orders.

### Smart Contract CHAT-GPT4 Score

I will score your code based on five criteria: functionality, security, efficiency, code readability, and modularity.

1. Functionality: 3/5
   The code provides basic gasless exchange functionality using ERC20Permit for off-chain approvals. However, the order matching algorithm and data structure need improvement before it's suitable for production use.

2. Security: 3.5/5
   The code utilizes OpenZeppelin libraries, which are widely used and secure. The use of ReentrancyGuard is also a good practice. However, more checks and validations could be added to ensure the safety of the transactions.

3. Efficiency: 2/5
   The O(n^2) order matching algorithm is inefficient, and using arrays to store orders can be expensive. Improvements in the data structure and matching algorithm are necessary for better performance.

4. Code Readability: 4/5
   The code is generally well-structured and easy to understand, with inline comments explaining the implementation. However, some parts of the code could benefit from additional comments, especially in the matchOrders function.

5. Modularity: 3.5/5
   The code is organized into functions that serve distinct purposes. However, it could benefit from further separation of concerns throughthe use of libraries or additional contracts for specific tasks, such as order management, matching, and trade execution.

Overall, I would give your code an average score of 3.2/5. It's a good starting point for a gasless exchange, but there is room for improvement in various aspects. Addressing the issues mentioned in the previous response and optimizing the implementation would significantly enhance the project.

## Conclusion

Chat-GPT and its copycats will change coding for sure. This is the first time I worked fully with a chatbot to write code. It boosted my productivity and creativity. If these tools get even better when they are more targeted to coding, I am sure the future of coding will be much more fun, but we will need much less developers!
