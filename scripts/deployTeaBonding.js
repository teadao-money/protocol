const { ethers } = require("hardhat");
const Web3 = require("web3");
const web3 = new Web3("https://data-seed-prebsc-1-s1.binance.org:8545");

async function main() {
  const [deployer, MockDAO] = await ethers.getSigners();

  console.log("Deploying contracts with the account: " + deployer.address);

  // Initial staking index
  const initialIndex = "7675210820";

  // First block epoch occurs
  const firstEpochBlock = await web3.eth.getBlockNumber();

  // What epoch will be first epoch
  const firstEpochNumber = "338";

  // How many blocks are in each epoch
  const epochLengthInBlocks = "600";

  // Initial reward rate for epoch
  const initialRewardRate = "3000";

  // Ethereum 0 address, used when toggling changes in treasury
  const zeroAddress = "0x0000000000000000000000000000000000000000";

  // Large number for approval for Frax and DAI
  const largeApproval = "100000000000000000000000000000000";

  // Initial mint for Frax and DAI (10,000,000)
  const initialMint = "100000000000000000000000000";

  // DAI bond BCV
  const daiBondBCV = "300";

  // Bond vesting length in blocks. 33110 ~ 5 days
  const bondVestingLength = "144000";

  // Min bond price
  const minBondPrice = "26000";

  // Max bond payout
  const maxBondPayout = "20";

  // DAO fee for bond
  const bondFee = "500";

  // Max debt bond can take on
  const maxBondDebt = "1000000000000000";

  // Initial Bond debt
  const intialBondDebt = "130066000000000";

  // Deploy TEA
  const TEA = await ethers.getContractFactory("TeaERC20Token");
  const tea = await TEA.deploy();

  // Deploy DAI
  const DAI = await ethers.getContractFactory("DAI");
  const dai = await DAI.deploy(0);

  // Deploy 10,000,000 mock DAI and mock Frax
  await dai.mint(deployer.address, initialMint);

  // Deploy treasury
  //@dev changed function in treaury from 'valueOf' to 'valueOfToken'... solidity function was coflicting w js object property name
  const Treasury = await ethers.getContractFactory(
    "contracts/TeaBonding/Treasury.sol:TeaTreasury"
  );
  const treasury = await Treasury.deploy(
    tea.address,
    dai.address,
    dai.address,
    0
  );

  // Deploy bonding calc
  const TeaBondingCalculator = await ethers.getContractFactory(
    "TeaBondingCalculator"
  );
  const olympusBondingCalculator = await TeaBondingCalculator.deploy(
    tea.address
  );

  // Deploy staking distributor
  const Distributor = await ethers.getContractFactory("Distributor");
  const distributor = await Distributor.deploy(
    treasury.address,
    tea.address,
    epochLengthInBlocks,
    firstEpochBlock
  );

  // Deploy sTEA
  const STEA = await ethers.getContractFactory("sTea");
  const sTEA = await STEA.deploy();

  // Deploy Staking
  const Staking = await ethers.getContractFactory(
    "contracts/TeaBonding/Staking.sol:TeaStaking"
  );
  const staking = await Staking.deploy(
    tea.address,
    sTEA.address,
    epochLengthInBlocks,
    firstEpochNumber,
    firstEpochBlock
  );

  // Deploy staking warmpup
  const StakingWarmpup = await ethers.getContractFactory("StakingWarmup");
  const stakingWarmup = await StakingWarmpup.deploy(
    staking.address,
    sTEA.address
  );

  // Deploy staking helper
  const StakingHelper = await ethers.getContractFactory("StakingHelper");
  const stakingHelper = await StakingHelper.deploy(
    staking.address,
    tea.address
  );

  // Deploy DAI bond
  //@dev changed function call to Treasury of 'valueOf' to 'valueOfToken' in BondDepository due to change in Treausry contract
  const DAIBond = await ethers.getContractFactory("TeaBondDepository");
  const daiBond = await DAIBond.deploy(
    tea.address,
    dai.address,
    treasury.address,
    MockDAO.address,
    zeroAddress
  );

  // queue and toggle DAI and Frax bond reserve depositor
  await treasury.queue("0", daiBond.address);
  await treasury.toggle("0", daiBond.address, zeroAddress);

  // Set DAI and Frax bond terms
  await daiBond.initializeBondTerms(
    daiBondBCV,
    bondVestingLength,
    minBondPrice,
    maxBondPayout,
    bondFee,
    maxBondDebt,
    intialBondDebt
  );
  await daiBond.setAdjustment(true, 3, 13900, 300);

  // Set staking for DAI and Frax bond
  await daiBond.setStaking(stakingHelper.address, true);

  // Initialize sTEA and set the index
  await sTEA.initialize(staking.address);
  await sTEA.setIndex(initialIndex);

  // set distributor contract and warmup contract
  await staking.setContract("0", distributor.address);
  await staking.setContract("1", stakingWarmup.address);

  // Set treasury for TEA token
  await tea.setVault(treasury.address);

  // Add staking contract as distributor recipient
  await distributor.addRecipient(staking.address, initialRewardRate);

  // queue and toggle reward manager
  await treasury.queue("8", distributor.address);
  await treasury.toggle("8", distributor.address, zeroAddress);

  // queue and toggle deployer reserve depositor
  await treasury.queue("0", deployer.address);
  await treasury.toggle("0", deployer.address, zeroAddress);

  // queue and toggle liquidity depositor
  await treasury.queue("4", deployer.address);
  await treasury.toggle("4", deployer.address, zeroAddress);

  // Approve the treasury to spend DAI and Frax
  await dai.approve(treasury.address, largeApproval);

  await dai.approve(daiBond.address, largeApproval);

  // Approve staking and staking helper contact to spend deployer's TEA
  await tea.approve(staking.address, largeApproval);
  await tea.approve(stakingHelper.address, largeApproval);

  // Deposit 9,000,000 DAI to treasury, 600,000 TEA gets minted to deployer and 8,400,000 are in treasury as excesss reserves
  // https://etherscan.io/tx/0xf488c488a0b243eed720ebd4531c439caaa1abfd98c9a3407719100d755f97c9
  await treasury.deposit(web3.utils.toWei("150000"), dai.address, 0);

  await daiBond.deposit(web3.utils.toWei("6000"), "60000", deployer.address);

  const PancakeFactory = await ethers.getContractFactory("PancakeFactory");
  const pancakeFactory = await PancakeFactory.deploy(deployer.address);

  const PancakeRouter = await ethers.getContractFactory("PancakeRouter");
  const pancakeRouter = await PancakeRouter.attach(
    "0x3684bbC718cD82598f5B7993d6FF42B6cc4B15c8"
  );

  await tea.approve(pancakeRouter.address, web3.utils.toWei("100000", "ether"));
  await dai.approve(
    pancakeRouter.address,
    web3.utils.toWei("20000000000", "ether")
  );

  // Stake TEA through helper
  await stakingHelper.stake("100000000000", deployer.address);

  // https://etherscan.io/tx/0xc6fb5a5210955cca6080cb412327bfcdc9931f1121293954d0702ba9a22c1527
  // https://etherscan.io/tx/0x4613a1452e261476e360c993b85f7a76d6eb096abe92b4ba7114b60c58d097b5
  await pancakeRouter.addLiquidity(
    tea.address,
    dai.address,
    web3.utils.toWei("8000", "gwei"),
    web3.utils.toWei("2400000", "ether"),
    0,
    0,
    deployer.address,
    10000000000000
  );

  const pairAddress = await pancakeFactory.getPair(tea.address, dai.address);
  console.log("TEA: " + tea.address);
  console.log("DAI: " + dai.address);
  console.log("Treasury: " + treasury.address);
  console.log("Calc: " + olympusBondingCalculator.address);
  console.log("Staking: " + staking.address);
  console.log("sTEA: " + sTEA.address);
  console.log("Distributor " + distributor.address);
  console.log("Staking Wawrmup " + stakingWarmup.address);
  console.log("Staking Helper " + stakingHelper.address);
  console.log("DAI Bond: " + daiBond.address);
  console.log("Pancake factory: " + pancakeFactory.address);
  console.log("Pancake router: " + pancakeRouter.address);
  console.log("DAI/TEA: " + pairAddress);

  try {
    await run("verify:verify", {
      address: daiBond.address,
      constructorArguments: [
        tea.address,
        dai.address,
        treasury.address,
        MockDAO.address,
        zeroAddress,
      ],
    });
  } catch (e) {
    console.log(e);
  }

  try {
    await run("verify:verify", {
      address: tea.address,
      constructorArguments: [],
    });
  } catch (e) {}

  try {
    await run("verify:verify", {
      address: dai.address,
      constructorArguments: [0],
    });
  } catch (e) {}
  try {
    await run("verify:verify", {
      address: frax.address,
      constructorArguments: [0],
    });
  } catch (e) {}
  try {
    await run("verify:verify", {
      address: treasury.address,
      constructorArguments: [tea.address, dai.address, dai.address, 0],
    });
  } catch (e) {}
  try {
    await run("verify:verify", {
      address: olympusBondingCalculator.address,
      constructorArguments: [tea.address],
    });
  } catch (e) {
    console.log(e);
  }
  try {
    await run("verify:verify", {
      address: staking.address,
      constructorArguments: [
        tea.address,
        sTEA.address,
        epochLengthInBlocks,
        firstEpochNumber,
        firstEpochBlock,
      ],
    });
  } catch (e) {
    console.log(e);
  }
  try {
    await run("verify:verify", {
      address: sTEA.address,
      constructorArguments: [],
    });
  } catch (e) {
    console.log(e);
  }
  try {
    await run("verify:verify", {
      address: distributor.address,
      constructorArguments: [
        treasury.address,
        tea.address,
        epochLengthInBlocks,
        firstEpochBlock,
      ],
    });
  } catch (e) {
    console.log(e);
  }
  try {
    await run("verify:verify", {
      address: stakingWarmup.address,
      constructorArguments: [staking.address, sTEA.address],
    });
  } catch (e) {
    console.log(e);
  }
  try {
    await run("verify:verify", {
      address: stakingHelper.address,
      constructorArguments: [staking.address, tea.address],
    });
  } catch (e) {
    console.log(e);
  }
}

main()
  .then(() => process.exit())
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
