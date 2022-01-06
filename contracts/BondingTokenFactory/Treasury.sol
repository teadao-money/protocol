pragma solidity 0.7.5;

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

interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeBEP20 {
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }


    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

contract Singleton {
    // singleton always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address private singleton;
}

contract TreasuryImplement is Singleton, Ownable {
    using SafeBEP20 for IBEP20;

    mapping(address => bool) public isDepositToken;
    mapping(address => bool) public isDepositor;
    mapping(address => bool) public isRewardManager;
    uint256 public totalReserves;
    address public withdrawAsset;

    event Deposit(address indexed token, uint256 indexed lpAmount, uint256 indexed teaAmount);
    event DepositTokenChange(bool resultBefore, address indexed token, bool resultAfter);
    event DepositorChange(bool resultBefore, address indexed depositor, bool resultAfter);
    event RewardManagerChange(bool resultBefore, address indexed rewardManager, bool resultAfter);
    event RewardsMinted(address indexed caller, address indexed recipient, uint amount);

    function initialize(address _withdrawAsset, address depositAsset, address __owner, address _depositToken, address _depositor, address _rewardManager) external {
        require(owner() == address(0));
        initializeOwnable(__owner);
        require(_withdrawAsset != address(0));
        withdrawAsset = _withdrawAsset;
        isDepositToken[depositAsset] = true;
        isDepositToken[_depositToken] = true;
        isDepositor[_depositor] = true;
        isRewardManager[_rewardManager] = true;
    }

    function setDepositToken(address _token, bool _result) onlyOwner external {
        emit DepositTokenChange(isDepositToken[_token], _token, _result);
        isDepositToken[_token] = _result;
    }

    function setDepositor(address _depositor, bool _result) onlyOwner external {
        emit DepositorChange(isDepositor[_depositor], _depositor, _result);
        isDepositor[_depositor] = _result;
    }

    function setIsRewardManager(address _rewardManager, bool _result) onlyOwner external {
        emit RewardManagerChange(isRewardManager[_rewardManager], _rewardManager, _result);
        isRewardManager[_rewardManager] = _result;
    }

    function deposit(address _token, uint _depositAmount, uint256 _withdrawAmount) external returns (uint) {
        require(isDepositToken[_token], "Not accepted token");
        require(isDepositor[msg.sender], "Not accepted depositor");
        IBEP20(_token).safeTransferFrom(msg.sender, address(this), _depositAmount);
        IBEP20(withdrawAsset).safeTransfer(msg.sender, _withdrawAmount);
        emit Deposit(_token, _depositAmount, _withdrawAmount);
        return _withdrawAmount;
    }

    function withdraw(address token, address to, uint _amount) external onlyOwner {
        IBEP20(token).safeTransfer(to, _amount);
    }

    function approve(address token, address to, uint _amount) external onlyOwner {
        IBEP20(token).safeApprove(to, _amount);
    }

    function mintRewards(address _recipient, uint _amount) external {
        require(isRewardManager[msg.sender], "Not approved");
        IBEP20(withdrawAsset).safeTransfer(_recipient, _amount);
        emit RewardsMinted(msg.sender, _recipient, _amount);
    }
}
