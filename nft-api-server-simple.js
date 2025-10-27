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
        
        // 记录转移历史（模拟）
        const transferRecord = {
            id: `transfer-${Date.now()}`,
            tokenId: tokenId,
            threadId: threadId,
            fromUsername: fromUsername,
            toUsername: toUsername,
            timestamp: new Date().toISOString(),
            status: 'completed'
        };
        
        res.json({
            success: true,
            tokenId: tokenId,
            message: `NFT transferred from ${fromUsername} to ${toUsername}`,
            transferRecord: transferRecord
        });
        
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 获取转移历史端点
app.get('/api/transfer-history/:username', async (req, res) => {
    try {
        const { username } = req.params;
        
        // 模拟转移历史数据
        const transferHistory = [
            {
                id: `transfer-${Date.now()}-1`,
                tokenId: `NFT-${Date.now()}-1`,
                threadId: 'thread-1',
                fromUsername: 'user1',
                toUsername: username,
                timestamp: new Date(Date.now() - 86400000).toISOString(), // 1天前
                status: 'completed',
                message: 'Thanks for the NFT!'
            },
            {
                id: `transfer-${Date.now()}-2`,
                tokenId: `NFT-${Date.now()}-2`,
                threadId: 'thread-2',
                fromUsername: username,
                toUsername: 'user2',
                timestamp: new Date(Date.now() - 172800000).toISOString(), // 2天前
                status: 'completed',
                message: null
            }
        ];
        
        res.json({
            success: true,
            username: username,
            transfers: transferHistory,
            totalCount: transferHistory.length
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

// 获取用户NFT列表端点
app.get('/api/user-nfts/:username', async (req, res) => {
    try {
        const { username } = req.params;
        
        // 模拟用户NFT列表
        const userNFTs = [
            {
                tokenId: `NFT-${Date.now()}-1`,
                threadId: 'thread-1',
                buildingId: 'building-1',
                timestamp: new Date().toISOString(),
                contractAddress: '0xA0fA27fC547D544528e9BE0cb6569E9B925e533E',
                owner: username
            },
            {
                tokenId: `NFT-${Date.now()}-2`,
                threadId: 'thread-2',
                buildingId: 'building-2',
                timestamp: new Date().toISOString(),
                contractAddress: '0xA0fA27fC547D544528e9BE0cb6569E9B925e533E',
                owner: username
            }
        ];
        
        res.json({
            success: true,
            username: username,
            nfts: userNFTs,
            totalCount: userNFTs.length
        });
        
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 获取NFT详情端点
app.get('/api/nft/:tokenId', async (req, res) => {
    try {
        const { tokenId } = req.params;
        
        // 模拟NFT详情
        const nftDetail = {
            tokenId: tokenId,
            threadId: 'thread-1',
            buildingId: 'building-1',
            timestamp: new Date().toISOString(),
            contractAddress: '0xA0fA27fC547D544528e9BE0cb6569E9B925e533E',
            owner: 'current-user',
            metadata: {
                name: 'Phygital Asset Thread',
                description: 'A unique digital asset representing a physical location',
                image: 'https://example.com/nft-image.jpg'
            }
        };
        
        res.json({
            success: true,
            nft: nftDetail
        });
        
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 获取所有NFT列表端点
app.get('/api/all-nfts', async (req, res) => {
    try {
        const { page = 1, limit = 20 } = req.query;
        
        // 模拟所有NFT列表
        const allNFTs = Array.from({ length: parseInt(limit) }, (_, i) => ({
            tokenId: `NFT-${Date.now()}-${i + 1}`,
            threadId: `thread-${i + 1}`,
            buildingId: `building-${i + 1}`,
            timestamp: new Date().toISOString(),
            contractAddress: '0xA0fA27fC547D544528e9BE0cb6569E9B925e533E',
            owner: `user-${(i % 5) + 1}`
        }));
        
        res.json({
            success: true,
            nfts: allNFTs,
            totalCount: allNFTs.length,
            page: parseInt(page),
            limit: parseInt(limit)
        });
        
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
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
            contract: 'GET /api/contract-info',
            userNFTs: 'GET /api/user-nfts/:username',
            nftDetail: 'GET /api/nft/:tokenId',
            allNFTs: 'GET /api/all-nfts',
            transferHistory: 'GET /api/transfer-history/:username'
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
