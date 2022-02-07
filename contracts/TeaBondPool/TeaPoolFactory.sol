// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "./TeaBond.sol";

import "hardhat/console.sol";

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ITeaBond {
    function deposit(address _depositor, uint256 _amount) external returns (uint);

    function initialize(
        address _owner,
        uint _controlVariable,
        uint _vestingTerm,
        uint _maxPayout,
        uint _fee
    ) external;

    function redeem(address _recipient, bool _stake) external returns (uint);

    function transferOwnership(address newOwner) external;
}

interface ITeaTreasury {
    function setDepositorOnlySetter(address _depositor, bool _result) external;
}

interface ITeaPool {
    function initPool(
        address _admin,
        address tea,
        address _stablecoin,
        address bondCalculator,
        address treasury,
        address dao,
        address teaStaking) external returns (address);
}

contract TeaPool is Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    uint controlVariable = 11000;
    uint vestingTerm = 500;
    uint minimumPrice = 26000;
    uint maxPayout = 300;
    uint fee = 1000;

    address public bond;
    address public principle;
    address public tea;
    mapping(address => bool) public isBond721;

    function initPool(
        address _admin,
        address _tea,
        address _principle,
        address bondCalculator,
        address treasury,
        address dao,
        address teaStaking) external returns (address) {

        tea = _tea;
        principle = _principle;
        bond = address(new TeaBond(_tea, _principle, bondCalculator, treasury, dao, teaStaking));
        ITeaBond(bond).initialize(_admin, controlVariable, vestingTerm, maxPayout, fee);
        initOwnable(_admin);

        return bond;
    }

    function setBond721(address _bond721, bool _status) public onlyOwner {
        isBond721[_bond721] = _status;
    }

    function addLiquidity(uint256 _amount) external {
        IERC20(principle).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(principle).approve(address(bond), _amount);
        ITeaBond(bond).deposit(address(this), _amount);

    }

    function redeem() external onlyOwner {
        ITeaBond(bond).redeem(address(this), false);
    }

    function bond721(uint256 _amount) external {
        require(isBond721[msg.sender], "must bond721");
        IERC20(tea).safeTransfer(msg.sender, _amount);
    }

    function clearERC20(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }


}

contract TeaPoolFactory is Ownable {
    using SafeERC20 for IERC20;

    address public treasury;
    address public dao;
    address public tea;

    address public teaStaking;
    address public bondCalculator;
    address[] public listPools;

    mapping(address => bool) public supportTokenBond;

    event CreatePool(address, address stablecoin, address _user);

    constructor(address _treasury, address _dao, address _tea, address _bondCalculator, address _teaStaking) public {
        treasury = _treasury;
        dao = _dao;
        tea = _tea;
        bondCalculator = _bondCalculator;
        teaStaking = _teaStaking;
        initOwnable(msg.sender);
    }

    function changeTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function setTokenBond(address _stablecoin, bool _status) public onlyOwner {
        supportTokenBond[_stablecoin] = _status;
    }

    function createPool(
        address _user,
        address _principle
    ) public {
        require(supportTokenBond[_principle], "stable coin not support");
        address newPool = address(new TeaPool());
        address newBond = ITeaPool(newPool).initPool(_user, tea, _principle, bondCalculator, treasury, dao, teaStaking);
        ITeaTreasury(treasury).setDepositorOnlySetter(newBond, true);
        listPools.push(newPool);
        emit CreatePool(newPool, _principle, _user);
    }

}
