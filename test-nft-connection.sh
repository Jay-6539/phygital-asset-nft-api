#!/bin/bash

echo "🔍 测试NFT API连接..."

# 测试127.0.0.1
echo "测试 127.0.0.1:3000..."
curl -s -w "HTTP状态码: %{http_code}\n" http://127.0.0.1:3000/api/health

echo ""
echo "测试 localhost:3000..."
curl -s -w "HTTP状态码: %{http_code}\n" http://localhost:3000/api/health

echo ""
echo "测试NFT铸造..."
curl -X POST http://127.0.0.1:3000/api/mint-thread \
  -H "Content-Type: application/json" \
  -d '{
    "threadId": "TEST-123",
    "username": "Test User",
    "buildingId": "Test Building",
    "description": "Test NFT",
    "imageUrl": ""
  }' \
  -w "HTTP状态码: %{http_code}\n"

echo ""
echo "✅ 测试完成"
