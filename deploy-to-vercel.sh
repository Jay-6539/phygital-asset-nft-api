#!/bin/bash

echo "🚀 Phygital Asset NFT API - Vercel部署脚本"
echo "=========================================="

echo ""
echo "📋 部署前检查："
echo "=============="

# 检查必要文件
if [ ! -f "nft-api-server-amoy.js" ]; then
    echo "❌ 错误：找不到 nft-api-server-amoy.js"
    exit 1
fi

if [ ! -f "package.json" ]; then
    echo "❌ 错误：找不到 package.json"
    exit 1
fi

if [ ! -f "vercel.json" ]; then
    echo "❌ 错误：找不到 vercel.json"
    exit 1
fi

echo "✅ 所有必要文件已准备就绪"

echo ""
echo "🔧 准备部署文件："
echo "================"

# 确保package.json正确
echo "📦 检查package.json..."
if ! grep -q "ethers" package.json; then
    echo "⚠️  警告：package.json可能缺少ethers依赖"
fi

echo ""
echo "🌐 开始Vercel部署："
echo "=================="

echo "1️⃣ 登录Vercel..."
echo "请在浏览器中完成登录，然后按Enter继续..."
read -p "按Enter继续..."

echo "2️⃣ 初始化项目..."
npx vercel init --yes

echo "3️⃣ 部署到生产环境..."
npx vercel --prod

echo ""
echo "✅ 部署完成！"
echo "============"
echo "请记录您的部署URL，然后："
echo "1. 在Vercel Dashboard设置环境变量"
echo "2. 更新iOS应用配置"
echo "3. 测试API功能"

echo ""
echo "📋 环境变量设置："
echo "================"
echo "AMOY_RPC_URL=https://rpc-amoy.polygon.technology/"
echo "AMOY_CHAIN_ID=80002"
echo "CONTRACT_ADDRESS=0xA0fA27fC547D544528e9BE0cb6569E9B925e533E"
echo "AMOY_PRIVATE_KEY=你的私钥"
echo "NODE_ENV=production"
