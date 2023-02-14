# \*\*\*\*ERC1155 written in YUL, tested with FOUNDRY

Our task of the last 3 weeks were to create a ERC1155 contract purely in YUL and test it with foundry. This was quite a tough exercise, because I was new to YUL programming and as well to foundry. Find below my journey in the last 2 weeks:

## 1. Research

The beginning for me was to understand what I needed to achive, so I revisited the ERC1155 specification and implementation in open zeppelin and solemate

- [ERC1155 Specification](https://github.com/ethereum/eips/issues/1155)
- [Open Zeppelin ERC 1155 Specification](https://docs.openzeppelin.com/contracts/3.x/erc1155)
- [OpenZeppelin 1155 Github Repo](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol)
- [Solmate 1155 Repo](https://github.com/transmissions11/solmate)

Then I realized I need to get familiar with foundry, which seems easy, but still needs time. But the investment is worth it, as I can say now after I finised the exercise:

- [Patrick Collins: Intro to Foundry | The FASTEST Smart Contract Framework](https://www.youtube.com/watch?v=fNMfMxGxeag)
- [Nader Dabit: Smart Contract Develpment with Foundry](https://www.youtube.com/watch?v=uelA2U9TbgM)
- [Nader Dabit: Workshop with Foundry](https://github.com/dabit3/foundry-workshop)
- [ETH Global: A complete Introduction to Smart Contract Development with Foundry](https://www.youtube.com/watch?v=de_fomBbLmM)
- [Antonio Ufano: Foundry vs. Hardhat](https://chainstack.com/foundry-hardhat-differences-performance/)
- [Brock Elmore: How ot Foundry 2.0: Brock Elmore](https://www.youtube.com/watch?v=EHrvD5c93JU)

After watching the tutorials I read the offical documentation and installed foundry on my machine. I created a hardhat project and added foundry to it, since there is official plugin for hardhat to run foundry with hardhat side by side:

- [Foundry Book: The official documentation of foundry](https://book.getfoundry.sh)
- [Installing Foundry on your machine](https://book.getfoundry.sh/getting-started/installation)
- [Hardhat Plugin: hardhat-foundry](https://hardhat.org/hardhat-runner/plugins/nomicfoundation-hardhat-foundry)
- [Installation Instruction for Hardhat-Foundry projects](https://hardhat.org/hardhat-runner/docs/advanced/hardhat-and-foundry)
- [Foundry github repo](https://github.com/foundry-rs/foundry)
- [Hardhat documentation](https://hardhat.org)

Then I continued to make the compiling of yul contract work with solc, based on a sample project. This basically enable us to use forge compile, forge debug, forge test with a contract written purely in YUL. Furthermore I installd a github plugin for yul files to get error messages away, make working with brackets easier and color code my code

- [Yul developer experience](https://github.com/CodeForcer/foundry-yul.git)
- [Solidity+Yul Semantic Syntax](https://marketplace.visualstudio.com/items?itemName=ContractShark.solidity-lang)

I further used GitHub Copilot to take advantages of AI in coding. This is a double-edged sword however. It helped me a lot to understand how to setup test files in foundry and as well creating yul code, especially repeating pattern of code I created. However GitHub Copilot is hallucinating quite a bit, so I spent a lot of time debugging the created code, destroying the productivity I gained. I guess while I continue to work with GitHub Copilot, this becomes more obvious, but I think this paradox remains immanent for quite some time. Still I will continue to work with Co-Pilot.

- [GitHub Copilot: Your AI pair programmer](https://github.com/features/copilot)

After setting up the environment, there was the need to understand, how solidity an YUL work. Especally encoding of dynamic Arrays and Strings longer as 32 bytes are a tough thing. Shorty said, solidity is encoding dynamic arrays and strings with an offset, length and values. The offsets are very tricky, because you create them in YUL memory, but the offsets need to be translated to the context they are deployed to (eg log or return value). As well memory management in YUL does not exist, you need to write it for yourself - I decided to work with pointers because they are very easy to implement and mimic solidity. Mappings I implemented as well as a keccac256 on the two keys, that was quite easy, as well accessing storage. These where my resources:

- [Offical YUL documentation](https://docs.soliditylang.org/en/v0.8.17/yul.html)
- [Layout of State Variables in Storage](https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#storage-inplace-encoding)
- [Angle Explains: Playing with Yul (Assembly)](https://blog.angle.money/playing-with-yul-cd4785e456d8)
- [ABI Encoding](https://www.youtube.com/watch?v=RZytWxtKODg)
- [Signature Database](https://openchain.xyz/signatures)

## 2. Implementation

After I did that much research I wanted to know what other people did. I found 2 projects that already implemented an ERC1155 Contract in YUL, one even with a youtube Video:

- [Frenchkebab: ERC1155 in pure YUL with Hardhat](https://github.com/Frenchkebab/ERC1155-in-pure-yul)
- [Jesper Kristensen: Repo for ERC1155 in Pure Yul](https://github.com/jesperkristensen58/erc1155-in-pure-yul)
- [Jesper Kristensen Video: Learn to Code ERC1155 in Pure Yul](https://www.youtube.com/watch?v=F-Wo5D-IX9s)

With that in hand I was fully prepared and pumped to start coding. Basically the concept is the following. When you create a pure yul contract you need to nest a object/code block in another object/code block. The first object/code block is the constructor, that gets executed when deployed to the blockchain. The second block is the code itself. I will comment here some elements how I implemented the code:

- Initalization: I set the memory pointer with every call to the contract to point to 0x80 and avoid that eth is sent to the contract, because it is not prepared for this.
- Memory: YUL just give you access to memory with mstore and mload. The memory managmement needs to be implemented by the code itself. I decided to use a memory pointer logic, because I did not want to have memory addresses in my code.
- Storage mappings: In this example 2 mappings need to be stored (mapping(uint256 => mapping(address => uint256)) private \_balances; and mapping(address => mapping(address => bool)) private \_operatorApprovals;). I mimiced solidity approach and keccac hashed the keys, as well added a feature to avoid hash collition.
- Storage memory: I store dynamic strings from storage position 1 on.
- Storage of owner: I store the owner in memory position 0
- After this I defined the events TransferSingle, Transfer Batch and Approval for all. The URI event I ignored, because Open Zeppelin is not implementing it, because the ERC1155 has no specific naming for tokens. Therefore only one string need to be stored
- Funtion selectors: In YUL the function selectors are the first 4 byes of the calldata. Therefore a switch statement for the function selector decides which function to call. The signature database helps here a lot.
- Function parameter: Parameters follow the function selector in a defined pattern of the signature. To decode, you need to get the 32 byte word out of the calldata, piece by piece. This was one of the most important part of the excerise, to understand how to decode the calldata and load it to a variable or to memory.
- Return values are easy - just use return. This terminates the yul processing, no matter where you are in the code.
- Helper methods for safe adding and safe substracting, less than equal and greater than equal or require are listed at the end
- Main Functionality is inside the function selector blocks of the switch statement, if reused you find them right after the switch statement. For example the mint function is called from mintBatch, so I created a \_mint function.

All this development is incredible difficult without a development framework. For me it was foundry. I used mainly forge compile, forge test and forge clean. If I needed a stack trace I was using the switches -vvvv. In there you find what foundry YUL gives back and what YUL function are called. If something did not make sense, I emitted in YUL a log0 or log3 event and checked in the foundry stack trace the values. That the trace is not cluttered you need to focus on one file with --match-path test/ERC1155.t.sol option. I started to set other test function to private to avoid the console to be cluttered. So my favorite commands in foundry were:

- forge test --match-path test/ERC1155.t.sol
- forge test --match-path test/ERC1155.t.sol -vvvv

I know that other people use chisel and foundry debug. I remained with the -vvvv switch but am not sure if this was the most productive option. It was for sure not possible to see what happened step by step in memory. But during development it was never necessary to do so. Chisel I did not understand fully how to use it so I left it behind, but for sure I will use both tools.

Creating the test methods was easy with GitHub Co-Pilot. I got immediately a structure:

- Define Events on top of the test file, so these are available in every test function
- Avoid Fuzzing cases with vm.assume or bound that do not make sense
- Define variables once in the testfunction so I do not reach the stack too deep error and reuse these variables (probably these variables could be placed on the top of the test file, too)
- Do vm.expectEmit, followed by an emit of the event. Like this, foundry will check if this event was emmitted and emmited the way you defined it.
- Abi Encode the function call an make the function calls to the yul contract. Receive the success flag and assert it. Decode the received data and assert it.
- Repeat the Abi Encode in the way that makes sense for the implemented yul contract.

I created 8 tests for the yul contract:

- TestSetOwner: I was not able to set the owner during deployment, therefore I created a setOwner function that can be called once. This is not recommended for a production deployment (front running) :-). Because this exercise is for educational purposes, I implemented it this way. I set the owner - this call succeeds. With another call, the setowner fails.
- TestIsApprovedForAll tests the isApprovedForAll function that it can be called succesfully by the contract and another user
- TestSetApprovalForAll sets a new account for an operator, checks if this is true with the isApprovedForAll function and checks that if fails when a user tries to approve himself.
- TestMintAndBurn mints a token, checks the balance, burns the token and checks the balance again
- TestBatchOfBalance mints 3 tokens and checks the balance in a batch
- TestSafeTransferFrom mints a token, checks the balance, transfers it to another user, checks the balance of the old owner and new owner
- TestSafeBatchTransferFrom mints thre tokens in a batch, checks the balances in a batch and transfer the tokens to a receiver. Then the balances are checked, the tokens burned in a bach and again the balances checked.
- testMintAndBurnBatch mints tokens, checks the balances, burns the tokens and checks the balances, all in a batch.
- testSetAndGetUri sets the URI, gets the URI and compares the result.

## 3. Conclusions

🎉️🎉️🎉️! Working with YUL is tough, this was my hardest assigment in the reareskills bootcamp so far. Without a framework like foundry I would not be able to finish this task in 2 weeks. This work had a huge learning experience. From ERC1155 to foundry to Upcode to YUL to Encoding dynamic arrays and string in calldata and memory. At the end of this article, remember solidity does encoding of values always in 32 bytes. For mappings it is a keccac256 on the two keys. For dynamic arrays and dynamic strings it follow the pattern offset, lenght, values. Best of all, the project works with hardhat as well. If you are reading this while you work on this assignment: Dont give up, after doing this exercise and reading all the code you understand Solidity, YUL and the EVM much better than before!
