# 数据库迁移执行计划

## 🎯 迁移目标

将数据库表名从旧命名规范更新为新命名规范，为未来的NFT铸造功能做准备。

## 📊 迁移内容

### 表名更新
| 旧表名 | 新表名 | 状态 |
|--------|--------|------|
| `asset_checkins` | `threads` | ✅ 需要迁移 |
| `oval_office_checkins` | `oval_office_threads` | ✅ 需要迁移 |
| `bids` | `bids` | ✅ 保持不变 |
| `transfer_requests` | `transfer_requests` | ✅ 保持不变 |
| `user_xp` | `user_xp` | ✅ 已是新命名 |

### Storage Bucket
| 旧Bucket名 | 新Bucket名 | 建议 |
|-----------|-----------|------|
| `asset_checkin_images` | `thread_images` | 代码已更新 |
| `oval_office_images` | `oval_office_thread_images` | 代码已更新 |

## 🚀 执行步骤

### 第一步：数据库迁移（Supabase）

#### 1.1 备份现有数据
在Supabase Dashboard:
- Settings → Database → Create Backup
- 或使用pg_dump备份

#### 1.2 执行迁移SQL
在Supabase SQL Editor中执行：
```sql
-- 复制 DATABASE_MIGRATION_COMPLETE.sql 的全部内容
-- 粘贴并执行
```

#### 1.3 验证数据迁移
检查数据完整性：
```sql
-- 检查记录数是否匹配
SELECT COUNT(*) FROM asset_checkins;  -- 旧表
SELECT COUNT(*) FROM threads;         -- 新表（应该相等）

SELECT COUNT(*) FROM oval_office_checkins;  -- 旧表
SELECT COUNT(*) FROM oval_office_threads;   -- 新表（应该相等）

-- 随机抽查几条记录
SELECT * FROM threads LIMIT 5;
SELECT * FROM oval_office_threads LIMIT 5;
```

### 第二步：Storage Bucket设置（Supabase Dashboard）

#### 2.1 创建新Bucket
1. 进入 Storage → Buckets
2. 创建 `thread_images`
   - Public bucket: ✅
   - File size limit: 5MB
   - Allowed MIME types: image/jpeg, image/png, image/heic

3. 创建 `oval_office_thread_images`
   - Public bucket: ✅
   - File size limit: 5MB
   - Allowed MIME types: image/jpeg, image/png, image/heic

#### 2.2 设置Storage Policies
```sql
-- thread_images policies
CREATE POLICY "Anyone can upload thread images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'thread_images');

CREATE POLICY "Anyone can read thread images"
ON storage.objects FOR SELECT
USING (bucket_id = 'thread_images');

-- oval_office_thread_images policies
CREATE POLICY "Anyone can upload oval thread images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'oval_office_thread_images');

CREATE POLICY "Anyone can read oval thread images"
ON storage.objects FOR SELECT
USING (bucket_id = 'oval_office_thread_images');
```

#### 2.3 迁移现有图片（可选）
**选项A**: 保持旧bucket，不迁移文件
- 优点：简单，现有URL继续有效
- 缺点：bucket名称不一致

**选项B**: 迁移所有文件到新bucket
- 优点：命名完全统一
- 缺点：需要更新所有image_url字段

**推荐选项A**，保持旧bucket继续工作。

### 第三步：应用代码更新（已完成）✅

以下文件已自动更新：
- ✅ `BuildingCheckInManager.swift` - threads
- ✅ `OvalOfficeCheckInManager.swift` - oval_office_threads
- ✅ `BidManager.swift` - threads, oval_office_threads
- ✅ `MarketDataManager.swift` - threads
- ✅ `ContentView.swift` - threads
- ✅ `MyHistoryView.swift` - threads, oval_office_threads
- ✅ `AssetHistoryModal.swift` - threads, oval_office_threads
- ✅ `NFCHistoryFullScreenView.swift` - threads, oval_office_threads
- ✅ `OvalOfficeHistoryModal.swift` - threads, oval_office_threads
- ✅ `BidDetailView.swift` - threads, oval_office_threads
- ✅ `DebugDashboard.swift` - oval_office_threads

### 第四步：测试验证

#### 4.1 编译测试
```bash
# 在Xcode中编译项目
⌘ + B
```

#### 4.2 功能测试清单
- [ ] 创建Building Thread（扫描NFC）
- [ ] 创建Oval Office Thread
- [ ] 查看Thread历史
- [ ] Thread详情显示
- [ ] 出价功能（Bid）
- [ ] 接受Bid并转移Thread所有权
- [ ] Thread转让功能
- [ ] Market统计数据
- [ ] 用户历史记录
- [ ] NFC历史记录

#### 4.3 数据验证
```sql
-- 检查Bid关联的Thread是否存在
SELECT b.id, b.record_id, b.record_type, 
       CASE 
           WHEN b.record_type = 'building' THEN EXISTS(SELECT 1 FROM threads WHERE id = b.record_id)
           ELSE EXISTS(SELECT 1 FROM oval_office_threads WHERE id = b.record_id)
       END as record_exists
FROM bids b
WHERE b.status IN ('pending', 'accepted', 'countered')
LIMIT 10;

-- 检查Transfer关联的Thread是否存在
SELECT t.id, t.record_id, t.record_type,
       CASE 
           WHEN t.record_type = 'building' THEN EXISTS(SELECT 1 FROM threads WHERE id = t.record_id::uuid)
           ELSE EXISTS(SELECT 1 FROM oval_office_threads WHERE id = t.record_id::uuid)
       END as record_exists
FROM transfer_requests t
WHERE t.status = 'pending'
LIMIT 10;
```

### 第五步：清理旧表（谨慎！）

#### 5.1 等待期（建议）
- 运行新系统 **3-7天**
- 确认所有功能正常
- 监控错误日志

#### 5.2 重命名旧表为备份
```sql
ALTER TABLE asset_checkins RENAME TO asset_checkins_backup_20251027;
ALTER TABLE oval_office_checkins RENAME TO oval_office_checkins_backup_20251027;
```

#### 5.3 最终删除（30天后）
```sql
-- 确认完全不需要后再执行
DROP TABLE IF EXISTS asset_checkins_backup_20251027;
DROP TABLE IF EXISTS oval_office_checkins_backup_20251027;
```

## 🔙 回滚方案

### 如果迁移后出现问题

#### 数据库回滚
```sql
-- 删除新表
DROP TABLE IF EXISTS threads;
DROP TABLE IF EXISTS oval_office_threads;

-- 如果旧表被重命名，恢复
ALTER TABLE asset_checkins_backup_20251027 RENAME TO asset_checkins;
ALTER TABLE oval_office_checkins_backup_20251027 RENAME TO oval_office_checkins;
```

#### 代码回滚
```bash
# 使用Git回滚代码
git log --oneline  # 找到迁移前的commit
git revert <commit_hash>
```

## 📋 迁移检查表

### 准备阶段
- [ ] 阅读完整迁移文档
- [ ] 备份Supabase数据库
- [ ] 备份本地代码（Git commit）
- [ ] 准备回滚方案

### 执行阶段
- [ ] 在Supabase执行 DATABASE_MIGRATION_COMPLETE.sql
- [ ] 验证数据迁移完整性
- [ ] 创建新Storage buckets
- [ ] 设置Storage policies
- [ ] 应用代码已更新（自动完成）
- [ ] 编译通过

### 测试阶段
- [ ] Thread创建功能
- [ ] Thread查询功能
- [ ] Bid功能
- [ ] Transfer功能
- [ ] Market统计
- [ ] 用户历史

### 清理阶段
- [ ] 运行3-7天无问题
- [ ] 重命名旧表为备份
- [ ] 30天后删除备份表

## 🎯 为什么现在迁移很重要

### 未来NFT功能的需要
1. **清晰的数据模型**
   - Thread = 可铸造为NFT的数字资产
   - 表名 `threads` 比 `asset_checkins` 更贴近NFT概念

2. **避免混淆**
   - "check-in" 暗示临时记录
   - "thread" 暗示可持久化、可交易的资产
   - NFT铸造时，"thread" 更容易理解

3. **扩展性**
   - 未来可以添加 `thread_nfts` 表关联
   - 字段如 `nft_token_id`, `nft_contract_address`
   - 清晰的Thread → NFT映射关系

4. **一致性**
   - 应用UI已使用Thread术语
   - 数据库应该匹配，避免开发混乱
   - 文档、代码、数据库三者统一

## 📝 迁移完成后的系统架构

```
用户创建Thread
    ↓
存储在 threads 表
    ↓
使用 Echo 交易 (bids表)
    ↓
转移所有权 (username字段更新)
    ↓
未来：铸造NFT (thread_nfts表)
    ↓
链上永久存储
```

## 更新日期
2025-10-27

## 迁移版本
Database Schema Version: 2.0
App Code Version: 对应的Git commit hash

