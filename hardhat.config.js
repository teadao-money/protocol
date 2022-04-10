require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-waffle");

const fs = require("fs");
const mnemonic = fs.readFileSync("./.secret").toString().trim();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
// task("accounts", "Prints the list of accounts", async () => {
//   const accounts = await ethers.getSigners();

//   for (const account of accounts) {
//     console.log(account.address);
//   }
// });

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    hardhat: {
      accounts: { mnemonic: mnemonic }
    },
    kovan: {
      url: `https://kovan.infura.io/v3/6d7d276d251d4f8cb9a66e916ff48508`,
      network_id: 42, // Ropsten's id
      gas: 7000000, // Ropsten has a lower block limit than mainnet
      confirmations: 2, // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 2000000, // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true,
      accounts: { mnemonic: mnemonic }
    },
    bnb: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545/`,
      network_id: 97,
      confirmations: 1,
      gas: 20000000,
      timeoutBlocks: 20000000,
      skipDryRun: true,
      accounts: { mnemonic: mnemonic }
    },
    bnbMainNet: {
      url: `https://bsc-dataseed.binance.org`,
      network_id: 56,
      confirmations: 1,
      gas: 20000000,
      timeoutBlocks: 20000000,
      skipDryRun: true,
      accounts: { mnemonic: mnemonic }
    }
  },
  solidity: {
    compilers: [
      {
        version: "0.5.16",
        settings: {
          // See the solidity docs for advice about optimization and evmVersion
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.0",
        settings: {
          // See the solidity docs for advice about optimization and evmVersion
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.4.18",
        settings: {
          // See the solidity docs for advice about optimization and evmVersion
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.6.6",
        settings: {
          // See the solidity docs for advice about optimization and evmVersion
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.7.5",
        settings: {
          // See the solidity docs for advice about optimization and evmVersion
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
  },
  etherscan: {
    apiKey: "6N5H8711IXTR3CWSXHUJ2NG7UD71PDE1HS" //bnb
    // apiKey: "PAJ2TIU2TYP92YT2C53W898IC1YTIJ2KVX",// kovan
  }
};
