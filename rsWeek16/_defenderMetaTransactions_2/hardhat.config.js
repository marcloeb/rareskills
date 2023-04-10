require('dotenv').config();

require('@nomiclabs/hardhat-waffle');
require('@nomiclabs/hardhat-ethers');

task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: '0.8.0',
  defaultNetwork: 'goerli',
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    sepolia: {
      chainId: 11155111,
      url: process.env.ALCHEMY_SEPOLIA_URL,
      accounts: [process.env.WALLET_PRIVATE_KEY],
    },
    goerli: {
      chainId: 5,
      url: process.env.ALCHEMY_GOERLI_URL,
      accounts: [process.env.WALLET_PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.EHTERSCAN_API_KEY,
  },
};
