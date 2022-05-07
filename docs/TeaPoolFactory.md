### TeaPoolFactory
- Smart contarct tạo pool, trong đó nó sẽ gen ra 1 pool và 1 smc bond tương ứng.
- Function:
```angular2html
function createPool(
        address _user,
        address _principle,
        address _dao,
        uint _controlVariable,
        uint _vestingTerm,
        uint _minimumPrice,
        uint _maxPayout,
    uint _fee
    ) public

- _user: Người tạo
- _principle: Stablecoin để bond
- _dao: 
- _controlVariable
- _vestingTerm: 
- _minimumPrice: 
- _maxPayout: 
```

### TeaPool
- Smart contract này được tạo từ hàm createPool của smc TeaPoolFactory. Trong này có 1 số hàm sau
1. addLiquidity(uint256 _amount):
- Hàm này cho phép đẩy thêm stablecoin vào bonding
2. redeem(): Hàm này sẽ lấy tea về pool
3. bond721(): Cho phép 1 số bond nft721 lấy tea ra khỏi pool

### TeaTreasuary
- Smart contract này nhận toàn bộ stablecoin của tất cả các pool khi addLiquidity
### TeaBondNFT721
- Smart contract cho phép bond nft(mình chỉ đang hỗ trợ 1 số nft721 như axie...)
### TeaPriceFeedNFT
- Smart contract nhận request price của smart contract TeaBondNFT721 và fulfillPrice về TeaBondNFT721.

### Ghi chú: 
-  rút nft khi bond chưa có
