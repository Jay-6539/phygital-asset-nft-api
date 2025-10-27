# 应用代码迁移指南 - 表名更新

## 📋 需要更新的代码

执行完 `DATABASE_MIGRATION_COMPLETE.sql` 后，需要更新以下Swift代码中的表名引用。

## 🔍 表名映射

| 旧表名 | 新表名 | 用途 |
|--------|--------|------|
| `asset_checkins` | `threads` | Building的Thread记录 |
| `oval_office_checkins` | `oval_office_threads` | Oval Office的Thread记录 |
| `bids` | `bids` | 保持不变 |
| `transfer_requests` | `transfer_requests` | 保持不变 |
| `user_xp` | `user_xp` | 保持不变 |

## 📝 需要更新的文件清单

基于代码搜索，需要更新以下文件中的表名引用：

### 1. BuildingCheckInManager.swift
```swift
// 查找并替换所有 "asset_checkins" → "threads"
private let tableName = "threads"  // 之前是 "asset_checkins"
```

### 2. OvalOfficeCheckInManager.swift
```swift
// 查找并替换所有 "oval_office_checkins" → "oval_office_threads"
private let tableName = "oval_office_threads"  // 之前是 "oval_office_checkins"
```

### 3. BidManager.swift
```swift
// 更新表名引用
let tableName = bid.recordType == "building" ? "threads" : "oval_office_threads"
// 之前是：bid.recordType == "building" ? "asset_checkins" : "oval_office_checkins"
```

### 4. MarketDataManager.swift
```swift
// 更新所有查询中的表名
endpoint: "threads?select=building_id,username"
// 之前是："asset_checkins?select=building_id,username"
```

### 5. TransferManager.swift
```swift
// 更新表名引用
let tableName = recordType == "building" ? "threads" : "oval_office_threads"
```

### 6. Views文件（查询相关）
- MyHistoryView.swift
- AssetHistoryModal.swift
- BuildingHistoryView.swift
- 其他包含表名查询的View文件

## 🔄 自动化更新脚本

建议使用全局搜索替换：

### 替换规则
```
"asset_checkins"         → "threads"
'asset_checkins'         → 'threads'
asset_checkins           → threads (在字符串中)

"oval_office_checkins"   → "oval_office_threads"
'oval_office_checkins'   → 'oval_office_threads'
oval_office_checkins     → oval_office_threads (在字符串中)
```

## ⚠️ 注意事项

### 不要替换的地方
- 注释中的历史说明
- 文档中的迁移说明
- 备份表名引用

### 需要特别检查的地方
- URL字符串拼接
- SQL查询语句
- RPC函数调用
- 日志输出信息

## 📊 验证清单

迁移后需要测试：

- [ ] Thread创建（Building）
- [ ] Thread创建（Oval Office）
- [ ] Thread历史查询
- [ ] Thread所有权转移（Bid完成时）
- [ ] Thread转让功能
- [ ] Market数据统计
- [ ] NFC扫描记录
- [ ] 用户历史记录

## 🎯 迁移步骤总览

### 步骤1：数据库迁移（Supabase）
```sql
-- 执行 DATABASE_MIGRATION_COMPLETE.sql
```

### 步骤2：代码更新（Xcode）
```
1. 全局搜索 "asset_checkins"
2. 替换为 "threads"
3. 全局搜索 "oval_office_checkins"
4. 替换为 "oval_office_threads"
5. 编译并修复任何错误
```

### 步骤3：测试验证
```
1. 运行应用
2. 测试所有Thread相关功能
3. 检查日志输出
4. 验证数据正确性
```

### 步骤4：清理（可选）
```sql
-- 确认运行正常后，删除旧表备份
-- DROP TABLE IF EXISTS asset_checkins_backup_20251027;
-- DROP TABLE IF EXISTS oval_office_checkins_backup_20251027;
```

## 📝 更新记录模板

迁移完成后，记录以下信息：

```
迁移日期: 2025-10-27
数据库版本: v2.0
迁移的记录数:
  - threads: ___ 条
  - oval_office_threads: ___ 条
  
应用版本: ___
测试状态: [ ] 通过 / [ ] 失败
回滚状态: [ ] 不需要 / [ ] 已回滚
```

## 🔙 回滚方案

如果迁移出现问题，可以快速回滚：

### 数据库回滚
```sql
-- 删除新表
DROP TABLE IF EXISTS threads;
DROP TABLE IF EXISTS oval_office_threads;

-- 恢复旧表（如果重命名了）
ALTER TABLE asset_checkins_backup_20251027 RENAME TO asset_checkins;
ALTER TABLE oval_office_checkins_backup_20251027 RENAME TO oval_office_checkins;
```

### 代码回滚
```
git revert <commit_hash>
```

## 更新日期
2025-10-27

