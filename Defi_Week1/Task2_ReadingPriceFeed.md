# Task 1: Reading Price Feed

Read the a price feed contract ETH USD. And answer questions. Do not answer these questions conceptually. You need to link to the line number of the contract on etherscan. Use mainnet Ethereum.

## The Task Intro

- Visit the price feed oracle for ETH USD. What function is used to get the price of
  ETH USD?
- What is roundId and phaseId?
- What function is called by offchain data sources to put the data on chain?
- How does chainlink verify the address calling that function is allowed to do it?
- What is in the payload of the update function? Don’t just copy and paste transactions, explain what they consist of.
- Use a pricefeed from Chainlink
- What three contracts mentioned in the whitepaper? What are their addresses on the
  Ethereum mainnet for the price feed ETH - USD?
- What discrepancies do you notice between the whitepaper and the actual
  implementation?

## Reading resources

- [Chainlink Whitepaper](https://research.chain.link/whitepaper-v1.pdf)
- [Chainlink Thread intro](https://twitter.com/chainlink/status/1540107442415194114?lang=en)
- [How to get ethereum to usd price in smart contract](https://dapp-world.com/smartbook/how-to-get-ethereum-to-usd-price-in-smart-contract-K4Jf)
- [How Chainlink Price Feeds Secure the DeFi Ecosystem](https://blog.chain.link/chainlink-price-feeds-secure-defi/)
- [Chainlink Data Feeds](https://data.chain.link/)
- [Chainlink Documentation for Data Feeds](https://docs.chain.link/data-feeds/)

## Solution

First task is to find the contract address of the ETH USD Chainlink Price Feed on Etherscan. While searching for the contract address through the etherscan search window, I found only the aggregator, which seemed different.

After a google search I found in the chainlink documentation a [list to all price feeds](https://data.chain.link/). With this I found the Chainlink Ethereum Mainnet ETH USD price [feed documentation](https://data.chain.link/ethereum/mainnet/crypto-usd/eth-usd). On this page I found the contract address: [0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419](https://etherscan.io/address/0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419#code).

First how Chainlink Price Feeds work:

1. Exchanges have data from their trades and expose them through an API.
2. Dataproviders collect data from many exchanges and expose them through an API.
3. Chainlink Nodes collect data from many Dataproviders and expose them through an API.
4. Chainlink Smart Contract aggregates several nodes. The smart contract gets updated based on a Deviation threshold

From here I answer the questions:

- Function used to get the price of ETH USD: `latestRoundData()` line 319
- `roundId` is "the requested round ID as presented through the proxy, this is made up of the aggregator's round ID with the phase ID encoded in the two highest order bytes"
- `phaseId`is incremented each time the underlying aggregator implementation is updated. It is used as key to find the aggregator address. If the current phase id is 5, this means that this proxy has had 5 underlying aggregators since its initial deployment ([read more](https://docs.chain.link/data-feeds/historical-data/)).
- Function called by offchain data sources: In the Proxy for the Aggregator there is the aggrregator function that reveils the Aggregator address. [Etherscan](https://etherscan.io/address/0x37bC7498f4FF12C19678ee8fE19d713b87F6a9e6#code) shows me it is of the Type AccessControlledOffchainAggregator type. I found its [documentation](https://docs.chain.link/data-feeds/api-reference/#requesteraccesscontroller) and the [contract in a github repository (maybe not the offical repository)](https://github.com/smartcontractkit/libocr/blob/master/contract/AccessControlledOffchainAggregator.sol), from there to the baseclass [OffchainAggregator](https://github.com/smartcontractkit/libocr/blob/master/contract/OffchainAggregator.sol). There I found the function `function transmit(bytes calldata _report, bytes32[] calldata _rs, bytes32[] calldata _ss, bytes32 _rawVs) at line 576 (Etherscan 535)`
- How chainlink verifies calling transmit by the address is allowed? It happens in the OffchainAggregator baseclass as well at line 649 (Etherscan 608)

  - Oracle memory transmitter = s_oracles[msg.sender];
  - require( // Check that sender is authorized to report
    transmitter.role == Role.Transmitter && msg.sender == s_transmitters[transmitter.index],
    "unauthorized transmitter"
    );

- Payload of the update function: There are two steps happening in the update process of the AggregationProxy (0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419): The first is proposeAggregator and the second is confirmAggregator. The payload of the first in transaction 0x4d1add140b0a756df30921bd152fba82cc196a786e74f567d0bc529ee0b4aa60

  - 0xf8a2abd3 = Function selector (proposeAggregator(address \_aggregator)
  - 000000000000000000000000b103ede8acd6f0c106b7a5772e9d24e34f5ebc2c -> this is the proposed address

  The payload of the second transaction 0x3ca4491afeca5539ad29b9cb297e184c133aca872349701be67d3b980e2952ec:

  - 0xa928c096 = Function selector (confirmAggregator(address \_aggregator)
  - 000000000000000000000000b103ede8acd6f0c106b7a5772e9d24e34f5ebc2c -> this is the proposed address

  Interestingly, the proxy for the pricefeed does calls and no delegate calls, therefore it is not a real proxy, storage and context is kept in the called contract. As well currently the proxy shows phase 5, but only one upgrade is visible on the proxy. I leave it like it is, if anyone finds out what is happening, mail me at marc@maskenplanet.de

- Use a pricefeed from Chainlink: I created a contract inside the contract folder and a corresponding test in the test folder I used the sepolia Chainlink and tested it with forge test --fork-url https://eth-sepolia.g.alchemy.com/v2/myKey. As well I deployed the contract to the Seplia Network and verified it. You find it the address at Sepolia testnet 0xFC3CD13D9193878438644De611E7c3C4b644BE36
- What three contracts mentioned in the whitepaper? There are many contracts and security features mentionioned in the contract. There is an aggregator proxy ETH / USD (0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419), an aggregator ETH / USD (0x37bC7498f4FF12C19678ee8fE19d713b87F6a9e6), a Link token LINK
- What is missing is the Reputation System that is discussed in the White Paper.

## Conclusion

The intro for the Defi Course are oracles. For me it was great to create a VCF Service, read a Defi Book and read the Chainlink Whitepaper. After this I worked through the Chainlink documentation, created a price feed and was astonished, that there is an API for Automisation of transactions. Interestingly the VCF service is quite expensive and costs 0.5 Link per request. As explained before, the Defi course gives us enough knowlege to step into a topic and learn more about it independently. This is true :-).
