require('@nomicfoundation/hardhat-toolbox');
require('@openzeppelin/hardhat-upgrades');
require('@nomiclabs/hardhat-ethers');
require('dotenv').config();
require('@nomiclabs/hardhat-etherscan');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: '0.8.17',
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  defaultNetwork: 'goerli',
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
