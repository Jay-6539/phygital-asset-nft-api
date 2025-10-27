#!/bin/bash

# 测试查询threads记录是否存在
# 用法: ./test_asset_query.sh <record_id>

RECORD_ID=${1:-"9770E373-FC8F-4D79-868C-4C02F8B0E443"}

# 从Config.xcconfig读取配置
SUPABASE_URL=$(grep "SUPABASE_URL" Config.xcconfig | cut -d'=' -f2 | tr -d ' ')
SUPABASE_KEY=$(grep "SUPABASE_ANON_KEY" Config.xcconfig | cut -d'=' -f2 | tr -d ' ')

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 查询 threads 记录"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Record ID: $RECORD_ID"
echo ""

# 尝试不同的UUID格式
echo "━━━ 尝试1: 大写UUID ━━━"
UPPERCASE_ID=$(echo "$RECORD_ID" | tr '[:lower:]' '[:upper:]')
echo "🔗 URL: $SUPABASE_URL/rest/v1/threads?id=eq.$UPPERCASE_ID"
curl -s "$SUPABASE_URL/rest/v1/threads?id=eq.$UPPERCASE_ID" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" | jq '.'

echo ""
echo "━━━ 尝试2: 小写UUID ━━━"
LOWERCASE_ID=$(echo "$RECORD_ID" | tr '[:upper:]' '[:lower:]')
echo "🔗 URL: $SUPABASE_URL/rest/v1/threads?id=eq.$LOWERCASE_ID"
curl -s "$SUPABASE_URL/rest/v1/threads?id=eq.$LOWERCASE_ID" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" | jq '.'

echo ""
echo "━━━ 尝试3: 查询所有记录的ID（前5条）━━━"
echo "🔗 URL: $SUPABASE_URL/rest/v1/threads?select=id,username,asset_name&limit=5"
curl -s "$SUPABASE_URL/rest/v1/threads?select=id,username,asset_name&limit=5" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" | jq '.'

echo ""
echo "━━━ 尝试4: 查询属于Garfield的记录 ━━━"
curl -s "$SUPABASE_URL/rest/v1/threads?username=eq.Garfield&select=id,username,asset_name" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" | jq '.'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

