#!/bin/bash

# Phygital Asset NFT系统监控脚本

echo "📊 Phygital Asset NFT系统监控"
echo "=============================="

# 获取当前时间
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "🕐 监控时间: $TIMESTAMP"

echo ""

# 检查API服务状态
echo "📡 API服务监控:"
API_RESPONSE=$(curl -s http://localhost:3000/api/health 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ API服务: 运行正常"
    
    # 提取关键信息
    NETWORK=$(echo $API_RESPONSE | grep -o '"network":"[^"]*"' | cut -d'"' -f4)
    CHAIN_ID=$(echo $API_RESPONSE | grep -o '"chainId":[0-9]*' | cut -d':' -f2)
    TOTAL_SUPPLY=$(echo $API_RESPONSE | grep -o '"totalSupply":"[^"]*"' | cut -d'"' -f4)
    
    echo "📊 网络: $NETWORK (Chain ID: $CHAIN_ID)"
    echo "📊 总供应量: $TOTAL_SUPPLY"
    
    # 检查供应量变化
    if [ -f "last_supply.txt" ]; then
        LAST_SUPPLY=$(cat last_supply.txt)
        if [ "$TOTAL_SUPPLY" != "$LAST_SUPPLY" ]; then
            echo "🆕 检测到新NFT铸造! 从 $LAST_SUPPLY 增加到 $TOTAL_SUPPLY"
        else
            echo "📈 供应量稳定: $TOTAL_SUPPLY"
        fi
    fi
    echo $TOTAL_SUPPLY > last_supply.txt
    
else
    echo "❌ API服务: 未运行或异常"
    echo "💡 启动命令: node nft-api-server-amoy.js"
fi

echo ""

# 检查合约信息
echo "📋 合约监控:"
CONTRACT_INFO=$(curl -s http://localhost:3000/api/contract-info 2>/dev/null)
if [ $? -eq 0 ]; then
    CONTRACT_NAME=$(echo $CONTRACT_INFO | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    CONTRACT_SYMBOL=$(echo $CONTRACT_INFO | grep -o '"symbol":"[^"]*"' | cut -d'"' -f4)
    OWNER=$(echo $CONTRACT_INFO | grep -o '"owner":"[^"]*"' | cut -d'"' -f4)
    
    echo "✅ 合约状态: 正常"
    echo "📊 合约名称: $CONTRACT_NAME ($CONTRACT_SYMBOL)"
    echo "📊 合约拥有者: $OWNER"
else
    echo "❌ 合约查询: 失败"
fi

echo ""

# 系统资源监控
echo "💻 系统资源:"
echo "📊 CPU使用率: $(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')"
echo "📊 内存使用: $(top -l 1 | grep "PhysMem" | awk '{print $2}')"

echo ""

# 网络连接测试
echo "🌐 网络连接测试:"
if curl -s --connect-timeout 5 https://amoy.polygonscan.com > /dev/null; then
    echo "✅ Amoy网络: 连接正常"
else
    echo "❌ Amoy网络: 连接异常"
fi

echo ""

# 显示重要链接
echo "🔗 快速访问:"
echo "📊 合约地址: https://amoy.polygonscan.com/address/0xA0fA27fC547D544528e9BE0cb6569E9B925e533E"
echo "🎨 OpenSea: https://testnets.opensea.io/assets/amoy/0xA0fA27fC547D544528e9BE0cb6569E9B925e533E"

echo ""
echo "🎯 系统状态: 监控完成 ✅"
