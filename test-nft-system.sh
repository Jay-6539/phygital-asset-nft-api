#!/bin/bash

# Phygital Asset NFT系统测试脚本
# 测试从合约部署到应用集成的完整流程

echo "🧪 Phygital Asset NFT系统测试"
echo "================================"

# 检查API服务状态
echo "📡 检查API服务状态..."
API_RESPONSE=$(curl -s http://localhost:3000/api/health)
if [ $? -eq 0 ]; then
    echo "✅ API服务运行正常"
    echo "📊 服务信息: $API_RESPONSE"
else
    echo "❌ API服务未运行，请先启动: node nft-api-server-amoy.js"
    exit 1
fi

echo ""

# 测试NFT铸造
echo "🎨 测试NFT铸造功能..."
MINT_RESPONSE=$(curl -s -X POST http://localhost:3000/api/mint-thread \
  -H "Content-Type: application/json" \
  -d '{
    "threadId": "test-system-'$(date +%s)'",
    "username": "System Test User",
    "buildingId": "System Test Building",
    "description": "Testing complete system integration",
    "imageUrl": "https://example.com/system-test.jpg"
  }')

if echo "$MINT_RESPONSE" | grep -q '"success":true'; then
    echo "✅ NFT铸造成功"
    echo "📋 铸造结果: $MINT_RESPONSE"
    
    # 提取Token ID
    TOKEN_ID=$(echo "$MINT_RESPONSE" | grep -o '"tokenId":"[^"]*"' | cut -d'"' -f4)
    echo "🎨 Token ID: $TOKEN_ID"
else
    echo "❌ NFT铸造失败"
    echo "📋 错误信息: $MINT_RESPONSE"
fi

echo ""

# 测试合约信息查询
echo "📊 查询合约信息..."
CONTRACT_INFO=$(curl -s http://localhost:3000/api/contract-info)
if [ $? -eq 0 ]; then
    echo "✅ 合约信息查询成功"
    echo "📋 合约信息: $CONTRACT_INFO"
else
    echo "❌ 合约信息查询失败"
fi

echo ""

# 显示验证链接
echo "🔗 验证链接:"
echo "📊 合约地址: https://amoy.polygonscan.com/address/0xA0fA27fC547D544528e9BE0cb6569E9B925e533E"
echo "🎨 OpenSea测试网: https://testnets.opensea.io/assets/amoy/0xA0fA27fC547D544528e9BE0cb6569E9B925e533E"

echo ""
echo "🎉 系统测试完成！"
echo ""
echo "📋 下一步:"
echo "1. 在iOS应用中创建Thread"
echo "2. 验证NFT自动铸造"
echo "3. 检查区块链交易记录"
echo "4. 在OpenSea上查看NFT"
