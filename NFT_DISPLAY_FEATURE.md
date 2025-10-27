# 📱 NFT展示功能实现

## 📋 功能概述

为iOS应用添加NFT展示功能，允许用户查看自己拥有的所有NFT。

## 🔧 实现步骤

### 步骤1：更新API服务器
在 `nft-api-server-simple.js` 中添加用户NFT查询端点：

```javascript
// 获取用户NFT列表
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
                contractAddress: '0xA0fA27fC547D544528e9BE0cb6569E9B925e533E'
            },
            {
                tokenId: `NFT-${Date.now()}-2`,
                threadId: 'thread-2',
                buildingId: 'building-2',
                timestamp: new Date().toISOString(),
                contractAddress: '0xA0fA27fC547D544528e9BE0cb6569E9B925e533E'
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

// 获取NFT详情
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
```

### 步骤2：更新NFTManager
在 `NFTManager.swift` 中添加用户NFT查询功能：

```swift
// MARK: - 查询用户NFT
/// 获取用户拥有的所有NFT
func getUserNFTs(username: String) async -> [NFTInfo]? {
    guard isNFTEnabled else { return nil }
    
    do {
        let endpoint = "\(apiURL)/user-nfts/\(username)"
        guard let url = URL(string: endpoint) else { return nil }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        let result = try JSONDecoder().decode(UserNFTsResult.self, from: data)
        
        return result.nfts.map { nft in
            NFTInfo(
                threadId: UUID(uuidString: nft.threadId) ?? UUID(),
                tokenId: nft.tokenId,
                contractAddress: nft.contractAddress,
                buildingId: nft.buildingId,
                timestamp: nft.timestamp
            )
        }
        
    } catch {
        Logger.debug("查询用户NFT失败: \(error)")
        return nil
    }
}

// MARK: - 查询NFT详情
/// 获取特定NFT的详细信息
func getNFTDetail(tokenId: String) async -> NFTDetail? {
    guard isNFTEnabled else { return nil }
    
    do {
        let endpoint = "\(apiURL)/nft/\(tokenId)"
        guard let url = URL(string: endpoint) else { return nil }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        let result = try JSONDecoder().decode(NFTDetailResult.self, from: data)
        
        return NFTDetail(
            tokenId: result.nft.tokenId,
            threadId: result.nft.threadId,
            buildingId: result.nft.buildingId,
            timestamp: result.nft.timestamp,
            contractAddress: result.nft.contractAddress,
            owner: result.nft.owner,
            metadata: result.nft.metadata
        )
        
    } catch {
        Logger.debug("查询NFT详情失败: \(error)")
        return nil
    }
}
```

### 步骤3：创建NFT展示UI
需要创建以下视图：
- `MyNFTsView.swift` - 用户NFT列表
- `NFTDetailView.swift` - NFT详情页面
- `NFTCardView.swift` - NFT卡片组件

### 步骤4：集成到现有功能
- 在Profile页面添加"My NFTs"选项
- 在Market页面添加NFT展示
- 在Thread详情页面显示对应NFT

## 🎯 预期效果

- ✅ 用户可以查看自己的所有NFT
- ✅ NFT详情页面显示完整信息
- ✅ 区块链链接集成
- ✅ 美观的NFT展示界面

## 📱 下一步

1. 更新API服务器添加查询端点
2. 创建NFT展示UI界面
3. 集成到现有功能中
4. 测试展示功能
