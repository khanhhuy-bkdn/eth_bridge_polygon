// Loading env configs for deploying and public contract source
require('dotenv').config();

// Using hardhat-ethers plugin for deploying
// See here: https://hardhat.org/plugins/nomiclabs-hardhat-ethers.html
//           https://hardhat.org/guides/deploying.html
require('@nomiclabs/hardhat-ethers');

// Testing plugins with Waffle
// See here: https://hardhat.org/guides/waffle-testing.html
require("@nomiclabs/hardhat-waffle");

// This plugin runs solhint on the project's sources and prints the report
// See here: https://hardhat.org/plugins/nomiclabs-hardhat-solhint.html
require("@nomiclabs/hardhat-solhint");

// Verify and public source code on etherscan
require('@nomiclabs/hardhat-etherscan');

const config_fx = require("@maticnetwork/fx-portal/config/config.json");

const config = {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      accounts: { count: 20 },
    },
    localhost: {
      chainId: 31337
    },
    goerli_testnet: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [process.env.DEPLOY_ACCOUNT],
      fxRoot: config_fx.testnet.fxRoot,
      checkpointManager: config_fx.testnet.checkpointManager
    },
    eth_mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [process.env.DEPLOY_ACCOUNT],
      gas: 8100000,
      gasPrice: 8000000000,
      fxRoot: config_fx.mainnet.fxRoot,
      checkpointManager: config_fx.mainnet.checkpointManager
    },
    polygon_testnet: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [process.env.DEPLOY_ACCOUNT],
      gas: 8100000,
      gasPrice: 8000000000,
      fxChild: config_fx.testnet.fxChild,
    },
    polygon_mainnet: {
      url: "https://polygon-mainnet.g.alchemy.com/v2/5H3v-T645AQksySIgSDKBy0TpT23rF6J",
      accounts: [process.env.DEPLOY_ACCOUNT],
      fxChild: config_fx.mainnet.fxChild,
    },
  },
  etherscan: {
    apiKey: `${process.env.VERIFY_SCAN_KEY}`
  },
  solidity: {
    compilers: [
      {
        version: '0.8.4',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ],
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts',
    deploy: 'deploy',
    deployments: 'deployments',
  },
  mocha: {
    timeout: 200000,
    useColors: true,
    reporter: 'mocha-multi-reporters',
    reporterOptions: {
      configFile: './mocha-report.json',
    },
  }
};

module.exports = config;
