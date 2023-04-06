require('@nomicfoundation/hardhat-toolbox');
require('@nomicfoundation/hardhat-foundry');
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.8.18',
        settings: {},
      },
      {
        version: '0.4.24',
        settings: {},
      },
    ],
  },
  gasReporter: {
    enabled: true,
  },
  defaultNetwork: 'sepolia',
  hardhat: {
    allowUnlimitedContractSize: true,
  },
  networks: {
    sepolia: {
      chainId: 11155111,
      url: process.env.ALCHEMY_SEPOLIA_URL,
      accounts: [process.env.WALLET_PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.EHTERSCAN_API_KEY,
  },
};
