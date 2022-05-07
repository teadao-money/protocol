const {ethers} = require("hardhat");
const Web3 = require("web3");
const web3 = new Web3("https://data-seed-prebsc-1-s1.binance.org:8545");


async function main() {

    const largeApproval = "100000000000000000000000000000000";
    const [deployer, MockDAO] = await ethers.getSigners();

    // Deploy TEA
    const TEA = await ethers.getContractFactory("TeaERC20Token");
    const tea = await TEA.deploy();
    console.log("1. tea address at https://testnet.bscscan.com/address/" + tea.address);

    // Deploy DAI
    const DAI = await ethers.getContractFactory("DAI");
    const dai = await DAI.deploy(0);
    console.log("2. dai address at https://testnet.bscscan.com/address/" + dai.address);


    // Deploy 10,000,000 mock DAI and mock Frax
    await dai.mint(deployer.address, "100000000000000000000000000");

    const TreasuryImplement = await ethers.getContractFactory("TreasuryImplement");
    const teaTreasuryImplement = await TreasuryImplement.deploy();
    console.log("3. teaTreasuryImplement address at https://testnet.bscscan.com/address/" + teaTreasuryImplement.address);


    const StakingImplement = await ethers.getContractFactory("StakingImplement");
    const teaStakingImplement = await StakingImplement.deploy();
    console.log("4. teaStakingImplement address at https://testnet.bscscan.com/address/" + teaStakingImplement.address);


    const sImplement = await ethers.getContractFactory("sTokenImplement");
    const steaImplement = await sImplement.deploy();
    console.log("5. steaImplement address at https://testnet.bscscan.com/address/" + steaImplement.address);

    const BondBEPImplement = await ethers.getContractFactory("BondBEPImplement");
    const bondBEPImplement = await BondBEPImplement.deploy();
    console.log("6. bondBEPImplement address at https://testnet.bscscan.com/address/" + bondBEPImplement.address);

    const BondBNBImplement = await ethers.getContractFactory("BondBNBImplement");
    const bondBNBImplement = await BondBNBImplement.deploy();
    console.log("7. bondBNBImplement address at https://testnet.bscscan.com/address/" + bondBNBImplement.address);

    const WETH9 = await ethers.getContractFactory("WETH");
    const weth = await WETH9.deploy();
    console.log("8. weth address at https://testnet.bscscan.com/address/" + weth.address);

    const PriceFeed = await ethers.getContractFactory("contracts/bondingTokenFactory/PriceFeed.sol:PriceFeed");
    const priceFeed = await PriceFeed.deploy();
    console.log("9. priceFeed address at https://testnet.bscscan.com/address/" + priceFeed.address);

    const BondingFactory = await ethers.getContractFactory("BondingFactory");
    const bondingFactory = await BondingFactory.deploy(bondBEPImplement.address, bondBNBImplement.address, teaStakingImplement.address, steaImplement.address, teaTreasuryImplement.address);
    console.log("10. bondingFactory address at https://testnet.bscscan.com/address/" + bondingFactory.address);

    let transaction = await bondingFactory.createBonding({
        depositAsset: weth.address,
        withdrawAsset: tea.address,
        priceFeed: priceFeed.address,
        dao: deployer.address,
        owner: deployer.address,
        totalSup: 100000000,
        rate: 1100,
        discount: 11000,
        bondingTime: 144000,
        maxPayout: 1000,
        bondingFee: 100,
        _bondingType: 1,
    });
    console.log("11. Create bonding tx at https://testnet.bscscan.com/tx/" + transaction.hash);


    let receipt = await transaction.wait();
    let staking;
    let bonding;
    let sToken;
    let treasury;
    for (let event of receipt.logs) {
        if (event.topics[0] === "0x7f539e61e1af9bdd0b79071575c4d02181b0ccbe19f28836837409f8bae22dbc") {
            let listAddress = web3.eth.abi.decodeParameters(["address", "address", "address", "address"], event.data);
            staking = listAddress[0];
            sToken = listAddress[1];
            bonding = listAddress[2];
            treasury = listAddress[3];
        }
    }
    console.log("Address", staking, bonding, sToken, treasury);
    staking = teaStakingImplement.attach(staking);
    bonding = bondBNBImplement.attach(bonding);
    sToken = sImplement.attach(sToken);
    treasury = teaTreasuryImplement.attach(treasury);

    transaction = await tea.transfer(treasury.address, "10000000000000000000000000");
    console.log("12. Transfer to treasury tx at https://testnet.bscscan.com/tx/" + transaction.hash);


    transaction = await dai.approve(bonding.address, largeApproval);
    console.log("13. Approve dai to bond tx at https://testnet.bscscan.com/tx/" + transaction.hash);

    //
    // // Approve staking and staking helper contact to spend deployer's TEA
    transaction = await tea.approve(staking.address, largeApproval);
    console.log("14. Approve tea to bond tx at https://testnet.bscscan.com/tx/" + transaction.hash);

    transaction = await bonding.deposit(deployer.address, {value: ethers.utils.parseEther("0.001")});
    console.log("15. Deposit weth to bond tx at https://testnet.bscscan.com/tx/" + transaction.hash);

    await transaction.wait();
    transaction = await bonding.redeem(deployer.address, true);
    console.log("16. Redeem with stake tx at https://testnet.bscscan.com/tx/" + transaction.hash);
    await transaction.wait();
    transaction = await bonding.redeem(deployer.address, false);
    console.log("17. Redeem tx at https://testnet.bscscan.com/tx/" + transaction.hash);

    transaction = await staking.stake(web3.utils.toWei("0.0000006"), deployer.address);
    console.log("18. Staking tx at https://testnet.bscscan.com/tx/" + transaction.hash);

    transaction = await sToken.approve(staking.address, largeApproval);
    console.log("19. Approve sToken to bond tx at https://testnet.bscscan.com/tx/" + transaction.hash);

    transaction = await staking.unstakeAll(true);
    console.log("20. Unstake all tx at https://testnet.bscscan.com/tx/" + transaction.hash);


    transaction = await bondingFactory.createBonding({
        depositAsset: dai.address,
        withdrawAsset: tea.address,
        priceFeed: priceFeed.address,
        dao: deployer.address,
        owner: deployer.address,
        totalSup: 100000000,
        rate: 1100,
        discount: 11000,
        bondingTime: 144000,
        maxPayout: 1000,
        bondingFee: 100,
        _bondingType: 0,
    });
    console.log("21. Create bonding tx at https://testnet.bscscan.com/tx/" + transaction.hash);


    receipt = await transaction.wait();

    for (let event of receipt.logs) {
        if (event.topics[0] === "0x7f539e61e1af9bdd0b79071575c4d02181b0ccbe19f28836837409f8bae22dbc") {
            let listAddress = web3.eth.abi.decodeParameters(["address", "address", "address", "address"], event.data);
            staking = listAddress[0];
            sToken = listAddress[1];
            bonding = listAddress[2];
            treasury = listAddress[3];
        }
    }
    console.log("Address", staking, bonding, sToken, treasury);
    staking = teaStakingImplement.attach(staking);
    bonding = bondBEPImplement.attach(bonding);
    sToken = sImplement.attach(sToken);
    treasury = teaTreasuryImplement.attach(treasury);

    transaction = await tea.transfer(treasury.address, "10000000000000000000000000");
    console.log("22. Transfer to treasury tx at https://testnet.bscscan.com/tx/" + transaction.hash);


    transaction = await dai.approve(bonding.address, largeApproval);
    console.log("23. Approve dai to bond tx at https://testnet.bscscan.com/tx/" + transaction.hash);

    //
    // // Approve staking and staking helper contact to spend deployer's TEA
    transaction = await tea.approve(staking.address, largeApproval);
    console.log("24. Approve tea to bond tx at https://testnet.bscscan.com/tx/" + transaction.hash);

    transaction = await bonding.deposit(web3.utils.toWei("100"), deployer.address);
    console.log("25. Deposit dai to bond tx at https://testnet.bscscan.com/tx/" + transaction.hash);

    await transaction.wait();
    transaction = await bonding.redeem(deployer.address, true);
    console.log("26. Redeem with stake tx at https://testnet.bscscan.com/tx/" + transaction.hash);
    await transaction.wait();
    transaction = await bonding.redeem(deployer.address, false);
    console.log("27. Redeem tx at https://testnet.bscscan.com/tx/" + transaction.hash);

    transaction = await staking.stake(web3.utils.toWei("0.0000006"), deployer.address);
    console.log("28. Staking tx at https://testnet.bscscan.com/tx/" + transaction.hash);

    transaction = await sToken.approve(staking.address, largeApproval);
    console.log("29. Approve sToken to bond tx at https://testnet.bscscan.com/tx/" + transaction.hash);

    transaction = await staking.unstakeAll(true);
    console.log("30. Unstake all tx at https://testnet.bscscan.com/tx/" + transaction.hash);


    try {
        await run("verify:verify", {
            address: daiBond.address,
            constructorArguments: [tea.address, dai.address, treasury.address, MockDAO.address, zeroAddress],
        });
    } catch (e) {
        console.log(e);

    }

    try {
        await run("verify:verify", {
            address: tea.address,
            constructorArguments: [],
        });
    } catch (e) {
    }

    try {
        await run("verify:verify", {
            address: dai.address,
            constructorArguments: [0],
        });
    } catch (e) {
    }
    try {
        await run("verify:verify", {
            address: frax.address,
            constructorArguments: [0],
        });
    } catch (e) {
    }
    try {
        await run("verify:verify", {
            address: treasury.address,
            constructorArguments: [tea.address, dai.address, dai.address, 0],
        });
    } catch (e) {
    }
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
            constructorArguments: [tea.address, sTEA.address, epochLengthInBlocks, firstEpochNumber, firstEpochBlock],
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
            constructorArguments: [treasury.address, tea.address, epochLengthInBlocks, firstEpochBlock],
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
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
