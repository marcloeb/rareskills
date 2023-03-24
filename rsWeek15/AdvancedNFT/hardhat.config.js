require('@nomicfoundation/hardhat-toolbox');
require('@nomicfoundation/hardhat-foundry');
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: '0.8.18',
  settings: {
    optimizer: {
      enabled: true,
      runs: 10,
    },
  },
  defaultNetwork: 'goerli',
  hardhat: {
    allowUnlimitedContractSize: true,
  },
  networks: {
    goerli: {
      chainId: 5,
      url: process.env.ALCHEMY_GOERLI_URL,
      accounts: [process.env.GOERLI_WALLET_PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.EHTERSCAN_API_KEY,
  },
};
