const { ethers } = require("hardhat");

async function main() {
    console.log("🚀 开始部署Phygital Asset NFT合约到Amoy测试网...");
    
    // 获取部署者账户
    const [deployer] = await ethers.getSigners();
    console.log("📝 部署账户:", deployer.address);
    
    // 检查账户余额
    const balance = await deployer.provider.getBalance(deployer.address);
    console.log("💰 账户余额:", ethers.formatEther(balance), "MATIC");
    
    if (balance < ethers.parseEther("0.01")) {
        console.log("⚠️  余额不足，请从水龙头获取测试MATIC");
        console.log("🔗 水龙头地址: https://faucet.polygon.technology/");
        return;
    }
    
    // 部署合约
    console.log("📦 正在部署合约...");
    const PhygitalAssetNFT = await ethers.getContractFactory("PhygitalAssetNFT");
    const nft = await PhygitalAssetNFT.deploy();
    
    console.log("⏳ 等待合约部署确认...");
    await nft.waitForDeployment();
    
    const contractAddress = await nft.getAddress();
    
    console.log("✅ 合约部署成功!");
    console.log("📍 合约地址:", contractAddress);
    console.log("🔗 交易哈希:", nft.deploymentTransaction().hash);
    
    // 验证合约信息
    console.log("\n📊 合约信息:");
    const contractInfo = await nft.getContractInfo();
    console.log("  名称:", contractInfo.contractName);
    console.log("  符号:", contractInfo.contractSymbol);
    console.log("  总供应量:", contractInfo.totalSupplyCount.toString());
    console.log("  拥有者:", contractInfo.contractOwner);
    
    // 测试铸造功能
    console.log("\n🧪 测试铸造功能...");
    try {
        const testThreadId = "test-thread-" + Date.now();
        const tx = await nft.mintThread(
            testThreadId,
            "Test User",
            "Test Building",
            "Test Description",
            "https://example.com/image.jpg"
        );
        
        console.log("📝 测试铸造交易:", tx.hash);
        const receipt = await tx.wait();
        console.log("✅ 测试铸造成功!");
        
        // 获取Token ID
        const tokenId = await nft.getTokenIdByThreadId(testThreadId);
        console.log("🎨 Token ID:", tokenId.toString());
        
        // 获取元数据
        const metadata = await nft.getThreadMetadata(tokenId);
        console.log("📋 元数据:");
        console.log("  Thread ID:", metadata.threadId);
        console.log("  用户名:", metadata.username);
        console.log("  建筑ID:", metadata.buildingId);
        console.log("  描述:", metadata.description);
        console.log("  图片URL:", metadata.imageUrl);
        console.log("  创建时间:", new Date(Number(metadata.createdAt) * 1000).toISOString());
        
    } catch (error) {
        console.log("❌ 测试铸造失败:", error.message);
    }
    
    console.log("\n🎉 部署完成!");
    console.log("📋 下一步:");
    console.log("1. 将合约地址添加到环境变量: CONTRACT_ADDRESS=" + contractAddress);
    console.log("2. 更新API服务配置");
    console.log("3. 在Amoy Polygonscan查看合约: https://amoy.polygonscan.com/address/" + contractAddress);
    console.log("4. 测试NFT铸造功能");
    
    // 保存部署信息到文件
    const fs = require('fs');
    const deploymentInfo = {
        contractAddress: contractAddress,
        deployer: deployer.address,
        transactionHash: nft.deploymentTransaction().hash,
        timestamp: new Date().toISOString(),
        network: "amoy"
    };
    
    fs.writeFileSync('deployment-info.json', JSON.stringify(deploymentInfo, null, 2));
    console.log("💾 部署信息已保存到 deployment-info.json");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ 部署失败:", error);
        process.exit(1);
    });
