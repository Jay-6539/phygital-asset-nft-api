# 🚀 快速开始 - 数据库迁移

## 📋 3步完成迁移

### 第1步：备份数据库 (1分钟)

1. 打开 https://supabase.com/dashboard
2. 选择您的项目
3. Settings → Database → Create Backup
4. 等待备份完成

### 第2步：执行迁移SQL (2分钟)

#### 2.1 打开迁移文件
```bash
# 文件位置
/Users/Jay/Documents/TreasureHuntHK/DATABASE_MIGRATION_COMPLETE.sql
```

#### 2.2 在Supabase执行
1. Supabase Dashboard → **SQL Editor**
2. 点击 **New query**
3. 复制 `DATABASE_MIGRATION_COMPLETE.sql` 的全部内容
4. 粘贴到编辑器
5. 点击 **Run** 执行
6. 等待执行完成（应该看到成功消息）

### 第3步：创建Storage Buckets (2分钟)

#### 3.1 创建 thread_images
1. Supabase Dashboard → **Storage**
2. 点击 **New bucket**
3. 设置：
   - Name: `thread_images`
   - Public bucket: ✅ 勾选
   - File size limit: 5 MB
   - Allowed MIME types: `image/jpeg,image/png,image/heic`
4. 点击 **Create bucket**

#### 3.2 创建 oval_office_thread_images
重复上述步骤，名称改为 `oval_office_thread_images`

#### 3.3 设置Storage Policies
在Supabase SQL Editor执行：
```sql
-- thread_images policies
CREATE POLICY "Public upload" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'thread_images');

CREATE POLICY "Public read" ON storage.objects
FOR SELECT USING (bucket_id = 'thread_images');

-- oval_office_thread_images policies
CREATE POLICY "Public upload" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'oval_office_thread_images');

CREATE POLICY "Public read" ON storage.objects
FOR SELECT USING (bucket_id = 'oval_office_thread_images');
```

## ✅ 完成！

### 测试应用
1. 在Xcode中编译（⌘+B）
2. 运行应用
3. 测试以下功能：
   - 创建Thread
   - 查看Thread历史
   - Bid功能
   - Market数据

## 🧹 清理旧表（可选）

### 7天后执行
如果新系统运行正常，可以清理旧表。

打开并执行：
```
/Users/Jay/Documents/TreasureHuntHK/CLEANUP_OLD_TABLES.sql
```

按照脚本中的说明操作。

## 📁 相关文件

| 文件 | 用途 |
|------|------|
| `DATABASE_MIGRATION_COMPLETE.sql` | ⭐ 主迁移脚本 |
| `CLEANUP_OLD_TABLES.sql` | 🧹 清理旧表 |
| `XP_SYSTEM_SETUP.sql` | XP系统（如需要）|
| `COMPLETE_MIGRATION_CHECKLIST.md` | 详细检查清单 |

## ⏱️ 总耗时

- 备份: ~1分钟
- SQL迁移: ~2分钟
- Storage设置: ~2分钟
- **总计: ~5分钟**

## 🎉 就这么简单！

执行完这3步，您的数据库就完成了现代化升级，为NFT功能做好了准备！

