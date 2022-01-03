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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        assert(a == b * c + a % b);
        // There is no case in which this doesn't hold

        return c;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeBEP20 {
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwner() external;

    function pushOwner(address newOwner_) external;

    function pullOwner() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    function initializeOwnable(address __owner) internal {
        _owner = __owner;
        emit OwnershipPushed(address(0), __owner);
    }

    function owner() public override view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwner() public virtual override onlyOwner() {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushOwner(address newOwner_) public virtual override onlyOwner() {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullOwner() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

interface IsDepositToken {
    function rebase(uint256 depositTokenProfit_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function gonsForBalance(uint amount) external view returns (uint);

    function balanceForGons(uint gons) external view returns (uint);

    function index() external view returns (uint);
}

interface ITreasury {
    function mintRewards(address _recipient, uint _amount) external;
}

contract Singleton {
    // singleton always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address private singleton;
}

contract StakingImplement is Singleton, Ownable {

    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address public depositToken;
    address public sDepositToken;

    struct Epoch {
        uint length;
        uint number;
        uint endBlock;
        uint distribute;
        uint staked;
    }

    struct Claim {
        uint deposit;
        uint gons;
        uint expiry;
        bool lock; // prevents malicious delays
    }

    Epoch public epoch;
    uint public totalBonus;
    address public treasury;
    uint256 public rateReward;// dec :10**6

    event DepositorChange(bool resultBefore, address indexed depositor, bool resultAfter);
    event RewardChange(uint256 resultBefore, uint256 resultAfter);

    mapping(address => bool) public isDepositor;

    function initialize(
        address _depositToken,
        address _sDepositToken,
        uint _epochLength,
        uint _firstEpochNumber,
        uint _firstEpochBlock,
        uint256 _rateReward,
        address _treasury,
        address __owner
    ) external {
        require(owner() == address(0));
        initializeOwnable(__owner);
        require(_depositToken != address(0));
        depositToken = _depositToken;
        require(_sDepositToken != address(0));
        rateReward = _rateReward;
        sDepositToken = _sDepositToken;
        epoch = Epoch(_epochLength, _firstEpochNumber, _firstEpochBlock, 0, 0);
        treasury = _treasury;
    }

    function setRateReward(uint256 _rateReward) public onlyOwner {
        emit RewardChange(rateReward, _rateReward);
        rateReward = _rateReward;
    }

    function setDepositor(address _depositor, bool _result) public onlyOwner {
        emit DepositorChange(isDepositor[_depositor], _depositor, _result);
        isDepositor[_depositor] = _result;
    }

    function stake(uint _amount, address _recipient) external returns (bool) {
        rebase();
        IBEP20(depositToken).safeTransferFrom(msg.sender, address(this), _amount);
        IBEP20(sDepositToken).safeTransfer(_recipient, _amount);
        return true;
    }

    function unstakeAll(bool _trigger) external {
        if (_trigger) {
            rebase();
        }
        uint256 _amount = IBEP20(sDepositToken).balanceOf(msg.sender);
        IBEP20(sDepositToken).safeTransferFrom(msg.sender, address(this), _amount);
        IBEP20(depositToken).safeTransfer(msg.sender, _amount);
    }

    /**
        @notice returns the sDepositToken index, which tracks rebase growth
        @return uint
     */
    function index() public view returns (uint) {
        return IsDepositToken(sDepositToken).index();
    }

    /**
        @notice trigger rebase if epoch over
     */
    function rebase() public {
        if (epoch.endBlock <= block.number) {
            epoch.endBlock = epoch.endBlock.add(epoch.length);
            epoch.number++;
            uint staked = IsDepositToken(sDepositToken).circulatingSupply();
            uint256 reward = staked.mul(rateReward).div(10 ** 6);
            if (address(treasury) != address(0)) {
                ITreasury(treasury).mintRewards(address(this), reward);
            }

            uint balance = IBEP20(depositToken).balanceOf(address(this));
            if (balance <= staked) {
                epoch.distribute = 0;
                epoch.staked = staked;
            } else {
                epoch.distribute = balance.sub(staked);
                epoch.staked = staked;
            }
            IsDepositToken(sDepositToken).rebase(epoch.distribute, epoch.number);
        }
    }

    /**
        @notice provide bonus to locked staking contract
        @param _amount uint
     */
    function giveLockBonus(address to, uint _amount) external onlyOwner {
        totalBonus = totalBonus.add(_amount);
        IBEP20(sDepositToken).safeTransfer(to, _amount);
    }

    function pendingRewardRebase() public view returns (uint256){
        return IsDepositToken(sDepositToken).circulatingSupply().mul(rateReward).div(10 ** 6);
    }
}
