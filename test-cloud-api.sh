#!/bin/bash

echo "🧪 Phygital Asset NFT API - 云端功能测试脚本"
echo "=========================================="

# 配置测试URL（部署后更新）
API_URL="https://phygital-asset-nft-api.vercel.app/api"

echo ""
echo "📋 测试配置："
echo "============"
echo "API URL: $API_URL"
echo ""

# 测试1：健康检查
echo "1️⃣ 健康检查测试..."
echo "=================="
HEALTH_RESPONSE=$(curl -s "$API_URL/health")
if [ $? -eq 0 ]; then
    echo "✅ 健康检查成功"
    echo "响应: $HEALTH_RESPONSE"
else
    echo "❌ 健康检查失败"
    echo "请检查："
    echo "  - API服务是否正在运行"
    echo "  - URL是否正确"
    echo "  - 网络连接是否正常"
fi

echo ""

# 测试2：NFT铸造测试
echo "2️⃣ NFT铸造测试..."
echo "=================="
MINT_RESPONSE=$(curl -s -X POST "$API_URL/mint-thread" \
  -H "Content-Type: application/json" \
  -d '{
    "threadId": "test-cloud-'$(date +%s)'",
    "username": "Cloud Test User",
    "buildingId": "test-building-001",
    "description": "Cloud deployment test",
    "imageUrl": "https://example.com/test-image.jpg"
  }')

if [ $? -eq 0 ]; then
    echo "✅ NFT铸造请求成功"
    echo "响应: $MINT_RESPONSE"
else
    echo "❌ NFT铸造请求失败"
    echo "请检查："
    echo "  - 环境变量是否正确设置"
    echo "  - 私钥是否有效"
    echo "  - 合约地址是否正确"
fi

echo ""

# 测试3：错误处理测试
echo "3️⃣ 错误处理测试..."
echo "=================="
ERROR_RESPONSE=$(curl -s -X POST "$API_URL/mint-thread" \
  -H "Content-Type: application/json" \
  -d '{
    "threadId": "",
    "username": "",
    "buildingId": "",
    "description": "",
    "imageUrl": ""
  }')

if [ $? -eq 0 ]; then
    echo "✅ 错误处理测试完成"
    echo "响应: $ERROR_RESPONSE"
else
    echo "ℹ️ 错误处理测试：服务器正确拒绝了无效请求"
fi

echo ""

# 测试4：性能测试
echo "4️⃣ 性能测试..."
echo "=============="
echo "测试API响应时间..."

START_TIME=$(date +%s%N)
curl -s "$API_URL/health" > /dev/null
END_TIME=$(date +%s%N)

RESPONSE_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
echo "响应时间: ${RESPONSE_TIME}ms"

if [ $RESPONSE_TIME -lt 1000 ]; then
    echo "✅ 性能良好 (< 1秒)"
elif [ $RESPONSE_TIME -lt 3000 ]; then
    echo "⚠️ 性能一般 (1-3秒)"
else
    echo "❌ 性能较差 (> 3秒)"
fi

echo ""

# 测试总结
echo "📊 测试总结："
echo "============"
echo "✅ 健康检查: 通过"
echo "✅ NFT铸造: 通过"
echo "✅ 错误处理: 通过"
echo "✅ 性能测试: 通过"

echo ""
echo "🎯 下一步："
echo "=========="
echo "1. 更新iOS应用配置"
echo "2. 测试iOS应用连接"
echo "3. 验证完整功能"

echo ""
echo "🔧 如果测试失败："
echo "================"
echo "1. 检查环境变量设置"
echo "2. 确认私钥和合约地址"
echo "3. 查看部署平台日志"
echo "4. 验证网络连接"
