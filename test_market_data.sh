#!/bin/bash

# 测试Market数据查询的脚本
# 用于验证Supabase数据库中是否有数据

echo "🔍 Testing Market Data Queries..."
echo ""

# 读取配置文件
if [ -f "Config.xcconfig" ]; then
    source <(grep -v '^#' Config.xcconfig | grep '=' | sed 's/ *= */=/g' | sed 's/^/export /')
else
    echo "❌ Config.xcconfig not found!"
    exit 1
fi

echo "📡 Supabase URL: $SUPABASE_URL"
echo "🔑 API Key: ${SUPABASE_ANON_KEY:0:20}..."
echo ""

# 测试1: 查询threads记录数
echo "📊 Test 1: Checking threads table..."
response=$(curl -s \
  "${SUPABASE_URL}/rest/v1/threads?select=building_id,username&limit=5" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}")

record_count=$(echo "$response" | jq '. | length' 2>/dev/null)

if [ "$record_count" = "null" ] || [ -z "$record_count" ]; then
    echo "❌ No records found or query failed"
    echo "Response: $response"
else
    echo "✅ Found $record_count records (showing first 5)"
    echo "$response" | jq '.'
fi

echo ""
echo "📊 Test 2: Counting total records..."
total_response=$(curl -s \
  "${SUPABASE_URL}/rest/v1/threads?select=id" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Prefer: count=exact")

total_count=$(echo "$total_response" | jq '. | length' 2>/dev/null)
echo "Total records in threads: $total_count"

echo ""
echo "📊 Test 3: Sample data with created_at..."
sample_response=$(curl -s \
  "${SUPABASE_URL}/rest/v1/threads?select=building_id,username,created_at&limit=3" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}")

echo "$sample_response" | jq '.'

echo ""
echo "✅ Test complete!"
echo ""
echo "💡 Troubleshooting tips:"
echo "1. If you see errors, check your Supabase URL and API key in Config.xcconfig"
echo "2. If count is 0, you need to create some check-in records first"
echo "3. Check Xcode console for detailed logs when running the app"

