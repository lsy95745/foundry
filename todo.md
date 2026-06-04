实现一个工厂合约，在以太坊上用 ERC20 模拟 meme 铸造（用最小代
理）
方法 1：deployInscription(string symbol, uint totalSupply, uint perMint) 
方法 2：mintInscription(address tokenAddr)


forge script script/InscriptionFactory.s.sol \
  --account lsy \
  --sender $(cast wallet address --account lsy) \
  --rpc-url sepolia \
  --broadcast \
  --verify


forge verify-contract \
  0x8aef67eab4ccc5b546b9e2ae3792038c9406f662 \
  src/InscriptionToken.sol:InscriptionToken \
  --chain sepolia \
  --rpc-url sepolia \
  --etherscan-api-key $ETHERSCAN_API_KEY



实现一个 AirdopMerkleNFTMarket 合约(假定 Token、NFT、AirdopMerkleNFTMarket 都是同一个开发者开发)，功能如下：

基于 Merkel 树验证某用户是否在白名单中
在白名单中的用户可以使用上架指定价格的优惠 50% 的Token 来购买 NFT， Token 需支持 permit 授权。
要求使用 multicall( delegateCall 方式) 一次性调用两个方法：

permitPrePay() : 调用token的 permit 进行授权
claimNFT() : 通过默克尔树验证白名单，并利用 permitPrePay 的授权，转入 token 转出 NFT 。