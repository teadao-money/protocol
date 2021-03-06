// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

pragma experimental ABIEncoderV2;

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
        return c;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

interface IBEP20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

interface IStaking {
    function stake(uint _amount, address _recipient) external returns (bool);
}

interface ITreasury {
    function deposit(address _token, uint _lpAmount, uint256 _paymentTokenAmount) external returns (uint);
}

interface IPriceData {
    function latestAnswer() external view returns (int256 answer);

    function latestTimestamp() external view returns (uint256 answer);

    function decimals() external view returns (uint8);
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused external {
        paused = false;
        Unpause();
    }
}

contract Singleton {
    // singleton always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address private singleton;
}


contract BondBEPImplement is Singleton, Pausable {

    using SafeBEP20 for IBEP20;
    using SafeMath for uint;

    /* ======== EVENTS ======== */

    event BondCreated(uint deposit, uint indexed payout, uint indexed expires);
    event BondRedeemed(address indexed recipient, uint payout, uint remaining);


    /* ======== STATE VARIABLES ======== */

    address public staking;
    address public DAO;
    address public paymentToken; // token given as payment for bond
    address public principle; // token used to create bond
    IPriceData public principlePriceFeed;
    IPriceData public paymentTokenPriceFeed;
    address public treasury;

    Terms public terms; // stores terms for new bonds
    mapping(address => Bond) public bondInfo; // stores bond information for depositors

    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint controlVariable; // scaling variable for price
        uint vestingTerm; // in blocks
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
    }

    // Info for bond holder
    struct Bond {
        uint payout; // OHM remaining to be paid
        uint vesting; // Blocks left to vest
        uint lastBlock; // Last interaction
    }

    /* ======== INITIALIZATION ======== */

    function initialize(
        address _paymentToken,
        address _principle,
        address _principlePriceFeed,
        address _paymentTokenPriceFeed,
        address _treasury,
        address _dao,
        address _staking,
        address __owner,
        uint _controlVariable,
        uint _vestingTerm,
        uint _maxPayout,
        uint _fee
    ) public {
        // principle cannot equal address(0) after initialize
        require(principle == address(0));
        initializeOwnable(__owner);
        require(_paymentToken != address(0));
        paymentToken = _paymentToken;
        require(_principle != address(0));
        principle = _principle;
        require(_principlePriceFeed != address(0));
        principlePriceFeed = IPriceData(_principlePriceFeed);
        require(_paymentTokenPriceFeed != address(0));
        paymentTokenPriceFeed = IPriceData(_paymentTokenPriceFeed);
        require(_treasury != address(0));
        treasury = _treasury;
        require(_dao != address(0));
        DAO = _dao;
        require(_staking != address(0));
        staking = _staking;
        require(terms.controlVariable == 0, "Bonds must be initialized from 0");
        terms = Terms({controlVariable : _controlVariable, vestingTerm : _vestingTerm, maxPayout : _maxPayout, fee : _fee});
    }

    function setDAO(address _DAO) public onlyOwner {
        DAO = _DAO;
    }

    modifier priceFeedValid(){
        require(block.timestamp.sub(principlePriceFeed.latestTimestamp()) < 86400
            && block.timestamp.sub(paymentTokenPriceFeed.latestTimestamp()) < 86400, "Inactive price feed");
        _;
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _maxPayout uint
     *  @param _fee uint
     */
    function initializeBondTerms(
        uint _controlVariable,
        uint _vestingTerm,
        uint _maxPayout,
        uint _fee
    ) external onlyOwner {
        require(terms.controlVariable == 0, "Bonds must be initialized from 0");
        terms = Terms({controlVariable : _controlVariable, vestingTerm : _vestingTerm, maxPayout : _maxPayout, fee : _fee});
    }

    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER {VESTING, PAYOUT, FEE, DISCOUNT}
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */

    function setBondTerms(PARAMETER _parameter, uint _input) external onlyOwner {
        if (_parameter == PARAMETER.VESTING) {// 0
            require(_input >= 10000, "Vesting must be longer than 36 hours");
            terms.vestingTerm = _input;
        } else if (_parameter == PARAMETER.PAYOUT) {// 1
            require(_input <= 1000, "Payout cannot be above 1 percent");
            terms.maxPayout = _input;
        } else if (_parameter == PARAMETER.FEE) {// 2
            require(_input <= 10000, "DAO fee cannot exceed payout");
            terms.fee = _input;
        } else if (_parameter == PARAMETER.DISCOUNT) {// 3
            // output need input = 1k => discount output= (10k+1k)/10K = 110%
            terms.controlVariable = _input;
        }
    }


    /* ======== USER FUNCTIONS ======== */
    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(uint _amount, address _depositor) external whenNotPaused priceFeedValid returns (uint){
        require(_depositor != address(0), "Invalid address");
        //Calculate principle token to paymentToken
        uint value = uint256(principlePriceFeed.latestAnswer()).mul(10 ** paymentTokenPriceFeed.decimals()).div(10 ** principlePriceFeed.decimals())
        .mul(_amount).div(uint256(paymentTokenPriceFeed.latestAnswer()));
        // convert decimal of token
        value = value.mul(10 ** IBEP20(paymentToken).decimals()).div(10 ** IBEP20(principle).decimals());

        //Apply discount
        uint payout = payoutFor(value);
        // must be > 0.01 paymentToken ( underflow protection )
        require(payout <= maxPayout(), "Bond too large");
        // size protection because there is no slippage

        // profits are calculated
        uint fee = payout.mul(terms.fee).div(10000);

        /**
            principle is transferred in
            approved and
            deposited into 
         */
        IBEP20(principle).safeTransferFrom(msg.sender, address(this), _amount);
        IBEP20(principle).approve(address(treasury), _amount);
        ITreasury(treasury).deposit(principle, _amount, payout.add(fee));

        if (fee != 0) {// fee is transferred to dao
            IBEP20(paymentToken).safeTransfer(DAO, fee);
        }

        // depositor info is stored
        bondInfo[_depositor] = Bond({payout : bondInfo[_depositor].payout.add(payout), vesting : terms.vestingTerm, lastBlock : block.number});
        // indexed events are emitted
        emit BondCreated(_amount, payout, block.number.add(terms.vestingTerm));
        // control variable is adjusted
        return payout;
    }

    /**
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @return uint
     */
    function redeem(address _recipient, bool _stake) external returns (uint) {
        Bond memory info = bondInfo[_recipient];
        uint percentVested = percentVestedFor(_recipient);
        // (blocks since last interaction / vesting term remaining)

        if (percentVested >= 1000000000) {// if fully vested
            delete bondInfo[_recipient];
            // delete user info
            emit BondRedeemed(_recipient, info.payout, 0);
            // emit bond data
            return stakeOrSend(_recipient, _stake, info.payout);
            // send payout


        } else {// if unfinished
            // calculate payout vested
            uint payout = info.payout.mul(percentVested).div(1000000000);

            // store updated deposit info
            bondInfo[_recipient] = Bond({payout : info.payout.sub(payout), vesting : info.vesting.sub(block.number.sub(info.lastBlock)), lastBlock : block.number});

            emit BondRedeemed(_recipient, payout, bondInfo[_recipient].payout);
            return stakeOrSend(_recipient, _stake, payout);
            // send payout
        }

    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to stake payout automatically
     *  @param _stake bool
     *  @param _amount uint
     *  @return uint
     */
    function stakeOrSend(address _recipient, bool _stake, uint _amount) internal returns (uint) {
        if (!_stake) {// if user does not want to stake
            IBEP20(paymentToken).transfer(_recipient, _amount);
            // send payout
        } else {// if user wants to stake
            IBEP20(paymentToken).approve(staking, _amount);
            IStaking(staking).stake(_amount, _recipient);

        }
        return _amount;
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns (uint) {
        return IBEP20(paymentToken).totalSupply().mul(terms.maxPayout).div(100000);
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor(uint _value) public view returns (uint) {
        return terms.controlVariable.mul(_value).div(10000);
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor(address _depositor) public view returns (uint percentVested_) {
        Bond memory bond = bondInfo[_depositor];
        uint blocksSinceLast = block.number.sub(bond.lastBlock);
        uint vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = blocksSinceLast.mul(1000000000).div(vesting);
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of OHM available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(address _depositor) external view returns (uint pendingPayout_) {
        uint percentVested = percentVestedFor(_depositor);
        uint payout = bondInfo[_depositor].payout;

        if (percentVested >= 1000000000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul(percentVested).div(1000000000);
        }
    }

}
