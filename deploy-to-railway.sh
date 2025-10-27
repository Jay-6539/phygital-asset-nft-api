#!/bin/bash

echo "🚀 Phygital Asset NFT API - Railway部署脚本"
echo "=========================================="

echo ""
echo "📋 Railway部署步骤："
echo "=================="

echo "1️⃣ 访问Railway网站"
echo "   https://railway.app"
echo "   使用GitHub账号登录"

echo ""
echo "2️⃣ 创建新项目"
echo "   - 点击 'New Project'"
echo "   - 选择 'Deploy from GitHub repo'"
echo "   - 选择您的仓库"

echo ""
echo "3️⃣ 配置环境变量"
echo "   在Railway Dashboard的Variables标签页添加："
echo "   AMOY_RPC_URL=https://rpc-amoy.polygon.technology/"
echo "   AMOY_CHAIN_ID=80002"
echo "   CONTRACT_ADDRESS=0xA0fA27fC547D544528e9BE0cb6569E9B925e533E"
echo "   AMOY_PRIVATE_KEY=你的私钥"
echo "   NODE_ENV=production"

echo ""
echo "4️⃣ 部署"
echo "   - Railway会自动检测package.json"
echo "   - 自动安装依赖"
echo "   - 自动启动服务"

echo ""
echo "5️⃣ 获取部署URL"
echo "   - 部署完成后，Railway会提供一个URL"
echo "   - 类似：https://phygital-asset-nft-api-production.up.railway.app"

echo ""
echo "✅ Railway优势："
echo "==============="
echo "✅ 免费额度充足"
echo "✅ 部署简单快速"
echo "✅ 自动HTTPS"
echo "✅ 环境变量管理"
echo "✅ 实时日志"

echo ""
echo "🔧 准备部署文件..."
echo "=================="

# 检查必要文件
if [ ! -f "nft-api-server-amoy.js" ]; then
    echo "❌ 错误：找不到 nft-api-server-amoy.js"
    exit 1
fi

if [ ! -f "package.json" ]; then
    echo "❌ 错误：找不到 package.json"
    exit 1
fi

echo "✅ 部署文件准备就绪"

echo ""
echo "📱 部署完成后，更新iOS应用："
echo "============================="
echo "在NFTManager.swift中更新API URL："
echo ""
echo "private let apiURL: String = {"
echo "    #if DEBUG"
echo "    return \"http://127.0.0.1:3000/api\"  // 开发环境"
echo "    #else"
echo "    return \"https://your-railway-url.up.railway.app/api\"  // 生产环境"
echo "    #endif"
echo "}()"

echo ""
echo "🚀 现在去Railway开始部署吧！"
