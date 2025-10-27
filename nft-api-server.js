const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 3000;

// 中间件
app.use(cors());
app.use(express.json());

// 模拟NFT铸造数据
let nftCounter = 1;
const mintedNFTs = new Map();

// 根路径 - 显示API信息
app.get('/', (req, res) => {
    res.json({
        message: '🎨 Phygital Asset NFT API Server',
        version: '1.0.0',
        status: 'running',
        endpoints: {
            health: 'GET /api/health',
            mint: 'POST /api/mint-thread',
            transfer: 'POST /api/transfer-nft',
            query: 'GET /api/nft/:threadId'
        },
        contractAddress: '0x1234567890123456789012345678901234567890',
        totalMinted: nftCounter.toString()
    });
});

// 健康检查端点
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        contractAddress: '0x1234567890123456789012345678901234567890',
        totalMinted: nftCounter.toString()
    });
});

// NFT铸造端点
app.post('/api/mint-thread', async (req, res) => {
    try {
        const { threadId, username, buildingId, description, imageUrl } = req.body;
        
        console.log(`🎨 铸造NFT请求:`, {
            threadId,
            username,
            buildingId,
            description: description?.substring(0, 50) + '...',
            imageUrl: imageUrl ? '有图片' : '无图片'
        });
        
        // 检查是否已铸造
        if (mintedNFTs.has(threadId)) {
            const existing = mintedNFTs.get(threadId);
            return res.json({
                success: true,
                tokenId: existing.tokenId,
                transactionHash: existing.transactionHash,
                alreadyMinted: true,
                contractAddress: '0x1234567890123456789012345678901234567890',
                elapsed: 50
            });
        }
        
        // 模拟铸造过程
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        const tokenId = `NFT-${nftCounter++}`;
        const transactionHash = `0x${Math.random().toString(16).substr(2, 64)}`;
        
        // 保存NFT信息
        mintedNFTs.set(threadId, {
            tokenId,
            transactionHash,
            username,
            buildingId,
            description,
            imageUrl,
            timestamp: new Date().toISOString()
        });
        
        console.log(`✅ NFT铸造成功: ${tokenId}`);
        
        res.json({
            success: true,
            tokenId,
            transactionHash,
            gasUsed: '0.001',
            alreadyMinted: false,
            contractAddress: '0x1234567890123456789012345678901234567890',
            elapsed: 1000
        });
        
    } catch (error) {
        console.error('❌ NFT铸造失败:', error);
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
        
        console.log(`🔄 NFT转移请求: ${fromUsername} → ${toUsername}`);
        
        const nft = mintedNFTs.get(threadId);
        if (!nft) {
            return res.status(404).json({
                success: false,
                message: 'NFT not found'
            });
        }
        
        // 模拟转移过程
        await new Promise(resolve => setTimeout(resolve, 500));
        
        console.log(`✅ NFT转移成功: ${nft.tokenId}`);
        
        res.json({
            success: true,
            tokenId: nft.tokenId,
            message: `Successfully transferred from ${fromUsername} to ${toUsername}`
        });
        
    } catch (error) {
        console.error('❌ NFT转移失败:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 查询NFT信息端点
app.get('/api/nft/:threadId', (req, res) => {
    const { threadId } = req.params;
    const nft = mintedNFTs.get(threadId);
    
    if (nft) {
        res.json({
            exists: true,
            tokenId: nft.tokenId,
            buildingId: nft.buildingId,
            message: 'NFT found',
            timestamp: nft.timestamp,
            contractAddress: '0x1234567890123456789012345678901234567890'
        });
    } else {
        res.json({
            exists: false,
            message: 'NFT not found'
        });
    }
});

// 启动服务器 - 绑定到所有接口（IPv4和IPv6）
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 NFT API服务已启动: http://0.0.0.0:${PORT}`);
    console.log(`📊 健康检查: http://127.0.0.1:${PORT}/api/health`);
    console.log(`🎨 铸造端点: POST http://127.0.0.1:${PORT}/api/mint-thread`);
    console.log(`🔄 转移端点: POST http://127.0.0.1:${PORT}/api/transfer-nft`);
    console.log(`🌐 支持访问: localhost, 127.0.0.1, 0.0.0.0`);
});
