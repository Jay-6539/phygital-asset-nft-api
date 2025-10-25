# Market功能调试指南

## ✅ 真实数据已实现

Market功能现在会从Supabase实时查询数据。以下是调试步骤：

## 🔍 第一步：运行App并查看日志

1. 在Xcode中运行App
2. 打开Market页面（点击Asset -> Market按钮）
3. **立即查看Xcode底部的控制台输出**

### 预期看到的日志

```
🔄 Starting to load market data...
📊 Loading stats...
🔥 Loading trending buildings...
👑 Loading top users...
📈 Received stats: X buildings, Y records, Z users
🏛️ Received N trending buildings
👥 Received M top users
🔍 Matching buildings with treasures...
   Buildings to match: N
   Available treasures: M
   Checking building ID: 898
   ⚠️ No treasure found for building ID: 898 - keeping original name
🎯 Final enriched buildings count: N
✅ Market data loaded successfully
```

## 📊 当前Supabase数据状态

根据测试，你的Supabase中有数据：
- Building ID: **898**
- Username: **Garfield**
- 有多条记录

## ❓ 常见问题

### 问题1: 统计数字显示为0

**原因**: 
- 可能是SupabaseManager的配置没有加载
- 或者网络请求失败

**解决方法**:
1. 检查Xcode控制台是否有错误日志
2. 确认Config.xcconfig中的配置正确
3. 重新Build项目 (Cmd+Shift+K clean，然后Cmd+B build)

### 问题2: Trending Buildings是空的

**原因**: 
- Building ID "898" 可能不在app的treasures列表中
- Oval Office的ID在代码中是"900"，但数据库中可能是"898"

**解决方法**:
查看日志中的这一行：
```
⚠️ No treasure found for building ID: 898 - keeping original name
```

如果看到这个警告，说明building ID不匹配。有两个解决方案：

**方案A: 修改数据显示逻辑（已实现）**
- 现在即使building ID不在treasures列表中，也会显示
- 只是显示为"Building 898"而不是真实名称

**方案B: 修复building ID**
- 检查你的check-in记录用的是什么building_id
- 确保与HistoricBuildingsManager中的ID一致

### 问题3: Top Users是空的

**原因**: 同上，数据查询或解析可能有问题

**解决方法**: 查看日志中的详细错误信息

## 🛠️ 调试命令

### 查看Supabase中的实际数据

```bash
cd /Users/Jay/Documents/TreasureHuntHK
./test_market_data.sh
```

### 查看所有building IDs

```bash
curl -s \
  "https://zcaznpjulvmaxjnhvqaw.supabase.co/rest/v1/asset_checkins?select=building_id" \
  -H "apikey: YOUR_API_KEY" \
  -H "Authorization: Bearer YOUR_API_KEY" | jq 'group_by(.building_id) | map({building_id: .[0].building_id, count: length})'
```

## 💡 下一步

1. **运行App，点击Market**
2. **复制Xcode控制台的完整日志**
3. **告诉我看到了什么**，我可以根据日志诊断具体问题

## 🎯 预期结果

如果一切正常，你应该看到：
- **Statistics**: 显示建筑数、记录数、用户数（不为0）
- **Trending tab**: 显示building列表（即使名称是"Building 898"）
- **Top Users tab**: 显示用户列表（包括"Garfield"）

如果这些都是空的或为0，请把Xcode控制台的日志发给我！

