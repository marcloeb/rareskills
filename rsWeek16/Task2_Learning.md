# Task 2: Learning

## How to sign & verify an Ethereum message off chain

[How to sign & verify an Ethereum message off chain](https://cryptomarketpool.com/how-to-sign-verify-an-ethereum-message-off-chain/) writes about cryptographic signatures:

> The combination of smart contracts and cryptographic signatures allow payments to be made off chain for a future date and time. This is similar to writing checks to pay for a product or service in the future.

This can happen for any kind of message, not only for payments. The message can be a string, a hash or a typed data. The signature can be split into r, s and v. The r and s are the signature and v is the recovery id. The recovery id is used to determine the public key of the signer. R, S and V will be discussed later in this course.

The mechanism in detail is:

- An owner signs a message with a private key. He derives r, s, v from that signing.
- A signature (65 bytes) is constructed by abi.encodePacked(r,s,v)
- The receiver from the signature can send it to a smart contract with the orignial message
- The smart contract abi.endodes the message, hashes it, adds the EthSignedMessage to it, encodes it again and hashes it again
- From the EthSignedMessageHash we can call recover with either the signature or r,s,v and retrieve the address of the signer

A message hashed and then signed by an owner, the signature is passed to another user, On another computer the computer the message can be hashed again and the public key/address can be recovered from the hashed message.

As a result, I can compare the owner with the signer. If both match, I can execute a certain action, like minting an NFT or permit an approve of a ERC20 transfer, or like later in my exercise do gasless transactions.

In the learning Project there are two examples, the Verifier and the VerifySigniture contract, both with the same concept:

### Signing

1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

### Verify

1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer

## EIP 721: Typed strucutred data hashing and signing and EIP 2612 ERC20 Permit

[EIP2612: ERC20 Permit](https://eips.ethereum.org/EIPS/eip-2612)

The ERC20 Permit allows a user to approve a transfer of a amount of tokens, even when he is not the owner of that token. For this he gets from the owner a signature, that can be split in the values r, s and v. I dont know theoretically what this means, and learn this in a later exercise:

```apache
let signature = await signer.provider.send("eth_signTypedData_v4", [myAccount, JSON.stringify(typedData)]);

const split = ethers.utils.splitSignature(signature);
console.log("r: ", split.r);
console.log("s: ", split.s);
console.log("v: ", split.v);
```

Another user can then execute the extension function Permit on the ERC20 token and take the gas costs:

```apache
    const tx = await writeContracts.YourContract.permit(
      myAccount,
      contractAddr,
      amount,
      deadline,
      split.v,
      split.r,
      split.s,
    );
    await tx.wait();
```

[EIP-712: Typed structured data hashing and signing](https://eips.ethereum.org/EIPS/eip-712)

The standard 712 writes:

> We are seeing growing adoption of off-chain message signing as it saves gas and reduces the number of transactions on the blockchain.

This can be lazy minting, where the owner of a contract signs the permission for a user to mint an NFT or a Approval for another user to transfer an ERC20 token.

Before ERC712 Messages in Signing were shown as HEX numbers, making it impossible for a regular user to understand these messages. With the implementation of EIP 712 it is possible to show messages that are readable.

Interesting implementation detail: we pass an object, that has The following properties:

- a property of types, that is an object with a property EIP712Domain and several further properties like Permit. EIP712 Domain and Permit are arrays that contain name/type pairs.
- a property primaryType, which defines what will be shown in the message
- a property domain, which is an Object that contains properties for all the values I defined in the EIP712Domain Object
- a property Permit, which is an Object that contains properties for all the values I defined in the Permit Object

This typed Data can be sent with`eth_signTypedData_v4`, where I add the account address and the Json stringified data:

```àpache

 const typedData = {
      types: {
        EIP712Domain: [
          { name: "name", type: "string" },
          { name: "version", type: "string" },
          { name: "chainId", type: "uint256" },
          { name: "verifyingContract", type: "address" },
        ],
        Permit: [
          { name: "owner", type: "address" },
          { name: "spender", type: "address" },
          { name: "value", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" },
        ],
      },
      primaryType: "Permit",
      domain: {
        name: "Marc",
        version: "1",
        chainId: network.chainId,
        verifyingContract: contractAddr,
      },
      message: {
        owner: myAccount,
        spender: contractAddr,
        value: amount,
        nonce: nonce,
        deadline: deadline,
      },
    };

let signature = await signer.provider.send("eth_signTypedData_v4", [myAccount, JSON.stringify(typedData)]);
```

## Uni- and Bidirectional Payment Channels

Unidirectional Payment channels are smart contracts, where a person sends ETH to this contract and a receiving person can receive the ETH by providing a signature from the sender. Bidirectional Payment Channels allow the payment to go in both directions.

As well payment channels use off-chain message signing to reduce gas fees by lowering the numbers of transactions. [How to create a payment channel on Ethereum](https://cryptomarketpool.com/how-to-create-a-payment-channel-on-ethereum/) describes it as follows:

> A payment channel is a process where participants can make multiple transfers without sending a transaction to the Ethereum blockchain. Once the final transaction occurs between the participants the recipient can claim their funds by submitting one final transaction to the smart contract on the blockchain. This allows both parties to avoid fees involved with multiple transactions.

I worked through the [Unidirectional Payment Channel ](https://solidity-by-example.org/app/uni-directional-payment-channel/) from from Solidity by Example. A contract gets deployed with ether on it. The receiver is allowed to withdraw the signed amount of ether from the sender by calling the close function and providing the signature of the sender and the amount as parameters. This will selfdestruct the contract and send the remaining ether to the sender.

Then I worked through the [Bidirectional Payment Channel](https://solidity-by-example.org/app/bi-directional-payment-channel/) from Solidity by Example. This contract is a bit more complex, as it allows the sender and the receiver to send ether to each other. The contract is deployed with ether on it. Additionally:

- the users are set
- the balances of the users
- An expireAt and challengePeriod are set

The idea of the bidirectional payment channel is that from the original amount of ether payed at contract creation, users can do as many transaction off-chain as they want. If they agree on a new balance and the expireAt point has not passed, then both users sign a message containing the contract address and the new balances and a nonce.

Then one of the users sends a transaction to the contract echallengeExit function with the new balances, the signatures and a nonce. If the signature match to each user, which means both users agreed on the new balances, after the challenge Period the withdraw function can be called and the agreed amount can be withdrawn.

A very cool and gas efficient way to do payments on Ethereum 🤩️. For both project I implemented a foundry test.

## Gasless Transactions

The idea of gaslsess transactions is what it says: a transaction that does not require gas. This is done by a third party, that pays the gas fees and then gets reimbursed by the person signing the transaction. The users signs for this a transaction, sends it to a relayer, the relayer checks if the signiture is correct, wraps the call into a transaction that is sent to the contract on the blockchain. For this action, the relayer pays the gas fee.

I watched [How to Relay Gasless Meta-Transactions](https://www.youtube.com/watch?v=Bhz5LJbq9YY), an Update to an OpenZeppelin Workshop with OpenZeppelin Defender. The idea is to use a relayer to pay the gas fees for a transaction. The relayer is a third party that pays the gas fees and then gets reimbursed by the person deploying the contract:

> A gasless Metatransaction is basicly a way of decupling the person signing the transaction and the person paying the gas fees. The idea is that the person signing the transaction is not the person paying the gas fees. This is done by a third party, that pays the gas fees and then gets reimbursed by the person signing the transaction.

This is EIP describes the idea of a relayer/trusted forwarder:
[ERC-2771: Secure Protocol for Native Meta Transactions ](https://eips.ethereum.org/EIPS/eip-2771)

At the end I realized it is still worth watching Santiagos Palladino (lead developer) old OpenZeppelin Workshop [Workshop Recap: Gasless MetaTransactions with OpenZeppelin Defender](https://blog.openzeppelin.com/gasless-metatransactions-with-openzeppelin-defender/). It gave me quite some insights. The workflow of gasless transactions are:

1. The user signs a meta transaction and sends this by a http request to OpenZeppelin Defender relayer address (webhook).
2. There an autotask with a webhook receives this request and validates it - we can place a custom logic there, there are example in OpenZeppelins repository and on the documentation site. it is not only ment for a gasless transaction only.
3. The Relayer then wraps the request, if marked valid by the autotask, in a transaction, signs it and sends it to the blockchain for its own gas cost (pays). Therefore the relayer needs to have a positive eth balance and we need to transfer eth onto it.
4. The call goes to the minimal forwarder contract on chain, validates the signature and forwards the call to the destination contract, in the sample of the workshop a registry
5. The registry then just places the name into a mapping.

As well there are alternatives to OpenZeppelin Defender, which rely on other techniques like a pool of relayers, not a personalized relayer.

## Account Abstraction

In short account abstraction means that the EOA is not only a key pair of public and private key, it is a smart contract that can be programmed. The main goal is to remove the friction of onboarding to make crypto more accessible and available for mass adoption. In a few longer words, account abstraction is:

> In short, account abstraction means that not only the execution of a transaction can be arbitrarily complex computation logic as specified by the EVM, but also the authorization logic of a transaction would be opened up so that users could create accounts with whatever authorization logic they want. Currently, a transaction can only “start from” an externally owned account (EOA), which has one specific authorization policy: an ECDSA signature. With account abstraction, a transaction could start from accounts that have other kinds of authorization policies, including multisigs, other cryptographic algorithms, and more complex constructions such as ZK-SNARK verification.

The ethereum foundation pushes this approach and a set of contracts available:

- [Account Abstraction by eth-infinitism](https://github.com/eth-infinitism/account-abstraction)
- [Trampoline Example](https://github.com/eth-infinitism/trampoline-example)

There was even a [Account Abstraction Grants 2023](https://esp.ethereum.foundation/account-abstraction-grants) from the Ethereum Foundation in 2023. They suggested to work on [these topics](https://hackmd.io/fpff2e4jTSqD0dHhSTUasA?both). This sounds very serious!

The idea is that developers can implement the contracts on these contracts and create new application wallets that interact with smart contracts. Use cases are:

### Recovery

- Wallet/seed phrase, possiblity for social recovery
- 2 Factor Authentication

### Signature abstraction

- Multisig
- Per-device keys
- BLS Signature (other signatures than ECDA)
- Quantum resistant signatures

### Roles & policies

- Spending limits (smalpayment), whitelist
- Corporate accounts, multiple signatures
- Session keys -> allows to make transaction for one game with a limit
- Subscriptions
- Allowence to withdraw
- Pay off-chain with credit card

### Gas Abstraction

- Sponsoring gas for users
- Pay gas with ERC20 tokens
- Privacy: Mixer like tornado cash -> withdraw funds from a mixer you get known. Now you can withdraw completely anonymous (Private withdrawal from ZK mixers)
- Cross Chain operation but not want to use my account on other networks. -> my signature, but I do not need to have balances on those networks.

### Batching and Automation Execution

- Batch transaktionen
- Subscriptions
- Transaktionen bündeln-> tiefere kosten
- Trading bot-> Kauf bei gewissen Preisen Zustand x dann mache y

This list does not seem complete, but hey, this is blockchain and things move fast ;-). I read these ressources:

For sure this a big thing, you can feel it reading the docs.

- [ERC-4337: Account Abstraction Using Alt Mempool](https://eips.ethereum.org/EIPS/eip-4337)
- [Implementing account abstraction as part of eth1.x](https://ethereum-magicians.org/t/implementing-account-abstraction-as-part-of-eth1-x/4020)
- [Letters from a Zeneca 36: All about ERC-4337](https://zeneca33.substack.com/p/letter-36-all-about-erc-4337)
- [Ethereum Game Changer!! The ERC-4337 Upgrade Explained!💥](https://www.youtube.com/watch?v=Ac3QRemCHoo)
- [ERC 4337 Account Abstraction? Wie funktionierts und was kann´s](https://www.youtube.com/watch?v=UGVnESC4-_w)
- [Account Abstraction: Making Accounts Smarter](https://www.youtube.com/watch?v=HbNdGex47ks)
- [HUGE opportunity for Web 3.0 Devs to make $$$ building cool stuff!](https://www.youtube.com/watch?v=HGIaMy2kCpw&t=4s)
- [ERC 4337 Account Abstraction? Wie funktionierts und was kann´s](https://www.youtube.com/watch?v=UGVnESC4-_w)
- [Account Abstraction and ERC-4337 Wallets](https://www.youtube.com/watch?v=-syoWCmi4Mo)
- [Account Abstraction: Making Accounts Smarter](https://www.youtube.com/watch?v=HbNdGex47ks)
- [Talk | ERC 4337: Account Abstraction via Alternative Mempool](https://www.youtube.com/watch?v=eyT6WzJmWyc)
- [You Could Have Invented Account Abstraction: Part 1](https://www.alchemy.com/blog/account-abstraction)
- [Account Abstraction Part 2: Sponsoring Transactions Using Paymasters](https://www.alchemy.com/blog/account-abstraction-paymasters)
- [Account Abstraction Part 3: Wallet Creation](https://www.alchemy.com/blog/account-abstraction-wallet-creation)
- [Account Abstraction Part 4: Aggregate Signatures](https://www.alchemy.com/blog/account-abstraction-aggregate-signatures)

We do not work on account abstraction in this week, so I finish my study here. I will come back to this topic for sure in the future - doing my own project or just reading more about it.

## Conclusion

Woooohaaaa. I always think it cannot get worse, it remains difficult. But still, I am happy to have learned so much. Account abstraction is to be done in reading and I will create a gasless exchange, but just simple points -> both have own readme files.

I am looking forward to the next week, where I will learn about the theoretical details of Eliptic Curve Cryptography and how it is used in Ethereum.

Done 🎉️.
