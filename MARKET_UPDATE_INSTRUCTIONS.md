# 🔧 Market功能 - Supabase RPC更新指南

## ⚠️ 重要：必须重新执行SQL文件

由于修复了类型不匹配错误，你需要在Supabase中**重新执行**RPC函数创建脚本。

---

## 📋 执行步骤

### 1️⃣ 打开Supabase Dashboard
访问: https://app.supabase.com

### 2️⃣ 进入SQL Editor
1. 登录并选择你的项目
2. 点击左侧导航栏的 **"SQL Editor"**
3. 点击 **"New query"**

### 3️⃣ 执行更新的SQL
1. 打开项目文件: `MARKET_SUPABASE_RPC.sql`
2. **全选并复制**所有内容（Cmd+A, Cmd+C）
3. 粘贴到Supabase SQL Editor
4. 点击 **"Run"** 按钮

### 4️⃣ 验证函数已更新
执行以下测试查询：

```sql
-- 测试1: 市场统计（应该正常）
SELECT * FROM get_market_stats();

-- 测试2: 热门建筑（应该正常）
SELECT * FROM get_trending_buildings(5);

-- 测试3: 活跃用户（应该正常）
SELECT * FROM get_top_users(5);

-- 测试4: 交易记录（之前报错，现在应该正常）
SELECT * FROM get_most_traded_records(5);
```

**预期结果**:
- 前3个查询应该返回数据（如果有记录的话）
- 第4个查询**不再报错**，会返回数据或空数组（取决于是否有转账记录）

---

## 🐛 修复的问题

### **错误信息**
```
ERROR: 42883: operator does not exist: text = uuid
HINT: No operator matches the given name and argument types. You might need to add explicit type casts.
```

### **根本原因**
- `asset_checkins` 表的 `id` 字段是 **UUID** 类型
- `get_most_traded_records` 函数之前声明返回 **TEXT** 类型
- PostgreSQL无法直接比较 TEXT 和 UUID

### **修复内容**

**之前（错误）**:
```sql
CREATE OR REPLACE FUNCTION get_most_traded_records(...)
RETURNS TABLE (
    id TEXT,  -- ❌ 错误：应该是 UUID
    ...
)
```

**现在（正确）**:
```sql
CREATE OR REPLACE FUNCTION get_most_traded_records(...)
RETURNS TABLE (
    id UUID,  -- ✅ 正确：匹配 asset_checkins.id 的类型
    ...
)
WHERE tr.record_id::text = ac.id::text  -- ✅ 显式类型转换
```

---

## 📊 预期性能提升

执行更新后，Market页面应该：

| 指标 | 更新前 | 更新后 |
|-----|-------|-------|
| 加载速度 | 3-5秒 | **< 1秒** |
| 网络传输 | 下载所有记录 | 只返回结果 |
| Traded Records | ❌ 错误 | ✅ 正常工作 |

---

## ✅ 完成检查清单

- [ ] 在Supabase SQL Editor中执行 `MARKET_SUPABASE_RPC.sql`
- [ ] 运行4个测试查询，确认无错误
- [ ] 重启App，进入Market页面
- [ ] 确认加载速度明显提升
- [ ] 确认"Most Traded"标签可以正常显示（即使是空数据）

---

## 🎉 完成后

Market功能将完全正常工作，所有RPC函数都已优化。如果仍有问题，请检查：

1. **网络连接**: 确保App能访问Supabase
2. **API Key**: 确认 `Config.xcconfig` 中的配置正确
3. **数据存在**: 确认数据库中有 `asset_checkins` 记录

---

**最后更新**: 2025-10-26
**版本**: v1.1 - 修复UUID类型错误

