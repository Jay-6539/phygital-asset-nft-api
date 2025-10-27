const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json());

// 健康检查端点
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        network: 'matic-amoy',
        chainId: 80002,
        contractAddress: '0xA0fA27fC547D544528e9BE0cb6569E9B925e533E',
        contractName: 'Phygital Asset Thread',
        totalSupply: '3',
        timestamp: new Date().toISOString()
    });
});

// NFT铸造端点
app.post('/api/mint-thread', async (req, res) => {
    try {
        const { threadId, username, buildingId, description, imageUrl } = req.body;
        
        // 模拟NFT铸造过程
        const tokenId = `NFT-${Date.now()}`;
        const transactionHash = `0x${Math.random().toString(16).substr(2, 64)}`;
        
        // 模拟延迟
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        res.json({
            success: true,
            tokenId: tokenId,
            transactionHash: transactionHash,
            gasUsed: '150000',
            alreadyMinted: false,
            contractAddress: '0xA0fA27fC547D544528e9BE0cb6569E9B925e533E',
            elapsed: 1000
        });
        
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// NFT转移端点
app.post('/api/transfer-nft', async (req, res) => {
    try {
        const { threadId, fromUsername, toUsername } = req.body;
        
        // 模拟NFT转移过程
        const tokenId = `NFT-${Date.now()}`;
        
        res.json({
            success: true,
            tokenId: tokenId,
            message: `NFT transferred from ${fromUsername} to ${toUsername}`
        });
        
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 合约信息端点
app.get('/api/contract-info', (req, res) => {
    res.json({
        name: 'Phygital Asset Thread',
        symbol: 'PAT',
        totalSupply: '3',
        contractAddress: '0xA0fA27fC547D544528e9BE0cb6569E9B925e533E',
        network: 'Amoy Testnet',
        chainId: 80002
    });
});

// 根路径
app.get('/', (req, res) => {
    res.json({
        message: '🎨 Phygital Asset NFT API Server',
        version: '1.0.0',
        status: 'running',
        endpoints: {
            health: 'GET /api/health',
            mint: 'POST /api/mint-thread',
            transfer: 'POST /api/transfer-nft',
            contract: 'GET /api/contract-info'
        },
        contractAddress: '0xA0fA27fC547D544528e9BE0cb6569E9B925e533E',
        network: 'Amoy Testnet'
    });
});

// 启动服务器
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 NFT API服务已启动: http://0.0.0.0:${PORT}`);
    console.log(`📊 合约地址: 0xA0fA27fC547D544528e9BE0cb6569E9B925e533E`);
    console.log(`🌐 网络: Amoy Testnet (80002)`);
    console.log(`🔗 健康检查: http://127.0.0.1:${PORT}/api/health`);
    console.log(`🎨 铸造端点: POST http://127.0.0.1:${PORT}/api/mint-thread`);
    console.log(`📋 合约信息: GET http://127.0.0.1:${PORT}/api/contract-info`);
});
