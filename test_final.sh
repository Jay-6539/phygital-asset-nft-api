#!/bin/bash

SUPABASE_URL="https://zcaznpjulvmaxjnhvqaw.supabase.co"
API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpjYXpucGp1bHZtYXhqbmh2cWF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzMzI2MjEsImV4cCI6MjA3NTkwODYyMX0.W6NzDWwkrq5tBDA929XXY6AOGgg6DVxM0GcRDq5WTL4"

echo "🔍 测试表名: threads (全小写)"
echo "===================================="
echo ""

echo "📖 测试读取"
curl -s -X GET \
  "${SUPABASE_URL}/rest/v1/threads?select=*" \
  -H "apikey: ${API_KEY}" \
  -H "Authorization: Bearer ${API_KEY}"

echo ""
echo ""
echo "✅ 如果看到 [] 或数据数组 = 成功！"
