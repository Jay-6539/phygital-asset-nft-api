# 数据库命名兼容性指南

## 🎯 概述

本文档说明数据库层面的命名策略，确保命名规范统一的同时，保持应用与Supabase的兼容性。

## 📊 命名映射关系

### 概念层（用户可见）
| 新概念 | 旧概念 | 说明 |
|--------|--------|------|
| **Building** | Building | 地图上的建筑点（不变）|
| **Thread** | Check-in | 用户在NFC上的记录 |
| **Echo** | Credit | 用户的代币 |
| **XP** | - | 用户的经验值（新增）|

### 数据库层（Supabase）
| 表名 | 存储内容 | 是否更改 |
|------|---------|---------|
| `asset_checkins` | Building的Thread记录 | ❌ 保持不变 |
| `oval_office_checkins` | Oval Office的Thread记录 | ❌ 保持不变 |
| `bids` | Thread的竞价记录 | ❌ 保持不变 |
| `transfer_requests` | Thread的转让请求 | ❌ 保持不变 |
| `user_xp` | 用户XP和等级 | ✅ 新表 |

### 字段层（Supabase）
| 表 | 字段名 | 含义 | 是否更改 |
|----|--------|------|---------|
| `bids` | `bid_amount` | 出价的Echo数量 | ❌ 保持不变 |
| `bids` | `counter_amount` | 反价的Echo数量 | ❌ 保持不变 |
| `bids` | `record_id` | Thread记录ID | ❌ 保持不变 |
| `asset_checkins` | `username` | Thread创建者 | ❌ 保持不变 |
| `asset_checkins` | `asset_name` | Thread资产名 | ❌ 保持不变 |

## 🔄 迁移策略

### 方案：仅更新注释，不更改表结构

**优点**：
- ✅ 零停机时间
- ✅ 无需修改应用代码
- ✅ 向后兼容
- ✅ 现有数据完全保留
- ✅ 现有查询继续工作

**实施**：
- 更新表注释（COMMENT ON TABLE）
- 更新字段注释（COMMENT ON COLUMN）
- 更新文档说明
- 应用层使用新术语

## 📝 SQL迁移脚本

执行 `DATABASE_NAMING_MIGRATION.sql` 脚本，该脚本会：

1. 更新 `asset_checkins` 表注释为"Thread记录表"
2. 更新 `oval_office_checkins` 表注释为"Oval Office Thread记录表"
3. 更新 `bids` 表中Echo相关字段的注释
4. 更新 `transfer_requests` 表中Thread相关的注释
5. 确认 `user_xp` 表注释正确

## 🔍 表结构说明

### 1. asset_checkins（Building Thread记录）
**表名保留原因**: 
- "asset"代表资产，符合Thread的概念
- "checkins"虽然是旧术语，但在数据库层面可以理解为"记录"
- 修改表名需要大量代码改动和数据迁移，风险高

**字段映射**:
```sql
id              → Thread ID (UUID)
building_id     → Building ID
username        → Thread创建者
asset_name      → Thread资产名称
description     → Thread描述
image_url       → Thread图片
nfc_uuid        → NFC位置标识
created_at      → Thread创建时间
```

### 2. oval_office_checkins（Oval Office Thread记录）
**表名保留原因**: 同上

**字段映射**:
```sql
id              → Thread ID (UUID)
username        → Thread创建者
asset_name      → Thread资产名称
description     → Thread描述
image_url       → Thread图片
created_at      → Thread创建时间
```

### 3. bids（Thread竞价表）
**表名保留原因**: "bids"是通用术语，不需要改

**字段映射**:
```sql
record_id       → Thread ID (关联asset_checkins或oval_office_checkins)
bid_amount      → 出价的Echo数量
counter_amount  → 反价的Echo数量
```

### 4. transfer_requests（Thread转让表）
**表名保留原因**: "transfer_requests"是通用术语

**字段映射**:
```sql
record_id       → Thread ID
record_type     → Thread类型
```

### 5. user_xp（用户XP表）
**表名**: 已经是正确的命名 ✅

## 🔗 应用层连接

### Swift代码中的表名引用
所有查询保持不变，例如：
```swift
// ✅ 继续使用原表名
let url = "\(baseURL)/rest/v1/asset_checkins?..."
let url = "\(baseURL)/rest/v1/oval_office_checkins?..."
let url = "\(baseURL)/rest/v1/bids?..."
```

### 字段名引用
所有字段名保持不变：
```swift
// ✅ 继续使用原字段名
"username": username,
"asset_name": assetName,
"bid_amount": bidAmount,
"counter_amount": counterAmount
```

## ✅ 执行步骤

### 1. 备份数据库
```sql
-- 在执行任何更改前，建议在Supabase Dashboard中创建备份
```

### 2. 执行迁移脚本
在Supabase SQL Editor中执行：
```bash
DATABASE_NAMING_MIGRATION.sql
```

### 3. 验证更新
检查表注释：
```sql
-- 查看表注释
SELECT 
    schemaname,
    tablename,
    obj_description((schemaname||'.'||tablename)::regclass, 'pg_class') as comment
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('asset_checkins', 'oval_office_checkins', 'bids', 'transfer_requests', 'user_xp');

-- 查看字段注释
SELECT 
    cols.column_name,
    pg_catalog.col_description((schemaname||'.'||tablename)::regclass::oid, cols.ordinal_position) as comment
FROM information_schema.columns cols
JOIN pg_tables t ON t.tablename = cols.table_name
WHERE cols.table_name = 'bids'
AND cols.column_name IN ('bid_amount', 'counter_amount', 'record_id');
```

### 4. 测试应用
- ✅ 启动应用
- ✅ 测试Thread创建
- ✅ 测试Bid功能
- ✅ 测试Echo转账
- ✅ 测试XP获取
- ✅ 测试Market数据加载

## 🚨 重要提醒

### 不要做的事情
- ❌ 不要重命名表（asset_checkins → thread_records）
- ❌ 不要重命名字段（bid_amount → echo_amount）
- ❌ 不要删除现有数据
- ❌ 不要修改索引名称

### 应该做的事情
- ✅ 只更新注释（COMMENT ON）
- ✅ 保持所有表结构不变
- ✅ 保持所有字段名不变
- ✅ 保持所有索引不变
- ✅ 更新文档说明

## 📚 术语对照表

### 数据库层面（技术名称）
```
asset_checkins        = Thread存储表
building_id           = Building标识
bid_amount            = Echo出价金额
record_id             = Thread记录ID
```

### 应用层面（业务名称）
```
asset_checkins 记录   = Thread
building_id           = Building
bid_amount            = Echo amount
record_id             = Thread ID
```

### UI显示（用户可见）
```
Thread                = Thread
Building              = Building
Echo                  = Echo
XP                    = XP
```

## 🎯 总结

- **数据库**: 表名和字段名保持不变（技术稳定性）
- **注释**: 更新为新术语（文档清晰性）
- **应用**: UI和代码使用新术语（用户体验）
- **兼容**: 零破坏性迁移（安全可靠）

执行 `DATABASE_NAMING_MIGRATION.sql` 后，数据库文档将与应用层命名保持一致，同时不会破坏任何现有功能。

## 更新日期
2025-10-27

