# 🔍 问题排查指南 - Check-in 功能

## 当前问题：Failed to load history / Failed to fetch check-ins

### 📋 排查清单

按顺序检查以下项目：

---

## ✅ 第1步：确认 Supabase 表已创建

### 检查方法：
1. 登录 [Supabase Dashboard](https://supabase.com/dashboard)
2. 选择您的项目
3. 点击左侧 **Table Editor**
4. 查看是否有 `building_checkins` 表

### 如果表不存在：

在 **SQL Editor** 中执行：

```sql
-- 创建表
CREATE TABLE building_checkins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  building_id TEXT NOT NULL,
  username TEXT NOT NULL,
  asset_name TEXT,
  description TEXT NOT NULL DEFAULT '',
  image_url TEXT,
  nfc_uuid TEXT,
  gps_latitude DOUBLE PRECISION,
  gps_longitude DOUBLE PRECISION,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_building_checkins_building_id ON building_checkins(building_id);
CREATE INDEX idx_building_checkins_created_at ON building_checkins(created_at DESC);
```

---

## ✅ 第2步：检查 RLS（Row Level Security）策略

### 问题症状：
- HTTP 状态码：**401 Unauthorized** 或 **403 Forbidden**
- 日志显示："Response status code: 401"

### 解决方案：

在 **SQL Editor** 中执行：

```sql
-- 启用 RLS
ALTER TABLE building_checkins ENABLE ROW LEVEL SECURITY;

-- 允许所有人读取（公开访问）
CREATE POLICY "Allow public read access" 
ON building_checkins 
FOR SELECT 
USING (true);

-- 允许所有人插入
CREATE POLICY "Allow public insert" 
ON building_checkins 
FOR INSERT 
WITH CHECK (true);
```

### 验证策略：
1. 在 Supabase Dashboard → **Authentication** → **Policies**
2. 找到 `building_checkins` 表
3. 应该看到两个策略：
   - ✅ "Allow public read access" (SELECT)
   - ✅ "Allow public insert" (INSERT)

---

## ✅ 第3步：检查 API 配置

### 检查 SupabaseConfig：

1. 打开 `Config.xcconfig` 文件
2. 确认以下配置：

```
SUPABASE_URL = https://zcaznpjulvmaxjnhvqaw.supabase.co
SUPABASE_ANON_KEY = eyJhbGci...（你的实际 key）
```

### 验证方法：

在 App 中添加临时日志：
```swift
print("Supabase URL: \(SupabaseConfig.url)")
print("API Key length: \(SupabaseConfig.anonKey.count)")
```

---

## ✅ 第4步：查看详细日志

### 现在代码已增强日志输出

运行 App 后，在 Xcode Console 中查找：

```
🗄️ Fetching check-ins for building: HB_001
🐛 Request URL: https://...
🐛 Response status code: 200
🐛 Response body: [...]
```

### 常见错误码：

| 状态码 | 含义 | 解决方案 |
|--------|------|----------|
| **200** | 成功 | 检查响应数据格式 |
| **401** | 未授权 | 检查 API Key 和 RLS 策略 |
| **404** | 未找到 | 检查表名是否正确 |
| **406** | 不可接受 | 检查 Accept header |

---

## ✅ 第5步：手动测试 API

### 使用 curl 测试：

```bash
# 替换为你的实际值
SUPABASE_URL="https://zcaznpjulvmaxjnhvqaw.supabase.co"
API_KEY="your_anon_key_here"

# 测试获取 check-ins
curl -X GET \
  "${SUPABASE_URL}/rest/v1/building_checkins?select=*" \
  -H "apikey: ${API_KEY}" \
  -H "Authorization: Bearer ${API_KEY}"
```

### 期望结果：
```json
[]  // 如果表为空
```

或

```json
[
  {
    "id": "...",
    "building_id": "HB_001",
    "username": "test",
    ...
  }
]
```

---

## ✅ 第6步：测试 Storage Bucket（如果图片上传失败）

### 创建 Storage Bucket：

1. Supabase Dashboard → **Storage**
2. 点击 **Create a new bucket**
3. 配置：
   - Name: `building_checkin_images`
   - ✅ Public bucket
4. 点击 **Create**

### 设置 Storage Policies：

```sql
-- 允许公开上传
CREATE POLICY "Allow public upload" 
ON storage.objects 
FOR INSERT 
WITH CHECK (bucket_id = 'building_checkin_images');

-- 允许公开读取
CREATE POLICY "Allow public read" 
ON storage.objects 
FOR SELECT 
USING (bucket_id = 'building_checkin_images');
```

---

## 🧪 快速测试方案

### 方案 A：先不要图片，只测试数据

1. Check-in 时**不上传照片**
2. 只填写 Description
3. 如果成功，说明表和 RLS 配置正确
4. 然后再测试图片上传

### 方案 B：使用 Postman 测试

1. 下载 Postman
2. 创建 GET 请求：
   ```
   GET https://zcaznpjulvmaxjnhvqaw.supabase.co/rest/v1/building_checkins?select=*
   Headers:
     apikey: your_anon_key
     Authorization: Bearer your_anon_key
   ```
3. 发送请求，查看响应

---

## 📝 常见错误和解决方案

### Error 1: "Invalid URL"
**原因**: URL 构建错误  
**解决**: 检查 `SupabaseConfig.url` 是否正确

### Error 2: "Failed to decode"
**原因**: 数据库字段类型与代码不匹配  
**解决**: 检查表结构是否与 `BuildingCheckIn` 结构体匹配

### Error 3: "The operation couldn't be completed"
**原因**: 网络问题或 Supabase 服务不可用  
**解决**: 
- 检查网络连接
- 访问 [Supabase Status](https://status.supabase.com/)

---

## 🆘 仍然无法解决？

请提供以下信息：

1. **Xcode Console 完整日志**（包含所有 Logger 输出）
2. **HTTP 状态码**
3. **Response body** 内容
4. **Supabase Dashboard 截图**：
   - Table Editor 中的表结构
   - Policies 设置

---

## ✅ 成功的标志

当一切正常时，您应该看到：

```
🗄️ Fetching check-ins for building: HB_001
🐛 Request URL: https://zcaznpjulvmaxjnhvqaw.supabase.co/rest/v1/building_checkins?building_id=eq.HB_001&order=created_at.desc&select=*
🐛 Response status code: 200
🐛 Response body: []
✅ Fetched 0 check-ins for building: HB_001
```

如果看到 `Fetched 0 check-ins`，说明**配置成功**，只是还没有数据！


