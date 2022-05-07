pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IOraiBase {

    struct ResponsePriceData {
        uint128 rate;
        uint64 lastUpdatedBase;
        uint64 lastUpdatedQuote;
    }

    struct PriceData {
        uint128 rate; // USD-rate, multiplied by 1e18.
        uint64 resolveTime; // UNIX epoch when data is last resolved.
    }
}


contract PriceFeed is IOraiBase {
    function getPrice(address _principle)
    public view returns (ResponsePriceData memory)
    {
        return ResponsePriceData(485 * 1e18, 1, 1);
    }

    function getPrice(string memory _base)
    public view returns (PriceData memory)
    {

        return PriceData(13700000000000, 1);
    }


}
