const TeaPriceFeedNFT = artifacts.require("TeaPriceFeedNFT");
const TeaPriceFeedNFTClient = artifacts.require("TeaPriceFeedNFTClient");

const { expectRevert } = require("openzeppelin-test-helpers");
const Web3 = require("web3");
const network = "wss://kovan.infura.io/ws/v3/8d62942fd62641a7ab758673105b6df3";
const web3 = new Web3(network);
const HDWalletProvider = require("@truffle/hdwallet-provider");
const fs = require("fs");
const mnemonic = fs.readFileSync(".secret").toString().trim();
let a = new HDWalletProvider(mnemonic, `https://kovan.infura.io/v3/8d62942fd62641a7ab758673105b6df3`);

contract("tea price feeds", function(accounts) {
  let governance = accounts[0];

  describe("price feeds", function() {
      // it("1", async function() {
      //
      //   let teaPriceFeedNFT = await TeaPriceFeedNFT.new();
      //   console.log("1. teaPriceFeedNFT", teaPriceFeedNFT.address);
      //
      //   let teaPriceFeedNFTClient = await TeaPriceFeedNFTClient.new(teaPriceFeedNFT.address);
      //   console.log("2. teaPriceFeedNFTClient", teaPriceFeedNFTClient.address);
      //
      //   let transaction = await teaPriceFeedNFT.setSupportCollection("0x2f2a88c990a072061563923b0229c2514e5df82e806eceaabc961eb7203fde85", true);
      //   console.log("3. transaction teaPriceFeedNFT.setSupportCollection", transaction.tx);
      //
      //   transaction = await teaPriceFeedNFTClient.randomnessRequest("231234", "0x2f2a88c990a072061563923b0229c2514e5df82e806eceaabc961eb7203fde85");
      //   console.log("4. teaPriceFeedNFTClient.randomnessRequest", transaction.tx);
      //
      // }).timeout(40000000000);

      it("2", async function() {

        let teaPriceFeedNFT = await TeaPriceFeedNFT.at("0x12c602FbCc91Ac7Fa45Aa3883B64b0641463AAFe");
        console.log("1. teaPriceFeedNFT", teaPriceFeedNFT.address);

        let teaPriceFeedNFTClient = await TeaPriceFeedNFTClient.at("0x51eb4a5Fd87f44592a7757d9922edE2E962AFe32");
        console.log("2. teaPriceFeedNFTClient", teaPriceFeedNFTClient.address);

        transaction = await teaPriceFeedNFTClient.randomnessRequest("231234", "0x2f2a88c990a072061563923b0229c2514e5df82e806eceaabc961eb7203fde85");
        console.log("3. teaPriceFeedNFTClient.randomnessRequest", transaction.tx);

      }).timeout(40000000000);


    }
  );

});
