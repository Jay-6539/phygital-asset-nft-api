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
    contractAddress: process.env.CONTRACT_ADDRESS || '0xA0fA27fC547D544528e9BE0cb6569E9B925e533E',
    privateKey: process.env.AMOY_PRIVATE_KEY
};

// 初始化provider和wallet
const provider = new ethers.JsonRpcProvider(AMOY_CONFIG.rpcUrl);
const wallet = new ethers.Wallet(AMOY_CONFIG.privateKey, provider);

// 合约ABI（简化版）
const contractABI = [
    "function mintThread(string memory _threadId, string memory _username, string memory _buildingId, string memory _description, string memory _imageUrl) external returns (uint256)",
    "function getTokenIdByThreadId(string memory threadId) public view returns (uint256)",
    "function ownerOf(uint256 tokenId) public view returns (address)",
    "function getThreadMetadata(uint256 tokenId) public view returns (tuple(string threadId, string username, string buildingId, string description, string imageUrl, uint256 createdAt))",
    "function totalSupply() public view returns (uint256)",
    "function name() public view returns (string)",
    "function symbol() public view returns (string)",
    "event ThreadMinted(uint256 indexed tokenId, string indexed threadId, address indexed owner, string username, string buildingId)"
];

const contract = new ethers.Contract(AMOY_CONFIG.contractAddress, contractABI, wallet);

// 根路径 - 显示API信息
app.get('/', (req, res) => {
    res.json({
        message: '🎨 Phygital Asset NFT API Server (Amoy)',
        version: '2.0.0',
        status: 'running',
        network: 'Amoy Testnet',
        chainId: AMOY_CONFIG.chainId,
        contractAddress: AMOY_CONFIG.contractAddress,
        endpoints: {
            health: 'GET /api/health',
            mint: 'POST /api/mint-thread',
            transfer: 'POST /api/transfer-nft',
            query: 'GET /api/nft/:threadId',
            contract: 'GET /api/contract-info'
        }
    });
});

// 健康检查端点
app.get('/api/health', async (req, res) => {
    try {
        const network = await provider.getNetwork();
        const contractName = await contract.name();
        const totalSupply = await contract.totalSupply();
        
        res.json({
            status: 'ok',
            network: network.name,
            chainId: Number(network.chainId),
            contractAddress: AMOY_CONFIG.contractAddress,
            contractName: contractName,
            totalSupply: totalSupply.toString(),
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            error: error.message
        });
    }
});

// 合约信息端点
app.get('/api/contract-info', async (req, res) => {
    try {
        const name = await contract.name();
        const symbol = await contract.symbol();
        const totalSupply = await contract.totalSupply();
        const owner = await wallet.address;
        
        res.json({
            name: name,
            symbol: symbol,
            totalSupply: totalSupply.toString(),
            owner: owner,
            contractAddress: AMOY_CONFIG.contractAddress,
            network: 'Amoy Testnet',
            chainId: AMOY_CONFIG.chainId
        });
    } catch (error) {
        res.status(500).json({
            error: error.message
        });
    }
});

// NFT铸造端点
app.post('/api/mint-thread', async (req, res) => {
    const startTime = Date.now();
    
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
        const mintEvent = receipt.logs.find(log => {
            try {
                const parsed = contract.interface.parseLog(log);
                return parsed.name === 'ThreadMinted';
            } catch {
                return false;
            }
        });
        
        let tokenId = "1"; // 默认值
        if (mintEvent) {
            const parsed = contract.interface.parseLog(mintEvent);
            tokenId = parsed.args.tokenId.toString();
        }
        
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

// NFT查询端点
app.get('/api/nft/:threadId', async (req, res) => {
    try {
        const { threadId } = req.params;
        
        const tokenId = await contract.getTokenIdByThreadId(threadId);
        if (tokenId == 0) {
            return res.status(404).json({
                error: 'NFT not found'
            });
        }
        
        const metadata = await contract.getThreadMetadata(tokenId);
        const owner = await contract.ownerOf(tokenId);
        
        res.json({
            threadId: threadId,
            tokenId: tokenId.toString(),
            owner: owner,
            metadata: {
                threadId: metadata.threadId,
                username: metadata.username,
                buildingId: metadata.buildingId,
                description: metadata.description,
                imageUrl: metadata.imageUrl,
                createdAt: new Date(Number(metadata.createdAt) * 1000).toISOString()
            },
            contractAddress: AMOY_CONFIG.contractAddress,
            polygonscanUrl: `https://amoy.polygonscan.com/token/${AMOY_CONFIG.contractAddress}?a=${tokenId}`,
            openseaUrl: `https://testnets.opensea.io/assets/amoy/${AMOY_CONFIG.contractAddress}/${tokenId}`
        });
        
    } catch (error) {
        console.error('❌ NFT查询失败:', error);
        res.status(500).json({
            error: error.message
        });
    }
});

// NFT转移端点（预留）
app.post('/api/transfer-nft', async (req, res) => {
    res.json({
        message: 'Transfer functionality not implemented yet',
        status: 'coming_soon'
    });
});

// 启动服务器
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 NFT API服务已启动 (Amoy): http://0.0.0.0:${PORT}`);
    console.log(`📊 合约地址: ${AMOY_CONFIG.contractAddress}`);
    console.log(`🌐 网络: Amoy Testnet (${AMOY_CONFIG.chainId})`);
    console.log(`🔗 健康检查: http://127.0.0.1:${PORT}/api/health`);
    console.log(`🎨 铸造端点: POST http://127.0.0.1:${PORT}/api/mint-thread`);
    console.log(`📋 合约信息: GET http://127.0.0.1:${PORT}/api/contract-info`);
});
