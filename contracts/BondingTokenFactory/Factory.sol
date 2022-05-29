// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;


interface IProxy {
    function masterCopy() external view returns (address);
}

contract Proxy {
    address internal singleton;

    /// @dev Constructor function sets address of singleton contract.
    /// @param _singleton Singleton address.
    constructor(address _singleton) {
        require(_singleton != address(0), "Invalid singleton address provided");
        singleton = _singleton;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    fallback() external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let _singleton := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
        // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, _singleton)
                return (0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return (0, returndatasize())
        }
    }
}

interface ITreasure {
    function initialize(address withdrawAsset, address depositAsset, address _owner, address _depositToken, address _depositor, address _rewardManager) external;
}

interface IStaking {
    function initialize(address _MILKY, address _sMILKY, uint _epochLength, uint _firstEpochNumber, uint _firstEpochBlock, uint256 _rateReward, address _treasury, address __owner)
    external;
}

interface ISToken {
    function initialize(address stakingContract_, address __owner, string calldata name, uint8 dec, uint256 totalSup) external returns (bool);
}

interface IBonding {
    function initialize(address _paymentToken, address _principle, address _principlePriceFeed, address _paymentTokenPriceFeed, address _treasury, address _dao, address _staking, address __owner, uint _controlVariable, uint _vestingTerm, uint _maxPayout, uint _fee) external;
}

interface IBEP20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);
}

contract Ownable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    function initializeOwnable(address __owner) internal {
        _owner = __owner;
        emit OwnershipPushed(address(0), __owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwner() public onlyOwner() {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushOwner(address newOwner_) public onlyOwner() {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullOwner() public {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

contract BondingFactory is Ownable {
    struct ListAddress {
        address owner;
        address depositAsset;
        address withdrawAsset;
        address staking;
        address bonding;
        address sToken;
        address treasury;
    }

    struct BondCreatingData {
        // deposit token
        address depositAsset;
        // withdraw token
        address withdrawAsset;
        // price feed to calculate data
        address depositTokenPriceFeed;
        address withdrawTokenPriceFeed;
        // the place own bonding fee
        address dao;
        address owner;
        // totalSup init of sToken (not mul vs 10**dec)
        uint256 totalSup;
        // staking  reward each 8 hours(div 10**6)
        uint256 rate;
        // the discount when bonding (10000 = not discount)
        uint256 discount;
        // vesting block number of bonding
        uint256 bondingTime;
        // maxPayout can buy each bonding time totalSup * maxPayout / 100000
        uint256 maxPayout;
        // bonding fee amount*fee/10000
        uint256 bondingFee;
        // bonding with bnb or bep20
        BondingType _bondingType;
    }

    event BondCreated(address indexed sender, address indexed depositAddress, address indexed withdrawAddress, address staking, address sToken, address bonding, address treasury);
    enum SetContractType{BEP20_BONDING, NATIVE_BONDING, STAKING, STOKEN, TREASURY}
    enum BondingType{BEP20, NATIVE}

    address public bondingBEP20Implement;
    address public bondingNativeImplement;
    address public stakingImplement;
    address public sTokenImplement;
    address public treasuryImplement;
    ListAddress[] public listBonding;

    constructor(address _bondingBEP20Implement, address _bondingNativeImplement, address _stakingImplement, address _sTokenImplement, address _treasuryImplement) public {
        bondingBEP20Implement = _bondingBEP20Implement;
        bondingNativeImplement = _bondingNativeImplement;
        stakingImplement = _stakingImplement;
        sTokenImplement = _sTokenImplement;
        treasuryImplement = _treasuryImplement;
    }

    function listBondingLength() public view returns (uint256){
        return listBonding.length;
    }

    function setAddress(SetContractType _type, address _address) external onlyOwner {
        if (_type == SetContractType.BEP20_BONDING) {
            bondingBEP20Implement = _address;
        } else if (_type == SetContractType.NATIVE_BONDING) {
            bondingNativeImplement = _address;
        } else if (_type == SetContractType.STAKING) {
            stakingImplement = _address;
        } else if (_type == SetContractType.STOKEN) {
            sTokenImplement = _address;
        } else if (_type == SetContractType.TREASURY) {
            treasuryImplement = _address;
        }
    }

    function createBonding(BondCreatingData memory data) public returns (address, address, address, address) {
        address treasury = address(new Proxy(treasuryImplement));
        address sToken = address(new Proxy(sTokenImplement));
        address staking = address(new Proxy(stakingImplement));
        address bonding;
        if (data._bondingType == BondingType.BEP20) {
            bonding = address(new Proxy(bondingBEP20Implement));
        } else {
            bonding = address(new Proxy(bondingNativeImplement));
        }

        ListAddress  memory listContract = ListAddress(
            data.owner,
            data.depositAsset,
            data.withdrawAsset,
            staking,
            bonding,
            sToken,
            treasury
        );

        initializeStaking(data, listContract);
        initializeSToken(data, listContract);
        initializeBonding(data, listContract);
        initializeTreasury(data, listContract);
        emit BondCreated(data.owner, data.depositAsset, data.withdrawAsset, staking, sToken, bonding, treasury);
        listBonding.push(listContract);
        return (staking, sToken, bonding, treasury);

    }

    function initializeStaking(BondCreatingData memory data, ListAddress memory listContract) private {
        // force rebase each 8 hours
        IStaking(listContract.staking).initialize(
            data.withdrawAsset,
            listContract.sToken,
            9600,
            0,
            block.number,
            data.rate,
            listContract.treasury,
            data.owner
        );
    }

    function initializeSToken(BondCreatingData memory data, ListAddress memory listContract) private {
        ISToken(listContract.sToken).initialize(
            listContract.staking,
            data.owner,
            IBEP20(data.withdrawAsset).name(),
            IBEP20(data.withdrawAsset).decimals(),
            data.totalSup
        );
    }

    function initializeBonding(BondCreatingData memory data, ListAddress memory listContract) private {
        IBonding(listContract.bonding).initialize(
            data.withdrawAsset,
            data.depositAsset,
            data.depositTokenPriceFeed,
            data.withdrawTokenPriceFeed,
            listContract.treasury,
            data.dao,
            listContract.staking,
            data.owner,
            data.discount,
            data.bondingTime,
            data.maxPayout,
            data.bondingFee
        );
    }

    function initializeTreasury(BondCreatingData memory data, ListAddress memory listContract) private {
        ITreasure(listContract.treasury).initialize(
            data.withdrawAsset,
            data.depositAsset,
            data.owner,
            data.depositAsset,
            listContract.bonding,
            listContract.staking
        );
    }
}
