pragma solidity 0.6.12;

contract PriceFeed {
    int256 public latestAnswer;
    uint8 public decimals;

    function latestTimestamp() external view returns (uint256 answer){
        answer = block.timestamp;
    }
    constructor(uint8 _decimals, int256 answer) public {
        decimals = _decimals;
        latestAnswer = answer;
    }
}
