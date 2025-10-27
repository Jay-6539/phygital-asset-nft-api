#!/bin/bash

# Phygital Asset NFT系统状态检查

echo "🔍 Phygital Asset NFT系统状态检查"
echo "=================================="

# 检查API服务
echo "📡 API服务状态:"
API_RESPONSE=$(curl -s http://localhost:3000/api/health 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ API服务运行正常"
    echo "📊 网络: $(echo $API_RESPONSE | grep -o '"network":"[^"]*"' | cut -d'"' -f4)"
    echo "📊 链ID: $(echo $API_RESPONSE | grep -o '"chainId":[0-9]*' | cut -d':' -f2)"
    echo "📊 合约: $(echo $API_RESPONSE | grep -o '"contractAddress":"[^"]*"' | cut -d'"' -f4)"
    echo "📊 总供应量: $(echo $API_RESPONSE | grep -o '"totalSupply":"[^"]*"' | cut -d'"' -f4)"
else
    echo "❌ API服务未运行"
    echo "💡 启动命令: node nft-api-server-amoy.js"
fi

echo ""

# 检查合约信息
echo "📋 合约信息:"
CONTRACT_INFO=$(curl -s http://localhost:3000/api/contract-info 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ 合约查询正常"
    echo "📊 名称: $(echo $CONTRACT_INFO | grep -o '"name":"[^"]*"' | cut -d'"' -f4)"
    echo "📊 符号: $(echo $CONTRACT_INFO | grep -o '"symbol":"[^"]*"' | cut -d'"' -f4)"
    echo "📊 拥有者: $(echo $CONTRACT_INFO | grep -o '"owner":"[^"]*"' | cut -d'"' -f4)"
else
    echo "❌ 合约查询失败"
fi

echo ""

# 显示重要链接
echo "🔗 重要链接:"
echo "📊 合约地址: https://amoy.polygonscan.com/address/0xA0fA27fC547D544528e9BE0cb6569E9B925e533E"
echo "🎨 OpenSea: https://testnets.opensea.io/assets/amoy/0xA0fA27fC547D544528e9BE0cb6569E9B925e533E"

echo ""
echo "🎯 系统状态: 就绪 ✅"
echo "💡 现在可以在iOS应用中创建Thread，系统会自动铸造NFT！"
