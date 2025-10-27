# 🚀 Amoy主网迁移实施计划

## 🎯 立即行动步骤

### 第1步：获取Amoy测试网代币
```bash
# 访问Amoy水龙头获取测试MATIC
# https://faucet.polygon.technology/
# 或 https://mumbaifaucet.com/
```

### 第2步：创建智能合约项目
```bash
# 创建新的Hardhat项目
mkdir phygital-nft-contract
cd phygital-nft-contract
npm init -y
npm install --save-dev hardhat
npx hardhat init
```

### 第3步：安装依赖
```bash
npm install @openzeppelin/contracts
npm install dotenv
```

### 第4步：配置环境
```bash
# 创建.env文件
echo "AMOY_PRIVATE_KEY=your_wallet_private_key" > .env
echo "AMOY_RPC_URL=https://rpc-amoy.polygon.technology/" >> .env
```

### 第5步：部署合约
```bash
npx hardhat run scripts/deploy.js --network amoy
```

---

## 📋 详细实施清单

### ✅ 准备阶段
- [ ] 创建Amoy钱包
- [ ] 获取测试MATIC代币
- [ ] 设置Hardhat项目
- [ ] 配置环境变量

### ✅ 合约阶段
- [ ] 编写NFT智能合约
- [ ] 配置Hardhat网络
- [ ] 部署到Amoy测试网
- [ ] 验证合约部署

### ✅ API阶段
- [ ] 更新API服务代码
- [ ] 集成Web3功能
- [ ] 部署到云端
- [ ] 测试API端点

### ✅ 应用阶段
- [ ] 更新NFTManager配置
- [ ] 修改API URL
- [ ] 测试NFT铸造
- [ ] 验证区块链交易

---

## 🛠️ 快速开始命令

### 1. 创建合约项目
```bash
mkdir phygital-nft-contract && cd phygital-nft-contract
npm init -y
npm install --save-dev hardhat @openzeppelin/contracts dotenv
npx hardhat init
```

### 2. 配置Hardhat
```javascript
// hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.19",
  networks: {
    amoy: {
      url: process.env.AMOY_RPC_URL,
      accounts: [process.env.AMOY_PRIVATE_KEY]
    }
  }
};
```

### 3. 部署合约
```bash
npx hardhat run scripts/deploy.js --network amoy
```

---

## 🎯 推荐实施顺序

1. **先完成合约部署**（30分钟）
2. **再更新API服务**（20分钟）
3. **最后修改应用配置**（10分钟）
4. **测试验证**（15分钟）

**总时间**: 约75分钟

---

## 💡 需要帮助吗？

我可以帮您：
1. **创建智能合约代码**
2. **配置部署脚本**
3. **更新API服务**
4. **修改应用配置**

您想从哪一步开始？
