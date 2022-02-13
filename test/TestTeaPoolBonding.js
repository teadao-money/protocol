const Web3 = require("web3");
const web3 = new Web3("https://data-seed-prebsc-1-s1.binance.org:8545/");
const TeaToken = artifacts.require("TeaToken");
const PancakeFactory = artifacts.require("PancakeFactory");
const PancakePair = artifacts.require("PancakePair");
const WETH9 = artifacts.require("WETH");
const BondingCalculator = artifacts.require("contracts/poolBonding/TeaPriceFeed.sol:PriceFeed");
const DAI = artifacts.require("DAI");
const TeaBond = artifacts.require("TeaBond");
const TeaPool = artifacts.require("TeaPool");
const TeaPoolFactory = artifacts.require("TeaPoolFactory");
const TeaPriceFeedNFT = artifacts.require("contracts/poolBonding/TeaPriceFeedNFT.sol:TeaPriceFeedNFT");
const TeaNFT721 = artifacts.require("TeaNFT721");
const TeaBondNFT721 = artifacts.require("TeaBondNFT721");
const TeaTreasury = artifacts.require("contracts/poolBonding/TeaTreasury.sol:TeaTreasury");
const TeaStaking = artifacts.require("contracts/poolBonding/TeaStaking.sol:TeaStaking");
const STea = artifacts.require("sTea");
const fs = require("fs");
const HDWalletProvider = require("@truffle/hdwallet-provider");
const mnemonic = fs.readFileSync("./.secret").toString().trim();
const listWallets = new HDWalletProvider(mnemonic, "https://kovan.infura.io/v3/8d62942fd62641a7ab758673105b6df3").wallets;
let addressPrivatekey = {};

Object.entries(listWallets).forEach((item, index) => {
  addressPrivatekey[item[0]] = item[1].privateKey.toString("hex");
});


contract("TeaToken\n", function(accounts) {
  let governance = accounts[0];
  let account1 = accounts[1];
  let account2 = accounts[2];
  let account3 = accounts[3];
  let account4 = accounts[4];
  let account5 = accounts[5];
  let transaction;
  let pancakeFactory;
  let wETH9;
  let pancakeRouter;

  let controlVariable = 11000;
  let vestingTerm = 500;
  let minimumPrice = 26000;
  let maxPayout = 300;
  let fee = 1000;


// Initial mint for Frax and DAI (10,000,000)
  const initialMint = "100000000000000000000000000";
  describe("Test full flow\n", function() {

    it("Test", async function() {
      pancakeFactory = await PancakeFactory.new(governance, { from: governance });
      let CHAINID = pancakeFactory.constructor.network_id;
      console.log(CHAINID == 97);
      console.log("\n1. create pancakeFactory bsc contract: https://testnet.bscscan.com/address/" + pancakeFactory.address);

      wETH9 = await WETH9.new({ from: governance });
      console.log("\n2. create WETH9 bsc token contract: https://testnet.bscscan.com/address/" + wETH9.address);

      let daiToken = await DAI.new(0);
      await daiToken.mint(governance, initialMint);
      console.log("\n2. create daiToken bsc token contract: https://testnet.bscscan.com/address/" + daiToken.address);


      let teaToken = await TeaToken.new(500, account4);
      console.log("\n4. create TeaToken contract: https://testnet.bscscan.com/address/" + teaToken.address);

      transaction = await pancakeFactory.createPair(teaToken.address, wETH9.address);
      console.log("\n8.  create pair transaction: https://testnet.bscscan.com/tx/" + transaction.tx);

      let pool = await pancakeFactory.getPair(teaToken.address, wETH9.address);
      let pair = await PancakePair.at(pool);

      transaction = await teaToken.setIsCharged(pool, true);
      console.log("\n9. TeaToken setAddressPair transaction: https://testnet.bscscan.com/tx/" + transaction.tx);

      let calculator = await BondingCalculator.new();
      console.log("\n13. BondingCalculator transaction: https://testnet.bscscan.com/address/" + calculator.address);

      let teaTreasury;
      if (CHAINID === 97) {
        teaTreasury = await TeaTreasury.at("0x297c0337f8eA3e9d3E3cb572F94A74b61CAd50Be");
      } else {
        teaTreasury = await TeaTreasury.new(teaToken.address, pair.address);

      }
      console.log("\n14. teaTreasury address: https://testnet.bscscan.com/address/" + teaTreasury.address);

      transaction = await teaToken.addMinter(teaTreasury.address);
      console.log("\n15. TeaToken.addMinter transaction: https://testnet.bscscan.com/tx/" + transaction.tx);

      let sTea = await STea.new();
      console.log("\n16. STea address: https://testnet.bscscan.com/address/" + sTea.address);

      let epochLengthRebase;
      let firstRebaseBlock;
      let bondTerm;
      if (CHAINID == 97) {
        epochLengthRebase = 10;
        firstRebaseBlock = await web3.eth.getBlockNumber();
        bondTerm = 144000;
      } else {
        epochLengthRebase = 2;
        firstRebaseBlock = 3;
        bondTerm = 500;
      }

      let teaStaking = await TeaStaking.new(teaToken.address, sTea.address, epochLengthRebase, 0, firstRebaseBlock, 2270, teaTreasury.address);
      console.log("\n17. TeaStaking address: https://testnet.bscscan.com/address/" + teaStaking.address);

      transaction = await sTea.initialize(teaStaking.address);
      console.log("\n18. STea initialize transaction: https://testnet.bscscan.com/address/" + transaction.tx);

      transaction = await sTea.setIndex(7675210820);
      console.log("\n18. STea initialize transaction: https://testnet.bscscan.com/address/" + transaction.tx);

      let teaPoolFactory = await TeaPoolFactory.new(teaTreasury.address, teaToken.address, calculator.address, teaStaking.address);
      console.log(`19. teaPoolFactory ${teaPoolFactory.address}`);

      transaction = await teaTreasury.setIsRewardManager(teaStaking.address, true);
      console.log("\n21. teaTreasury setDepositor  transaction: https://testnet.bscscan.com/tx/" + transaction.tx);

      transaction = await teaTreasury.setDepositToken(wETH9.address, true);
      transaction = await teaTreasury.setDepositToken(daiToken.address, true);
      console.log("\n21. teaTreasury setDepositor  transaction: https://testnet.bscscan.com/tx/" + transaction.tx);

      transaction = await teaPoolFactory.setTokenBond(daiToken.address, true);
      console.log(`19. transaction teaPoolFactory.setTokenBond ${transaction.tx}`);

      transaction = await teaTreasury.addIsSetter(teaPoolFactory.address, true);
      console.log("\n20. transaction teaTreasury addIsSetter transaction: https://testnet.bscscan.com/address/" + transaction.tx);

      transaction = await teaPoolFactory.createPool(governance, daiToken.address, governance, controlVariable, vestingTerm, maxPayout, fee);
      console.log(`20. transaction teaPoolFactory.createPool ${transaction.tx}`);

      let poolNew = await teaPoolFactory.listPools(0);
      poolNew = await TeaPool.at(poolNew);
      console.log(`21. pool new  ${poolNew.address}`);

      let daiBond = await poolNew.bond();
      daiBond = await TeaBond.at(daiBond);
      console.log(`22. daiBond  ${daiBond.address}`);

      transaction = await daiToken.approve(poolNew.address, web3.utils.toWei("10000000000000000"));
      console.log("\n23. daiToken approve transaction: https://testnet.bscscan.com/tx/" + transaction.tx);

      transaction = await poolNew.addLiquidity(web3.utils.toWei("1"));
      console.log("\n24. transaction daiBond.deposit transaction: https://testnet.bscscan.com/tx/" + transaction.tx);

      transaction = await poolNew.redeem();
      console.log("\n25. poolNew redeem transaction: https://testnet.bscscan.com/tx/" + transaction.tx);

      let nft721 = await TeaNFT721.new();
      console.log(`26. nft 721 ${nft721.address}`);

      transaction = await nft721.mint(governance);
      console.log(`27. transaction nft721 mint ${transaction.tx}`);

      let teaPriceFeedNFT = await TeaPriceFeedNFT.new();
      console.log(`28. teaPriceFeedNFT ${teaPriceFeedNFT.address}`);

      let teaBondNFT721 = await TeaBondNFT721.new(teaToken.address, nft721.address, teaPriceFeedNFT.address, poolNew.address, governance);
      console.log(`29. teaBondNFT721 ${teaBondNFT721.address}`);

      transaction = await teaBondNFT721.initializeBondTerms(controlVariable, vestingTerm, maxPayout, fee);
      console.log(`30. transaction teaBondNFT721.initializeBondTerms ${transaction.tx}`);

      transaction = await nft721.setApprovalForAll(teaBondNFT721.address, true);
      console.log(`31. transaction nft721.setApprovalForAll ${transaction.tx}`);

      transaction = await teaPriceFeedNFT.setSupportNFT(nft721.address, true);
      console.log(`32. transaction teaPriceFeedNFT.setSupportNFT ${transaction.tx}`);

      transaction = await teaBondNFT721.deposit(governance, [1]);
      console.log(`33. transaction teaBondNFT721.deposit ${transaction.tx}`);

      let reqId = transaction.logs[0].args.reqId;
      console.log(`34 reqId ${reqId}`);

      transaction = await poolNew.setBond721(teaBondNFT721.address, true);
      console.log(`35 transaction poolNew.setBond721 ${transaction.tx}`);

      transaction = await teaPriceFeedNFT.fulfillPrice(reqId, [web3.utils.toWei("0.1")]);
      console.log(`36 transaction teaPriceFeedNFT.fulfillPrice ${transaction.tx}`);

      let reqData  = await teaPriceFeedNFT.reqIdDatas(reqId)
      console.log(JSON.stringify(reqData));
    }).timeout(40000000000);

  });
});
