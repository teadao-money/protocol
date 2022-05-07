1. Mô tả
- Tea price feed nft cung cấp dữ liệu onchain về giá tài số nft. 
2. Hash collection
- Hiện tại tea đang hỗ trợ các collection axie,... Mỗi collection được định danh bằng hash collection trên onchain
```angular2html
axie : 0x2f2a88c990a072061563923b0229c2514e5df82e806eceaabc961eb7203fde85
```
3. Địa chỉ smart contract
```angular2html
bsc testnet : 0x12c602FbCc91Ac7Fa45Aa3883B64b0641463AAFe
```
4. Cách sử dụng
- smart contract client
```
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface ITeaPriceFeedNFT {
    function randomnessRequest(uint256 _id, bytes32 _collection, bytes calldata _data) external returns (bytes32 reqId);
}

contract TeaPriceFeedNFTClient {

    uint256 public price;

    bytes32 public reqId;

    address public oracle = 0x12c602FbCc91Ac7Fa45Aa3883B64b0641463AAFe;

    constructor (address _oracle) public {
        oracle = _oracle;
    }

    function randomnessRequest(uint256 _id, bytes32 hashColelction) public {

        bytes memory data = abi.encode(address(this), this.fulfillRandomness.selector);

        reqId = ITeaPriceFeedNFT(oracle).randomnessRequest(_id, hashColelction, data);
    }

    function fulfillRandomness(bytes32 _reqId, uint256 _price) external {
        price = _price;
    }

}
```
- randomnessRequest(): Hàm thực hiện yêu cầu lấy giá nft
```angular2html
id : Id của collection
hashColelction : hash của collection mà bạn muốn lấy giá
```
- fulfillRandomness(): Hàm nhận dữ liệu từ tea price feed
```angular2html
_reqId : mỗi request get price  sẽ ứng với 1 reqId.
_price : giá ứng với id request đó
```
