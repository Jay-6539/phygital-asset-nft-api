# 🚀 NFT铸造迁移到Amoy主网指南

## 📋 迁移步骤概览

### 第1步：准备Amoy网络配置
### 第2步：创建智能合约
### 第3步：部署API服务到云端
### 第4步：更新应用配置
### 第5步：测试验证

---

## 🔧 第1步：准备Amoy网络配置

### 1.1 获取Amoy测试网信息
```javascript
// Amoy测试网配置
const AMOY_CONFIG = {
    chainId: 80002,
    rpcUrl: 'https://rpc-amoy.polygon.technology/',
    explorerUrl: 'https://amoy.polygonscan.com/',
    currency: 'MATIC',
    gasPrice: '20000000000' // 20 Gwei
};
```

### 1.2 准备钱包和私钥
```bash
# 创建环境变量文件
echo "AMOY_PRIVATE_KEY=your_private_key_here" > .env
echo "AMOY_RPC_URL=https://rpc-amoy.polygon.technology/" >> .env
echo "AMOY_CHAIN_ID=80002" >> .env
```

---

## 📝 第2步：创建智能合约

### 2.1 创建NFT合约
```solidity
// contracts/PhygitalAssetNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PhygitalAssetNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIdCounter;
    
    struct ThreadMetadata {
        string threadId;
        string username;
        string buildingId;
        string description;
        string imageUrl;
        uint256 createdAt;
    }
    
    mapping(uint256 => ThreadMetadata) public threadMetadata;
    mapping(string => uint256) public threadIdToTokenId;
    
    event ThreadMinted(uint256 indexed tokenId, string threadId, address indexed owner);
    
    constructor() ERC721("Phygital Asset Thread", "PAT") {}
    
    function mintThread(
        string memory _threadId,
        string memory _username,
        string memory _buildingId,
        string memory _description,
        string memory _imageUrl
    ) public onlyOwner returns (uint256) {
        require(threadIdToTokenId[_threadId] == 0, "Thread already minted");
        
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        
        _safeMint(msg.sender, tokenId);
        
        threadMetadata[tokenId] = ThreadMetadata({
            threadId: _threadId,
            username: _username,
            buildingId: _buildingId,
            description: _description,
            imageUrl: _imageUrl,
            createdAt: block.timestamp
        });
        
        threadIdToTokenId[_threadId] = tokenId;
        
        emit ThreadMinted(tokenId, _threadId, msg.sender);
        return tokenId;
    }
    
    function getThreadMetadata(uint256 tokenId) public view returns (ThreadMetadata memory) {
        return threadMetadata[tokenId];
    }
    
    function getTokenIdByThreadId(string memory threadId) public view returns (uint256) {
        return threadIdToTokenId[threadId];
    }
}
```

### 2.2 部署脚本
```javascript
// scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with account:", deployer.address);
    
    const PhygitalAssetNFT = await ethers.getContractFactory("PhygitalAssetNFT");
    const nft = await PhygitalAssetNFT.deploy();
    
    await nft.deployed();
    
    console.log("NFT contract deployed to:", nft.address);
    console.log("Deployment transaction:", nft.deployTransaction.hash);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
```

---

## 🌐 第3步：部署API服务到云端

### 3.1 更新API服务
```javascript
// nft-api-server-amoy.js
const express = require('express');
const cors = require('cors');
const { ethers } = require('ethers');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json());

// Amoy网络配置
const AMOY_CONFIG = {
    chainId: 80002,
    rpcUrl: process.env.AMOY_RPC_URL || 'https://rpc-amoy.polygon.technology/',
    contractAddress: process.env.CONTRACT_ADDRESS,
    privateKey: process.env.AMOY_PRIVATE_KEY
};

// 初始化provider和wallet
const provider = new ethers.providers.JsonRpcProvider(AMOY_CONFIG.rpcUrl);
const wallet = new ethers.Wallet(AMOY_CONFIG.privateKey, provider);

// 合约ABI（简化版）
const contractABI = [
    "function mintThread(string memory _threadId, string memory _username, string memory _buildingId, string memory _description, string memory _imageUrl) external returns (uint256)",
    "function getTokenIdByThreadId(string memory threadId) public view returns (uint256)",
    "function ownerOf(uint256 tokenId) public view returns (address)"
];

const contract = new ethers.Contract(AMOY_CONFIG.contractAddress, contractABI, wallet);

// NFT铸造端点
app.post('/api/mint-thread', async (req, res) => {
    try {
        const { threadId, username, buildingId, description, imageUrl } = req.body;
        
        console.log(`🎨 铸造NFT请求 (Amoy):`, {
            threadId,
            username,
            buildingId,
            description: description?.substring(0, 50) + '...',
            imageUrl: imageUrl ? '有图片' : '无图片'
        });
        
        // 检查是否已铸造
        try {
            const existingTokenId = await contract.getTokenIdByThreadId(threadId);
            if (existingTokenId > 0) {
                return res.json({
                    success: true,
                    tokenId: existingTokenId.toString(),
                    transactionHash: null,
                    alreadyMinted: true,
                    contractAddress: AMOY_CONFIG.contractAddress,
                    elapsed: 0
                });
            }
        } catch (error) {
            // 如果查询失败，继续铸造
        }
        
        // 执行铸造交易
        const tx = await contract.mintThread(
            threadId,
            username,
            buildingId || "",
            description || "",
            imageUrl || ""
        );
        
        console.log(`📝 交易已提交: ${tx.hash}`);
        
        // 等待交易确认
        const receipt = await tx.wait();
        console.log(`✅ 交易已确认: ${receipt.transactionHash}`);
        
        // 获取Token ID（从事件日志中解析）
        const mintEvent = receipt.events.find(e => e.event === 'ThreadMinted');
        const tokenId = mintEvent.args.tokenId.toString();
        
        res.json({
            success: true,
            tokenId: tokenId,
            transactionHash: receipt.transactionHash,
            gasUsed: receipt.gasUsed.toString(),
            alreadyMinted: false,
            contractAddress: AMOY_CONFIG.contractAddress,
            elapsed: Date.now() - startTime
        });
        
    } catch (error) {
        console.error('❌ NFT铸造失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 健康检查端点
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        contractAddress: AMOY_CONFIG.contractAddress,
        network: 'Amoy Testnet',
        chainId: AMOY_CONFIG.chainId
    });
});

app.listen(PORT, () => {
    console.log(`🚀 NFT API服务已启动 (Amoy): http://localhost:${PORT}`);
    console.log(`📊 合约地址: ${AMOY_CONFIG.contractAddress}`);
    console.log(`🌐 网络: Amoy Testnet (${AMOY_CONFIG.chainId})`);
});
```

### 3.2 部署到云端
```bash
# 使用Vercel部署
npm install -g vercel
vercel --prod

# 或使用Railway
npm install -g @railway/cli
railway login
railway init
railway up
```

---

## 📱 第4步：更新应用配置

### 4.1 更新NFTManager
```swift
// Phygital Asset/Managers/NFTManager.swift
class NFTManager {
    static let shared = NFTManager()
    private init() {}
    
    // 生产环境API地址
    private let apiURL: String = {
        #if DEBUG
        // 开发环境：本地测试
        return "http://127.0.0.1:3000/api"
        #else
        // 生产环境：云端API
        return "https://your-api-domain.vercel.app/api"
        #endif
    }()
    
    // 备用API地址
    private let backupAPIURL = "https://your-backup-api.railway.app/api"
    
    // 网络配置
    private let networkConfig = [
        "chainId": 80002,
        "networkName": "Amoy Testnet",
        "explorerUrl": "https://amoy.polygonscan.com/",
        "currency": "MATIC"
    ]
}
```

### 4.2 更新NFTInfo模型
```swift
// Phygital Asset/Models/NFTModels.swift
struct NFTInfo {
    let threadId: UUID
    let tokenId: String
    let contractAddress: String
    let buildingId: String?
    let timestamp: String?
    
    var polygonscanURL: URL? {
        URL(string: "https://amoy.polygonscan.com/token/\(contractAddress)?a=\(tokenId)")
    }
    
    var openseaURL: URL? {
        URL(string: "https://testnets.opensea.io/assets/amoy/\(contractAddress)/\(tokenId)")
    }
}
```

---

## 🧪 第5步：测试验证

### 5.1 本地测试
```bash
# 测试API连接
curl -X POST https://your-api-domain.vercel.app/api/mint-thread \
  -H "Content-Type: application/json" \
  -d '{
    "threadId": "test-123",
    "username": "Test User",
    "buildingId": "Test Building",
    "description": "Test NFT",
    "imageUrl": ""
  }'
```

### 5.2 应用测试
1. **更新应用配置**：将API URL改为生产环境
2. **创建Thread**：测试NFT铸造功能
3. **查看区块链**：在Amoy Polygonscan上查看交易
4. **验证NFT**：在OpenSea测试网上查看NFT

---

## 💰 成本估算

### Gas费用（Amoy测试网）
- **铸造NFT**: ~0.001 MATIC
- **转移NFT**: ~0.0005 MATIC
- **查询操作**: 免费

### 部署成本
- **智能合约部署**: ~0.01 MATIC
- **API服务托管**: 免费（Vercel/Railway）
- **域名**: 可选，免费子域名可用

---

## 🔒 安全注意事项

1. **私钥安全**: 使用环境变量，不要提交到代码库
2. **权限控制**: 只有合约owner可以铸造NFT
3. **输入验证**: 验证所有用户输入
4. **错误处理**: 完善的错误处理和日志记录

---

## 📞 下一步行动

1. **获取Amoy测试网MATIC**: 从水龙头获取测试代币
2. **部署智能合约**: 使用Hardhat部署到Amoy
3. **部署API服务**: 选择Vercel或Railway
4. **更新应用配置**: 修改API URL
5. **测试验证**: 完整测试流程

需要我帮您执行其中任何一个步骤吗？
