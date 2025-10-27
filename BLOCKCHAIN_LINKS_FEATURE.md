# 🔗 区块链链接集成

## 📋 功能概述

为iOS应用添加区块链链接集成，允许用户直接访问区块链信息。

## 🔧 实现步骤

### 步骤1：更新NFTModels
在 `NFTModels.swift` 中，区块链链接已经存在：

```swift
struct NFTInfo {
    let threadId: UUID
    let tokenId: String
    let contractAddress: String
    let buildingId: String?
    let timestamp: String?
    
    var polygonscanURL: URL? {
        // Amoy测试网Polygonscan链接
        URL(string: "https://amoy.polygonscan.com/token/\(contractAddress)?a=\(tokenId)")
    }
    
    var openseaURL: URL? {
        // OpenSea测试网链接
        URL(string: "https://testnets.opensea.io/assets/amoy/\(contractAddress)/\(tokenId)")
    }
}
```

### 步骤2：创建区块链链接UI
需要创建以下组件：
- `BlockchainLinksView.swift` - 区块链链接按钮
- `BlockchainLinkButton.swift` - 单个链接按钮
- `ShareNFTView.swift` - NFT分享功能

### 步骤3：集成到现有功能
- 在NFT详情页面添加区块链链接
- 在Market页面添加分享功能
- 在Thread详情页面显示区块链信息

### 步骤4：添加分享功能
```swift
// 分享NFT
func shareNFT(_ nft: NFTInfo) {
    let activityViewController = UIActivityViewController(
        activityItems: [
            "Check out my NFT: \(nft.tokenId)",
            nft.polygonscanURL ?? "",
            nft.openseaURL ?? ""
        ],
        applicationActivities: nil
    )
    
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        window.rootViewController?.present(activityViewController, animated: true)
    }
}
```

## 🎯 预期效果

- ✅ 用户可以直接访问Polygonscan
- ✅ 用户可以直接访问OpenSea
- ✅ NFT分享功能
- ✅ 完整的区块链集成

## 📱 下一步

1. 创建区块链链接UI组件
2. 集成到现有功能中
3. 测试链接功能
4. 优化用户体验
