/* global ethers */
/* eslint prefer-const: "off" */

const { getSelectors, FacetCutAction } = require('./libraries/diamond.js');

async function deployDiamond() {
  const accounts = await ethers.getSigners();
  const contractOwner = accounts[0];

  // Deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded or deployed to initialize state variables
  // Read about how the diamondCut function works in the EIP2535 Diamonds standard
  const DiamondInit = await ethers.getContractFactory('DiamondInit');
  const diamondInit = await DiamondInit.deploy();
  await diamondInit.deployed();
  console.log('DiamondInit deployed:', diamondInit.address);

  // Deploy facets and set the `facetCuts` variable
  console.log('');
  console.log('Deploying facets');
  const FacetNames = ['DiamondCutFacet', 'DiamondLoupeFacet', 'OwnershipFacet'];
  // The `facetCuts` variable is the FacetCut[] that contains the functions to add during diamond deployment
  const facetCuts = [];
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName);
    const facet = await Facet.deploy({ gasLimit: 30000000 });
    await facet.deployed();
    console.log(`${FacetName} deployed: ${facet.address}`);
    facetCuts.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet),
    });
  }

  // Deploy NFTFacet
  const NFTLib = await ethers.getContractFactory('LibNFT');
  const nftlib = await NFTLib.deploy();
  await nftlib.deployed();

  const NFTFacet = await ethers.getContractFactory('NFTFacet', {
    libraries: {
      LibNFT: nftlib.address,
    },
  });
  const nftFacet = await NFTFacet.deploy();
  await nftFacet.deployed();

  facetCuts.push({
    facetAddress: nftFacet.address,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(nftFacet),
  });

  // Deploy ERC20Facet
  const ERC20Lib = await ethers.getContractFactory('LibERC20');
  const erc20lib = await ERC20Lib.deploy();
  await erc20lib.deployed();

  const ERC20Facet = await ethers.getContractFactory(
    'ERC20Facet' /*, {
    libraries: {
      LibERC20: erc20lib.address,
    },
  }*/
  );
  const erc20Facet = await ERC20Facet.deploy();
  await erc20Facet.deployed();

  facetCuts.push({
    facetAddress: erc20Facet.address,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(erc20Facet),
  });

  // Creating a function call
  // This call gets executed during deployment and can also be executed in upgrades
  // It is executed with delegatecall on the DiamondInit address.
  let functionCall = diamondInit.interface.encodeFunctionData('init');

  // Setting arguments that will be used in the diamond constructor
  const diamondArgs = {
    owner: contractOwner.address,
    init: diamondInit.address,
    initCalldata: functionCall,
  };

  // deploy Diamond
  const Diamond = await ethers.getContractFactory('Diamond');
  const diamond = await Diamond.deploy(facetCuts, diamondArgs);
  await diamond.deployed();
  console.log();
  console.log('Diamond deployed:', diamond.address);

  // returning the address of the diamond
  return diamond.address;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

exports.deployDiamond = deployDiamond;
