#!/bin/bash

# Phygital Asset NFT合约快速部署脚本
# 用于将NFT铸造功能迁移到Amoy测试网

echo "🚀 Phygital Asset NFT合约部署脚本"
echo "=================================="

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js未安装，请先安装Node.js"
    exit 1
fi

# 检查npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm未安装，请先安装npm"
    exit 1
fi

echo "✅ Node.js和npm已安装"

# 创建合约项目目录
if [ ! -d "phygital-nft-contract" ]; then
    echo "📁 创建合约项目目录..."
    mkdir phygital-nft-contract
fi

cd phygital-nft-contract

# 初始化项目
if [ ! -f "package.json" ]; then
    echo "📦 初始化项目..."
    npm init -y
fi

# 安装依赖
echo "📥 安装依赖包..."
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npm install @openzeppelin/contracts dotenv

# 初始化Hardhat
if [ ! -d "contracts" ]; then
    echo "🔧 初始化Hardhat..."
    npx hardhat init
fi

# 复制合约文件
echo "📋 复制合约文件..."
cp ../contracts/PhygitalAssetNFT.sol ./contracts/
cp ../scripts/deploy.js ./scripts/
cp ../hardhat.config.js ./
cp ../package-contract.json ./package.json

# 创建环境变量文件
if [ ! -f ".env" ]; then
    echo "⚙️  创建环境变量文件..."
    cp ../env-template.txt ./.env
    echo "📝 请编辑 .env 文件，填入您的钱包私钥"
fi

echo ""
echo "🎉 项目设置完成！"
echo ""
echo "📋 下一步操作："
echo "1. 编辑 .env 文件，填入您的钱包私钥"
echo "2. 从水龙头获取测试MATIC: https://faucet.polygon.technology/"
echo "3. 运行部署命令: npm run deploy:amoy"
echo ""
echo "🔗 有用的链接："
echo "- Amoy水龙头: https://faucet.polygon.technology/"
echo "- Amoy浏览器: https://amoy.polygonscan.com/"
echo "- OpenZeppelin文档: https://docs.openzeppelin.com/contracts/"
echo ""
echo "⚠️  安全提醒："
echo "- 只使用测试钱包"
echo "- 不要将私钥提交到代码库"
echo "- 确保.env文件在.gitignore中"
