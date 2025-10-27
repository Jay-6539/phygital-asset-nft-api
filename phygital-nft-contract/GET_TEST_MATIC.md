# 💰 获取Amoy测试网MATIC代币

## 🚨 当前状态
- ✅ 合约项目已设置完成
- ✅ 私钥已配置
- ✅ 部署脚本已修复
- ❌ **账户余额不足** - 需要获取测试MATIC

## 🔗 获取测试代币

### 方法1：官方水龙头（推荐）
1. **访问**: https://faucet.polygon.technology/
2. **选择网络**: Amoy Testnet
3. **输入地址**: `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`
4. **点击**: Submit
5. **等待**: 几分钟后检查余额

### 方法2：备用水龙头
- **QuickNode**: https://faucet.quicknode.com/polygon/amoy
- **Mumbai Faucet**: https://mumbaifaucet.com/

## 📋 获取代币后的步骤

### 1. 验证余额
```bash
# 在合约项目目录中运行
npm run deploy:amoy
```

### 2. 部署合约
如果余额充足，脚本会自动：
- ✅ 部署NFT合约
- ✅ 测试铸造功能
- ✅ 保存部署信息
- ✅ 显示合约地址

## 🎯 预期结果

部署成功后，您会看到：
```
✅ 合约部署成功!
📍 合约地址: 0x...
🔗 交易哈希: 0x...
📊 合约信息:
  名称: Phygital Asset Thread
  符号: PAT
  总供应量: 0
  拥有者: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

## 🔍 验证部署

部署成功后，您可以：
1. **查看合约**: https://amoy.polygonscan.com/address/[合约地址]
2. **测试铸造**: 脚本会自动测试铸造功能
3. **查看NFT**: 在OpenSea测试网上查看

## ⚡ 快速操作

1. **获取代币**: https://faucet.polygon.technology/
2. **运行部署**: `npm run deploy:amoy`
3. **等待完成**: 约2-3分钟

**现在就去获取测试MATIC吧！** 🚀
