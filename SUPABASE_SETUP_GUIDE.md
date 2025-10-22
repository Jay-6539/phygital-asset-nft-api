# 📚 Supabase 设置指南 - 历史建筑 Check-in 功能

## 🎯 目标

为历史建筑（Treasure）添加多用户共享的 Check-in 历史记录功能，使用 Supabase 云存储。

---

## 📋 第一步：创建数据表

### 1. 登录 Supabase Dashboard
访问 [https://supabase.com/dashboard](https://supabase.com/dashboard)

### 2. 创建 `building_checkins` 表

在 SQL Editor 中执行以下 SQL：

```sql
-- 创建历史建筑 check-in 记录表
CREATE TABLE building_checkins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  building_id TEXT NOT NULL,           -- 建筑ID (如 "HB_001")
  username TEXT NOT NULL,               -- 用户名
  asset_name TEXT,                      -- 用户输入的Asset名称
  description TEXT NOT NULL DEFAULT '', -- 描述
  image_url TEXT,                       -- 图片URL
  nfc_uuid TEXT,                        -- NFC标签UUID
  gps_latitude DOUBLE PRECISION,        -- GPS纬度
  gps_longitude DOUBLE PRECISION,       -- GPS经度
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引以提高查询性能
CREATE INDEX idx_building_checkins_building_id ON building_checkins(building_id);
CREATE INDEX idx_building_checkins_created_at ON building_checkins(created_at DESC);
CREATE INDEX idx_building_checkins_username ON building_checkins(username);

-- 添加注释
COMMENT ON TABLE building_checkins IS '历史建筑的 Check-in 记录';
COMMENT ON COLUMN building_checkins.building_id IS '建筑ID，对应 Treasure 的 id 字段';
COMMENT ON COLUMN building_checkins.username IS '进行 check-in 的用户名';
COMMENT ON COLUMN building_checkins.asset_name IS '用户输入的Asset名称（可选）';
COMMENT ON COLUMN building_checkins.description IS '用户输入的描述';
COMMENT ON COLUMN building_checkins.image_url IS 'Storage中图片的公开URL';
COMMENT ON COLUMN building_checkins.nfc_uuid IS 'NFC标签的唯一标识符';
COMMENT ON COLUMN building_checkins.gps_latitude IS 'Check-in时的GPS纬度';
COMMENT ON COLUMN building_checkins.gps_longitude IS 'Check-in时的GPS经度';
```

### 3. 设置 Row Level Security (RLS)

```sql
-- 启用 RLS
ALTER TABLE building_checkins ENABLE ROW LEVEL SECURITY;

-- 允许所有人读取
CREATE POLICY "Allow public read access" 
ON building_checkins 
FOR SELECT 
USING (true);

-- 允许所有人插入（实际应用中可以添加认证限制）
CREATE POLICY "Allow public insert" 
ON building_checkins 
FOR INSERT 
WITH CHECK (true);

-- 如果需要用户只能修改自己的记录
-- CREATE POLICY "Users can update own records" 
-- ON building_checkins 
-- FOR UPDATE 
-- USING (auth.uid() = user_id);
```

---

## 🗂️ 第二步：创建 Storage Bucket

### 1. 创建 `building_checkin_images` Bucket

1. 在 Supabase Dashboard 中点击 **Storage**
2. 点击 **Create a new bucket**
3. 设置以下参数：
   - **Name**: `building_checkin_images`
   - **Public bucket**: ✅ 勾选（允许公开访问图片）
   - **File size limit**: 5MB
   - **Allowed MIME types**: `image/jpeg, image/png, image/heic`

### 2. 设置 Storage Policies

```sql
-- 允许所有人上传图片
CREATE POLICY "Allow public upload" 
ON storage.objects 
FOR INSERT 
WITH CHECK (bucket_id = 'building_checkin_images');

-- 允许所有人读取图片
CREATE POLICY "Allow public read" 
ON storage.objects 
FOR SELECT 
USING (bucket_id = 'building_checkin_images');

-- 允许用户删除自己的图片（可选）
-- CREATE POLICY "Users can delete own images" 
-- ON storage.objects 
-- FOR DELETE 
-- USING (bucket_id = 'building_checkin_images' AND auth.uid() = owner);
```

---

## 🔧 第三步：测试功能

### 1. 在 App 中测试

1. **运行应用**
2. **选择一个历史建筑**（如 "Jay's Table"）
3. **点击 "Check In Mine"**
4. **输入信息**:
   - Asset Name: "测试签到"
   - Description: "第一次测试"
   - Photo: 上传一张照片
5. **Tap NFC 或点击确认**
6. **查看日志** - 应该看到：
   ```
   ✅ Check-in saved successfully!
      - Building: Jay's Table
      - Username: [你的用户名]
      - Check-in ID: [UUID]
   ```

### 2. 再次 Tap NFC 查看历史

1. **再次 Tap 同一个 NFC 标签**
2. **应该看到 Asset History 界面显示：**
   - 你刚才的 check-in 记录
   - 用户名、时间、描述、照片

### 3. 在 Supabase Dashboard 中验证

1. 打开 **Table Editor**
2. 选择 `building_checkins` 表
3. 应该看到你的记录

---

## 📊 数据结构示例

### building_checkins 表数据示例

| id | building_id | username | asset_name | description | image_url | nfc_uuid | gps_latitude | gps_longitude | created_at |
|----|-------------|----------|------------|-------------|-----------|----------|--------------|---------------|------------|
| uuid-1 | HB_001 | Jay | 桌子 | 很漂亮的桌子 | https://... | nfc-123 | 22.2816 | 114.1583 | 2025-10-21... |
| uuid-2 | HB_001 | Alice | 椅子 | 古董椅子 | https://... | nfc-123 | 22.2816 | 114.1583 | 2025-10-21... |

---

## 🎨 功能对比

| 特性 | Office Map | 历史建筑 (Treasure) |
|------|------------|---------------------|
| **存储方式** | 本地文件 (PersistenceManager) | ☁️ Supabase 云存储 |
| **数据共享** | ❌ 单设备 | ✅ 多用户共享 |
| **跨设备同步** | ❌ | ✅ |
| **社交功能** | ❌ | ✅ 可以看到其他人的记录 |
| **离线支持** | ✅ | ⚠️ 需要网络连接 |
| **数据备份** | ❌ | ✅ 自动云备份 |

---

## 🔍 故障排查

### 问题 1: "Failed to save check-in"
**解决方案**:
- 检查网络连接
- 确认 Supabase API Key 配置正确
- 检查 RLS 策略是否正确设置

### 问题 2: 图片上传失败
**解决方案**:
- 确认 Storage Bucket 已创建
- 检查图片大小（< 5MB）
- 确认 Storage Policies 已设置

### 问题 3: 无法看到历史记录
**解决方案**:
- 检查 `building_id` 是否正确匹配
- 确认 RLS 的 SELECT 策略允许公开读取
- 查看控制台日志了解具体错误

---

## 📝 代码已实现的功能

✅ **BuildingCheckInManager.swift**
- 保存 check-in 到 Supabase
- 上传图片到 Storage
- 读取某个建筑的历史记录
- 从 URL 下载图片

✅ **ContentView.swift 更新**
- `saveCheckInData()` - 调用 Supabase 保存
- `AssetHistoryModal` - 从 Supabase 加载并显示历史
- `BuildingCheckInRow` - 显示单条 check-in 记录

---

## 🚀 下一步增强功能（可选）

1. **用户认证集成**
   - 使用 Supabase Auth 进行用户登录
   - 记录用户的 user_id

2. **点赞/评论功能**
   - 为 check-in 记录添加点赞
   - 添加评论功能

3. **排行榜**
   - 统计每个建筑的 check-in 数量
   - 显示最活跃的用户

4. **离线支持**
   - 本地缓存 check-in 记录
   - 网络恢复时同步

5. **图片优化**
   - 自动压缩图片
   - 生成缩略图

---

## ✅ 完成检查清单

- [ ] Supabase 中创建 `building_checkins` 表
- [ ] 设置表的 RLS 策略
- [ ] 创建 `building_checkin_images` Storage Bucket
- [ ] 设置 Storage Policies
- [ ] 测试 check-in 功能
- [ ] 测试查看历史记录功能
- [ ] 验证图片上传和显示
- [ ] 确认多用户可以看到彼此的记录

---

**🎉 完成后，您的历史建筑就有完整的社交 check-in 功能了！**


