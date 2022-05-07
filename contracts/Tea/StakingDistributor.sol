pragma solidity 0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount(uint256 total_, uint8 percentage_) internal pure returns (uint256 percentAmount_) {
        return div(mul(total_, percentage_), 1000);
    }

    function substractPercentage(uint256 total_, uint8 percentageToSub_) internal pure returns (uint256 result_) {
        return sub(total_, div(mul(total_, percentageToSub_), 1000));
    }

    function percentageOfTotal(uint256 part_, uint256 total_) internal pure returns (uint256 percent_) {
        return div(mul(part_, 100), total_);
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing(uint256 payment_, uint256 multiplier_) internal pure returns (uint256) {
        return sqrrt(mul(multiplier_, payment_));
    }

    function bondingCurve(uint256 supply_, uint256 multiplier_) internal pure returns (uint256) {
        return mul(multiplier_, supply_);
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
}

interface IPolicy {

    function policy() external view returns (address);

    function renouncePolicy() external;

    function pushPolicy(address newPolicy_) external;

    function pullPolicy() external;
}

contract Policy is IPolicy {

    address internal _policy;
    address internal _newPolicy;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _policy = msg.sender;
        emit OwnershipTransferred(address(0), _policy);
    }

    function policy() public view override returns (address) {
        return _policy;
    }

    modifier onlyPolicy() {
        require(_policy == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renouncePolicy() public virtual override onlyPolicy() {
        emit OwnershipTransferred(_policy, address(0));
        _policy = address(0);
    }

    function pushPolicy(address newPolicy_) public virtual override onlyPolicy() {
        require(newPolicy_ != address(0), "Ownable: new owner is the zero address");
        _newPolicy = newPolicy_;
    }

    function pullPolicy() public virtual override {
        require(msg.sender == _newPolicy);
        emit OwnershipTransferred(_policy, _newPolicy);
        _policy = _newPolicy;
    }
}

interface ITreasury {
    function mintRewards(address _recipient, uint _amount) external;
}

contract Distributor is Policy {
    using SafeMath for uint;
    /* ====== VARIABLES ====== */
    address public immutable TEA;
    address public immutable treasury;
    uint public immutable epochLength;
    uint public nextEpochBlock;
    mapping(uint => Adjust) public adjustments;

    /* ====== STRUCTS ====== */

    struct Info {
        uint rate; // in ten-thousandths ( 5000 = 0.5% )
        address recipient;
    }

    struct Adjust {
        bool add;
        uint rate;
        uint target;
    }


    Info[] public info;

    /* ====== CONSTRUCTOR ====== */
    constructor(address _treasury, address _tea, uint _epochLength, uint _nextEpochBlock) {
        require(_treasury != address(0));
        treasury = _treasury;
        require(_tea != address(0));
        TEA = _tea;
        epochLength = _epochLength;
        nextEpochBlock = _nextEpochBlock;
    }

    /* ====== PUBLIC FUNCTIONS ====== */

    /**
        @notice send epoch reward to staking contract
     */
    function distribute() external returns (bool) {
        if (nextEpochBlock <= block.number) {
            nextEpochBlock = nextEpochBlock.add(epochLength);
            // set next epoch block

            // distribute rewards to each recipient
            for (uint i = 0; i < info.length; i++) {
                if (info[i].rate > 0) {
                    ITreasury(treasury).mintRewards(// mint and send from treasury
                        info[i].recipient,
                        nextRewardAt(info[i].rate)
                    );
                    adjust(i);
                    // check for adjustment
                }
            }
            return true;
        } else {
            return false;
        }
    }

    /* ====== INTERNAL FUNCTIONS ====== */

    /**
        @notice increment reward rate for collector
     */
    function adjust(uint _index) internal {
        Adjust memory adjustment = adjustments[_index];
        if (adjustment.rate != 0) {
            if (adjustment.add) {// if rate should increase
                info[_index].rate = info[_index].rate.add(adjustment.rate);
                // raise rate
                if (info[_index].rate >= adjustment.target) {// if target met
                    adjustments[_index].rate = 0;
                    // turn off adjustment
                }
            } else {// if rate should decrease
                info[_index].rate = info[_index].rate.sub(adjustment.rate);
                // lower rate
                if (info[_index].rate <= adjustment.target) {// if target met
                    adjustments[_index].rate = 0;
                    // turn off adjustment
                }
            }
        }
    }

    /* ====== VIEW FUNCTIONS ====== */

    /**
        @notice view function for next reward at given rate
        @param _rate uint
        @return uint
     */
    function nextRewardAt(uint _rate) public view returns (uint) {
        return IERC20(TEA).totalSupply().mul(_rate).div(1000000);
    }

    /**
        @notice view function for next reward for specified address
        @param _recipient address
        @return uint
     */
    function nextRewardFor(address _recipient) public view returns (uint) {
        uint reward;
        for (uint i = 0; i < info.length; i++) {
            if (info[i].recipient == _recipient) {
                reward = nextRewardAt(info[i].rate);
            }
        }
        return reward;
    }

    /* ====== POLICY FUNCTIONS ====== */

    /**
        @notice adds recipient for distributions
        @param _recipient address
        @param _rewardRate uint
     */
    function addRecipient(address _recipient, uint _rewardRate) external onlyPolicy() {
        require(_recipient != address(0));
        info.push(Info({
        recipient : _recipient,
        rate : _rewardRate
        }));
    }

    /**
        @notice removes recipient for distributions
        @param _index uint
        @param _recipient address
     */
    function removeRecipient(uint _index, address _recipient) external onlyPolicy() {
        require(_recipient == info[_index].recipient);
        info[_index].recipient = address(0);
        info[_index].rate = 0;
    }

    /**
        @notice set adjustment info for a collector's reward rate
        @param _index uint
        @param _add bool
        @param _rate uint
        @param _target uint
     */
    function setAdjustment(uint _index, bool _add, uint _rate, uint _target) external onlyPolicy() {
        adjustments[_index] = Adjust({
        add : _add,
        rate : _rate,
        target : _target
        });
    }
}
