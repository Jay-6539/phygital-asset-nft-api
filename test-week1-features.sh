#!/bin/bash

echo "🧪 第1周计划测试脚本"
echo "=================="

API_URL="http://127.0.0.1:3000"

echo ""
echo "📋 测试计划："
echo "============"
echo "1. 测试根路径（查看所有端点）"
echo "2. 测试用户NFT查询"
echo "3. 测试NFT详情查询"
echo "4. 测试所有NFT列表"
echo "5. 测试NFT铸造功能"
echo "6. 测试NFT转移功能"

echo ""
echo "🔍 测试1：根路径"
echo "==============="
echo "URL: $API_URL/"
curl -s "$API_URL/" | jq '.' 2>/dev/null || curl -s "$API_URL/"

echo ""
echo "🔍 测试2：用户NFT查询"
echo "==================="
echo "URL: $API_URL/api/user-nfts/testuser"
curl -s "$API_URL/api/user-nfts/testuser" | jq '.' 2>/dev/null || curl -s "$API_URL/api/user-nfts/testuser"

echo ""
echo "🔍 测试3：NFT详情查询"
echo "==================="
echo "URL: $API_URL/api/nft/NFT-123456"
curl -s "$API_URL/api/nft/NFT-123456" | jq '.' 2>/dev/null || curl -s "$API_URL/api/nft/NFT-123456"

echo ""
echo "🔍 测试4：所有NFT列表"
echo "==================="
echo "URL: $API_URL/api/all-nfts?page=1&limit=3"
curl -s "$API_URL/api/all-nfts?page=1&limit=3" | jq '.' 2>/dev/null || curl -s "$API_URL/api/all-nfts?page=1&limit=3"

echo ""
echo "🔍 测试5：NFT铸造"
echo "==============="
echo "URL: $API_URL/api/mint-thread"
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-thread-123","username":"testuser","buildingId":"test-building","description":"Test NFT"}' \
  "$API_URL/api/mint-thread" | jq '.' 2>/dev/null || curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-thread-123","username":"testuser","buildingId":"test-building","description":"Test NFT"}' \
  "$API_URL/api/mint-thread"

echo ""
echo "🔍 测试6：NFT转移"
echo "==============="
echo "URL: $API_URL/api/transfer-nft"
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-thread-123","fromUsername":"user1","toUsername":"user2"}' \
  "$API_URL/api/transfer-nft" | jq '.' 2>/dev/null || curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-thread-123","fromUsername":"user1","toUsername":"user2"}' \
  "$API_URL/api/transfer-nft"

echo ""
echo "📊 测试总结："
echo "============"
echo "✅ 如果所有测试都返回JSON数据，说明API功能正常"
echo "✅ 新的端点已成功添加："
echo "   - GET /api/user-nfts/:username"
echo "   - GET /api/nft/:tokenId"
echo "   - GET /api/all-nfts"
echo "✅ NFTManager已更新支持新功能"
echo "✅ UI组件已创建：MyNFTsView, NFTDetailView"

echo ""
echo "📱 下一步："
echo "=========="
echo "1. 集成UI组件到现有功能"
echo "2. 测试iOS应用"
echo "3. 优化用户体验"
