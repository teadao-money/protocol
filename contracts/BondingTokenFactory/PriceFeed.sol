pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IBase {

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


contract PriceFeed is IBase {
    function getPrice(address token1, address token2)
    public view returns (ResponsePriceData memory)
    {
        return ResponsePriceData(1e9, 1, 1);
    }

    function getPrice(address token1)
    public view returns (PriceData memory)
    {

        return PriceData(13700000000000, 1);
    }


}