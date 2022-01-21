// const Web3 = require("web3");
// const web3 = new Web3("https://data-seed-prebsc-1-s1.binance.org:8545/");
// const MilkyToken = artifacts.require("MilkyToken");
// const PancakeFactory = artifacts.require('PancakeFactory');
// const PancakePair = artifacts.require('PancakePair');
// const WETH9 = artifacts.require('WETH9');
// const BondingCalculator = artifacts.require('PriceFeed');
// const BondMilkyBNB = artifacts.require('BondMilkyBNB');
// const MilkyTreasury = artifacts.require('MilkyTreasury');
// const MilkyStaking = artifacts.require('MilkyStaking');
// const SMilky = artifacts.require('sMilky');
// const RelayImplementation = artifacts.require("KawaiiRelay");
// const fs = require('fs');
// const HDWalletProvider = require('@truffle/hdwallet-provider');
// const mnemonic = fs.readFileSync('./.secret').toString().trim();
// const listWallets = new HDWalletProvider(mnemonic, "https://kovan.infura.io/v3/8d62942fd62641a7ab758673105b6df3").wallets;
// let addressPrivatekey = {};

// Object.entries(listWallets).forEach((item, index) => {
//   addressPrivatekey[item[0]] = item[1].privateKey.toString("hex");
// });

// const {expectRevert} = require("openzeppelin-test-helpers");
// const {getSignature} = require("../config.js");


// async function wait(ms) {
//   return new Promise(resolve => {
//     setTimeout(resolve, ms);
//   });
// }

// async function getReserves(pair) {
//   let reserve = await pair.getReserves();
//   console.log("Reserve 0: " + reserve[0] + " Reserve 1: " + reserve[1]);

// }


// contract("MilkyToken\n", function (accounts) {
//   let governance = accounts[0];
//   let account1 = accounts[1];
//   let account2 = accounts[2];
//   let account3 = accounts[3];
//   let account4 = accounts[4];
//   let account5 = accounts[5];
//   let transaction;
//   let pancakeFactory;
//   let wETH9;
//   let pancakeRouter;
//   let milkyToken;

//   describe("Test full flow\n", function () {

//     it("Test", async function () {
//       pancakeFactory = await PancakeFactory.new(governance, {from: governance});
//       let CHAINID = pancakeFactory.constructor.network_id
//       console.log(CHAINID == 97)
//       console.log("\n1. create pancakeFactory bsc contract: https://testnet.bscscan.com/address/" + pancakeFactory.address);

//       wETH9 = await WETH9.new({from: governance});
//       console.log("\n2. create WETH9 bsc token contract: https://testnet.bscscan.com/address/" + wETH9.address);


//       milkyToken = await MilkyToken.new(500, account4);
//       console.log("\n4. create milkyToken contract: https://testnet.bscscan.com/address/" + milkyToken.address)

//       transaction = await pancakeFactory.createPair(milkyToken.address, wETH9.address)
//       console.log("\n8.  create pair transaction: https://testnet.bscscan.com/tx/" + transaction.tx)

//       let pool = await pancakeFactory.getPair(milkyToken.address, wETH9.address);
//       let pair = await PancakePair.at(pool)

//       transaction = await milkyToken.setIsCharged(pool, true);
//       console.log("\n9. milkyToken setAddressPair transaction: https://testnet.bscscan.com/tx/" + transaction.tx)

//       let calculator = await BondingCalculator.new();
//       console.log("\n13. BondingCalculator transaction: https://testnet.bscscan.com/address/" + calculator.address)

//       let milkyTreasury;
//       let relayProxy;
//       if (CHAINID === 97) {
//         milkyTreasury = await MilkyTreasury.at("0x297c0337f8eA3e9d3E3cb572F94A74b61CAd50Be");
//         relayProxy = await RelayImplementation.at("0xaF58D9A3829E3e79E69A8781F6ac2bba3f43e95C")
//       } else {
//         milkyTreasury = await MilkyTreasury.new(milkyToken.address, pair.address);
//         relayProxy = await RelayImplementation.new()

//       }
//       console.log("\n14. MilkyTreasury address: https://testnet.bscscan.com/address/" + milkyTreasury.address)

//       transaction = await milkyToken.addMinter(milkyTreasury.address)
//       console.log("\n15. milkyToken.addMinter transaction: https://testnet.bscscan.com/tx/" + transaction.tx)

//       let sMilky = await SMilky.new()
//       console.log("\n16. SMilky address: https://testnet.bscscan.com/address/" + sMilky.address)

//       let epochLengthRebase;
//       let firstRebaseBlock;
//       let bondTerm;
//       if (CHAINID == 97) {
//         epochLengthRebase = 10
//         firstRebaseBlock = await web3.eth.getBlockNumber();
//         bondTerm = 144000;
//       } else {
//         epochLengthRebase = 2
//         firstRebaseBlock = 3;
//         bondTerm = 500;
//       }


//       let milkyStaking = await MilkyStaking.new(milkyToken.address, sMilky.address, epochLengthRebase, 0, firstRebaseBlock, 2270, milkyTreasury.address)
//       console.log("\n17. milkyStaking address: https://testnet.bscscan.com/address/" + milkyStaking.address)

//       transaction = await sMilky.initialize(milkyStaking.address);
//       console.log("\n18. sMilky initialize transaction: https://testnet.bscscan.com/address/" + transaction.tx)

//       transaction = await sMilky.setIndex(7675210820);
//       console.log("\n18. sMilky initialize transaction: https://testnet.bscscan.com/address/" + transaction.tx)

//       let bondMilkyBNB = await BondMilkyBNB.new(milkyToken.address, wETH9.address, calculator.address, milkyTreasury.address, governance, milkyStaking.address);
//       console.log("\n19. BondMilkyBNB transaction: https://testnet.bscscan.com/address/" + bondMilkyBNB.address)

//       transaction = await milkyStaking.setDepositor(bondMilkyBNB.address, true);
//       console.log("\n20. milkyStaking setDepositor transaction: https://testnet.bscscan.com/address/" + bondMilkyBNB.address)

//       transaction = await milkyTreasury.setDepositor(bondMilkyBNB.address, true);
//       console.log("\n21. milkyTreasury setDepositor  transaction: https://testnet.bscscan.com/tx/" + transaction.tx)

//       transaction = await milkyTreasury.setDepositToken(wETH9.address, true);
//       console.log("\n21. milkyTreasury setDepositor  transaction: https://testnet.bscscan.com/tx/" + transaction.tx)


//       transaction = await milkyTreasury.setIsRewardManager(milkyStaking.address, true);
//       console.log("\n21. milkyTreasury setDepositor  transaction: https://testnet.bscscan.com/tx/" + transaction.tx)


//       transaction = await bondMilkyBNB.initializeBondTerms(11000, bondTerm, 300, 1000)
//       console.log("\n22. initializeBondTerms transaction: https://testnet.bscscan.com/tx/" + transaction.tx)


//       transaction = await pair.approve(bondMilkyBNB.address, web3.utils.toWei("1000000000"));
//       console.log("\n24. pair approve transaction: https://testnet.bscscan.com/tx/" + transaction.tx)


//       let nonce = await bondMilkyBNB.nonces(governance);
//       let sign = getSignature(
//         CHAINID,
//         "MilkyBondingBNB",
//         bondMilkyBNB.address,
//         "Data",
//         {
//           depositor: governance,
//           nonce,
//         },
//         {
//           Data: [
//             {name: "depositor", type: "address"},
//             {name: "nonce", type: "uint256"},
//           ],
//         },
//         Buffer.from(addressPrivatekey[governance.toLowerCase()], "hex")
//       );

//       transaction = await relayProxy.execute(bondMilkyBNB.address,
//         web3.eth.abi.encodeFunctionCall( {
//           "inputs": [
//             {
//               "internalType": "address",
//               "name": "_depositor",
//               "type": "address"
//             },
//             {
//               "internalType": "address",
//               "name": "sender",
//               "type": "address"
//             },
//             {
//               "internalType": "uint8",
//               "name": "v",
//               "type": "uint8"
//             },
//             {
//               "internalType": "bytes32",
//               "name": "r",
//               "type": "bytes32"
//             },
//             {
//               "internalType": "bytes32",
//               "name": "s",
//               "type": "bytes32"
//             }
//           ],
//           "name": "depositPermit",
//           "outputs": [
//             {
//               "internalType": "uint256",
//               "name": "",
//               "type": "uint256"
//             }
//           ],
//           "stateMutability": "payable",
//           "type": "function"
//         }, [
//           governance,
//           governance,
//           sign.v,
//           sign.r,
//           sign.s
//         ]),
//         {
//           from: governance,
//           value: 100
//         }
//       )


//       // transaction = await bondMilkyBNB.deposit( governance,{value: 1000});
//       console.log("\n25. bondMilkyBNB deposit transaction: https://testnet.bscscan.com/tx/" + transaction.tx)

//       transaction = await bondMilkyBNB.redeem(governance, false)
//       console.log("\n26. bondMilkyBNB redeem transaction: https://testnet.bscscan.com/tx/" + transaction.tx)

//       transaction = await bondMilkyBNB.redeem(governance, true)
//       console.log("\n27. bondMilkyBNB redeem transaction: https://testnet.bscscan.com/tx/" + transaction.tx)

//       transaction = await bondMilkyBNB.redeem(governance, false)
//       console.log("\n28. bondMilkyBNB redeem transaction: https://testnet.bscscan.com/tx/" + transaction.tx)

//       transaction = await bondMilkyBNB.redeem(governance, false)
//       console.log("\n29. bondMilkyBNB redeem transaction: https://testnet.bscscan.com/tx/" + transaction.tx)

//       transaction = await bondMilkyBNB.redeem(governance, true)
//       console.log("\n30. bondMilkyBNB redeem transaction: https://testnet.bscscan.com/tx/" + transaction.tx)

//       transaction = await sMilky.approve(milkyStaking.address, web3.utils.toWei("10000000"))
//       console.log("\n31. sMilky approve transaction: https://testnet.bscscan.com/tx/" + transaction.tx)

//       // transaction = await milkyStaking.unstake(1, false)
//       // console.log("\n32. milkyStaking unstake transaction: https://testnet.bscscan.com/tx/" + transaction.tx)

//       transaction = await milkyStaking.unstakeAll(true)
//       console.log("\n32. milkyStaking unstakeAll transaction: https://testnet.bscscan.com/tx/" + transaction.tx)


//       console.log("npx hardhat verify", milkyToken.address, "500", account4, "--network bnb");
//       console.log("npx hardhat verify", calculator.address, "--network bnb");
//       console.log("npx hardhat verify", milkyTreasury.address, milkyToken.address, pair.address, "--network bnb");
//       console.log("npx hardhat verify", sMilky.address, "--network bnb");
//       console.log("npx hardhat verify", milkyStaking.address, milkyToken.address, sMilky.address, epochLengthRebase, 0, firstRebaseBlock, 2270, milkyTreasury.address, "--network bnb");
//       console.log("npx hardhat verify", bondMilkyBNB.address, milkyToken.address, pair.address, calculator.address, milkyTreasury.address, governance, milkyStaking.address, "--network bnb");


//     }).timeout(40000000000);

//   });
// });
