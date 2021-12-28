# 1. Contract BondingFactory

## 1.1 function createBonding
```solidity
   struct BondCreatingData {
  // deposit token
  address stableCoin;
  // reward token
  address tea;
  // price feed to calculate data
  address priceFeed;
  // the place own bonding fee
  address dao;
  address owner;
  // totalSup init of sToken (not mul vs 10**dec)
  uint256 totalSup;
  // staking  reward each 8 hours(div 10**6)
  uint256 rate;
  // the discount when bonding (10000 = not discount)
  uint256 discount;
  // vesting block number of bonding
  uint256 bondingTime;
  // maxPayout can buy each bonding time totalSup * maxPayout / 100000
  uint256 maxPayout;
  // bonding fee amount*fee/10000
  uint256 bondingFee;
  // bonding with bnb or bep20
  BondingType _bondingType;
}
```
+ Input là struct BondCreatingData:
  + address stableCoin: đồng tiền nạp vào bonding
  + address tea: đồng tiền trả thưởng bonding
  + address priceFeed: price feed giữa đồng nạp vào và đồng reward 
  + address dao: chỗ mà phí của bonding gửi mỗi khi có thằng bond
  + address owner: owner của mấy cái bond, staking, sToken, treasury
  + uint256 totalSup: total supply của sToken, nó phải > lượng token có thể nạp vào staking (nên = total sup của tea)
  + uint256 rate: sau 8 h, reward 1 thằng nhận được = rate*depositAmount/10/**6
  + uint256 discount: khi 1 thằng nạp x tiền vào bond, thì nó sẽ nhận được discount*x/10000 tiền tea
  + uint256 bondingTime: số block vesting 
  + uint256 maxPayout: số lương tối đa nó có thể mua đồng tea trong bonding = maxPayOut*totalSup của Tea/100000
  + uint256 bondingFee: số tea được gửi cho dao mỗi khi có thằng bonding =  amount*fee/10000
  + BondingType _bondingType: loại bonding, 0 là ứng với đồng stable coin, 1 là ứng với đồng native(BNB)

Nhiệm vụ: tạo 1 bond project (bond, staking).

Dựa vào event `        emit BondCreated(staking, sToken, bonding, treasury);` để lấy thông tin các contract được tạo ra.

** Lưu ý rằng treasury tạo ở kiểu này sẽ k mint được Tea mà phải được gửi vào trước khi có ngừoi bonding




