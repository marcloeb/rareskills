# Clone Pattern ERC-1167: Minimal Proxy Contract

The clone pattern is very similar to the proxy pattern. A proxy pattern has just one proxy and one impletation. A Clone Pattern has a multiple proxies that have one implementation, with the difference that the clones are immutable.

> "To simply and cheaply clone contract functionality in an immutable way, this standard specifies a minimal bytecode implementation that delegates all calls to a known, fixed address."

## 1. The Task

Clone Pattern. Create a contract that lets people create new ERC20 tokens with a fixed supply easily. Compare the gas cost of the clone pattern to the gas cost of creating the entire contract

```shell
REPORT_GAS=true npx hardhat test
```

## 2. The Solution

There were no intro Videos given in this task, just a link to a [OpenZeppelin Clone Library](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Clones.sol). So I watched a few Videos and found a OZ Workshop:

- [Workshop Recap: Cheap contract deployment through Clones](https://blog.openzeppelin.com/workshop-recap-cheap-contract-deployment-through-clones)
- [Minimal Proxy Contract | Solidity (0.7)](https://www.youtube.com/watch?v=9xqoK2nKkM4)
- [Rareskills: EIP-1167 - Minimal Proxy Standard with Initialization (Clone pattern)](https://www.rareskills.io/post/eip-1167-minimal-proxy-standard-with-initialization-clone-pattern)

The [OpenZeppelin Workshop](https://github.com/OpenZeppelin/workshops) was most helpful and doing exactly what I needed to do, therefore I decided to upgrade this sample from Solidity 0.6 to 0.8.17, bacause it is exactly what I need to achieve. Basically it compares the Clone pattern with the Proxy Pattern and a regular instantiation. For creating a contract the Naive/regular instantiation is the most expensive, followed by the proxy followed by the clone. This result makes sense, because each contract in the mentioned order has less and less functionality.

A drawback is calling the deployed function compared to the regular contract - similar to the proxy contract it has a slightly higher gas cost (700 gas per call).

Another drawback from clones is that they are immutable.

The solution contains 3 factories, one for each pattern:

```àpache
contract FactoryNaive {
  function createToken(string calldata name, string calldata symbol, uint256 initialSupply) external returns (address) {
        ERC20PresetFixedSupplyUpgradeable token = new ERC20PresetFixedSupplyUpgradeable();
        token.initialize(name, symbol, initialSupply, msg.sender);
        return address(token);
  }
}

contract FactoryProxy {
  address immutable tokenImplementation;

  constructor() {
        tokenImplementation = address(new ERC20PresetFixedSupplyUpgradeable());
  }

 function createToken(string calldata name, string calldata symbol, uint256 initialSupply) external returns (address) {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            tokenImplementation,
            address(this),
            abi.encodeWithSelector(ERC20PresetFixedSupplyUpgradeable.initialize.selector, name, symbol, initialSupply,
            msg.sender)
        );
        return address(proxy);
  }
}

contract FactoryClone {
  address immutable tokenImplementation;

  constructor() {
      tokenImplementation = address(new ERC20PresetFixedSupplyUpgradeable());
  }

  function createToken(string calldata name, string calldata symbol, uint256 initialSupply) external returns (address) {
        address clone = Clones.clone(tokenImplementation);
        ERC20PresetFixedSupplyUpgradeable(clone).initialize(name, symbol, initialSupply, msg.sender);
        return clone;
    }
}
```

Each contract calls a ERC20 Token with fixed Supply, the ability to burn and no access control for minting and pausing - Upgradable that we can initalize it. Its an OpenZeppelin [ERC20PresetFixedSupplyUpgradable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20PresetFixedSupply) contract. This contract is created in the constructor for the proxy and the clone, but not for the regular instantiation. Here we see that the proxy and clone point to one implementation.

Lastly the test - this is very sweet done by OpenZeppelin:

```àpache
async function deploy(name, ...params) {
  const Contract = await ethers.getContractFactory(name);
  return await Contract.deploy(...params).then(f => f.deployed());
}
```

It starts with a async function deploy that encapsulates the getContractFactory and deploys the contract, waiting for the deploy and returning the factory. This makes the following contract much more clean.

But it does not stop there, the code iterates over the 3 contract names (FactoryNaive, FactoryProxy, Factory Clone) and does for each the same test. As usual before Fixtures we do a before(async function(), here to get the accounts and the contract.

```àpache
describe('factories', function() {
  for (const name of [ 'FactoryNaive', 'FactoryProxy', 'FactoryClone']) {
    describe(name, function() {
      before(async function() {
        this.accounts = await ethers.getSigners();
        this.factory = await deploy(name);
      });

      it('factory deployment cost', async function() {
        await this.factory.deployTransaction.wait();
      });

      it('wallet deployment cost', async function() {
        const tx1 = await this.factory.createToken('name', 'symbol', 1000, { from: this.accounts[0].address });
        const { gasUsed: createGasUsed, events } = await tx1.wait();
        const { address } = events.find(Boolean);
        console.log(`${name}.createToken: ${createGasUsed.toString()}`);

        const { interface } = await ethers.getContractFactory('ERC20PresetFixedSupplyUpgradeable');
        const instance = new ethers.Contract(address, interface, this.accounts[0]);
        const tx2 = await instance.transfer(this.accounts[1].address, 100, { from: this.accounts[0].address });
        const { gasUsed: transferGasUsed } = await tx2.wait();
        console.log(`ERC20.transfer:           ${transferGasUsed.toString()}`);
      });
    });
  }
});
```

Then it deploys the contract again (if you know why, wite me at marc.loeb(at)bluesky-information.com) and starts the measurement for the createToken function and a transfer function.
Very well accomplished.

```shell
    FactoryNaive
      ✓ factory deployment cost
FactoryNaive.createToken: 1837128
ERC20.transfer:           52095
      ✓ wallet deployment cost
    FactoryProxy
      ✓ factory deployment cost
FactoryProxy.createToken: 954582
ERC20.transfer:           59550
      ✓ wallet deployment cost
    FactoryClone
      ✓ factory deployment cost
FactoryClone.createToken: 187897
ERC20.transfer:           54773
      ✓ wallet deployment cost
```

## 3. Conclusion

I was supprised of the quality of the OpenZeppelin Contracts, there is a lot of functionality just waiting for you to be discovered. It seems that reading code is a core competency I need to continue to improve. Event with the rise of AI Tools in Coding, the review functionality gains more and more of importance. I enjoyed working through cloning and proxy contracts :-). Done 🎉️ .
