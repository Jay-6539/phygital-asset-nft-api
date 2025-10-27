#!/bin/bash

echo "🧪 Vercel API测试脚本"
echo "===================="

API_URL="https://phygital-asset-nft-k0l8bbict-jay-6539s-projects.vercel.app"

echo ""
echo "📋 测试计划："
echo "============"
echo "1. 测试根路径"
echo "2. 测试健康检查端点"
echo "3. 测试NFT铸造端点"
echo "4. 测试合约信息端点"

echo ""
echo "🔍 测试1：根路径"
echo "==============="
echo "URL: $API_URL/"
curl -s -w "\nHTTP状态码: %{http_code}\n" "$API_URL/" | head -5

echo ""
echo "🔍 测试2：健康检查"
echo "================="
echo "URL: $API_URL/api/health"
curl -s -w "\nHTTP状态码: %{http_code}\n" "$API_URL/api/health" | head -5

echo ""
echo "🔍 测试3：合约信息"
echo "================="
echo "URL: $API_URL/api/contract-info"
curl -s -w "\nHTTP状态码: %{http_code}\n" "$API_URL/api/contract-info" | head -5

echo ""
echo "🔍 测试4：NFT铸造（POST）"
echo "======================="
echo "URL: $API_URL/api/mint-thread"
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-vercel","username":"Vercel Test"}' \
  -w "\nHTTP状态码: %{http_code}\n" \
  "$API_URL/api/mint-thread" | head -5

echo ""
echo "📊 测试总结："
echo "============"
echo "✅ 如果HTTP状态码是200，说明API工作正常"
echo "✅ 如果HTTP状态码是401/403，说明需要身份验证"
echo "✅ iOS应用应该可以正常工作（不受浏览器限制影响）"

echo ""
echo "📱 下一步："
echo "=========="
echo "1. 在iOS模拟器中运行应用"
echo "2. 创建一个新的Thread"
echo "3. 检查控制台日志"
echo "4. 验证NFT铸造功能"
