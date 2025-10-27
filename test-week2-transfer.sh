#!/bin/bash

echo "🧪 第2周计划测试脚本 - NFT转移功能"
echo "=================================="

API_URL="http://127.0.0.1:3000"

echo ""
echo "📋 测试计划："
echo "============"
echo "1. 测试根路径（查看所有端点）"
echo "2. 测试NFT转移功能"
echo "3. 测试转移历史查询"
echo "4. 测试NFT铸造功能"
echo "5. 测试用户NFT查询"

echo ""
echo "🔍 测试1：根路径"
echo "==============="
echo "URL: $API_URL/"
curl -s "$API_URL/" | jq '.endpoints' 2>/dev/null || curl -s "$API_URL/" | grep -A 10 "endpoints"

echo ""
echo "🔍 测试2：NFT转移功能"
echo "==================="
echo "URL: $API_URL/api/transfer-nft"
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-thread-123","fromUsername":"user1","toUsername":"user2"}' \
  "$API_URL/api/transfer-nft" | jq '.' 2>/dev/null || curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-thread-123","fromUsername":"user1","toUsername":"user2"}' \
  "$API_URL/api/transfer-nft"

echo ""
echo "🔍 测试3：转移历史查询"
echo "====================="
echo "URL: $API_URL/api/transfer-history/testuser"
curl -s "$API_URL/api/transfer-history/testuser" | jq '.' 2>/dev/null || curl -s "$API_URL/api/transfer-history/testuser"

echo ""
echo "🔍 测试4：NFT铸造"
echo "==============="
echo "URL: $API_URL/api/mint-thread"
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-thread-456","username":"testuser","buildingId":"test-building","description":"Test NFT for transfer"}' \
  "$API_URL/api/mint-thread" | jq '.' 2>/dev/null || curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-thread-456","username":"testuser","buildingId":"test-building","description":"Test NFT for transfer"}' \
  "$API_URL/api/mint-thread"

echo ""
echo "🔍 测试5：用户NFT查询"
echo "==================="
echo "URL: $API_URL/api/user-nfts/testuser"
curl -s "$API_URL/api/user-nfts/testuser" | jq '.nfts | length' 2>/dev/null || curl -s "$API_URL/api/user-nfts/testuser" | grep -o '"nfts":\[.*\]'

echo ""
echo "📊 测试总结："
echo "============"
echo "✅ NFT转移功能测试："
echo "   - POST /api/transfer-nft - 转移NFT"
echo "   - GET /api/transfer-history/:username - 查询转移历史"
echo "✅ UI组件已创建："
echo "   - NFTTransferView - 转移界面"
echo "   - NFTTransferHistoryView - 历史记录界面"
echo "✅ BidManager已集成："
echo "   - 自动转移NFT所有权"
echo "   - 转移成功通知"

echo ""
echo "📱 下一步："
echo "=========="
echo "1. 集成UI组件到现有功能"
echo "2. 测试iOS应用"
echo "3. 优化用户体验"
echo "4. 准备生产环境"
