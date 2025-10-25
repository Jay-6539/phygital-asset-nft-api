# 🔄 Treasure Hunt Transfer Feature

## 功能概述

用户可以将自己的Check-in记录转让给其他用户。转让通过QR码和NFC验证完成，确保安全和唯一性。

## 📋 功能特点

### ✅ 安全机制
- **一次性转让码**：每个转让请求都有唯一的UUID
- **NFC现场验证**：接收者必须扫描实际的NFC标签
- **时效性**：转让请求5分钟后自动过期
- **原子性**：数据库事务确保转让不会重复
- **可追溯**：所有转让历史都保存在数据库

### 🎯 用户体验
- **简单直观**：扫描QR码即可发起转让
- **实时反馈**：转让状态实时更新
- **可取消**：转让完成前可随时取消

## 🚀 设置步骤

### 1. Supabase数据库配置

在Supabase SQL Editor中执行以下SQL脚本：

```bash
# 文件位置
./TRANSFER_SUPABASE_SETUP.sql
```

这将创建：
- ✅ `transfer_requests` 表
- ✅ `complete_transfer()` 函数（原子性转让）
- ✅ RLS策略
- ✅ 必要的索引

### 2. 验证数据库配置

在Supabase SQL Editor中执行：

```sql
-- 检查表是否创建成功
SELECT * FROM transfer_requests LIMIT 1;

-- 检查函数是否存在
SELECT proname FROM pg_proc WHERE proname = 'complete_transfer';
```

## 📱 使用流程

### 用户A（转让方）

1. **打开My History**
   - 点击右下角O菜单的"Me"按钮

2. **选择记录**
   - 点击任意建筑分组
   - 点击要转让的具体记录

3. **发起转让**
   - 点击"Transfer"按钮
   - 等待QR码生成

4. **显示QR码**
   - QR码显示在屏幕上
   - 显示转让码（用于备份）
   - 显示倒计时（5分钟）

5. **等待接收**
   - 保持屏幕显示
   - 可以选择"取消转让"

6. **转让完成**
   - 自动显示"Transfer Completed!"
   - 记录从My History中消失

### 用户B（接收方）

1. **扫描QR码**
   - 打开应用
   - 点击"接收转让"按钮（需要添加到UI）
   - 扫描用户A屏幕上的QR码

2. **查看转让信息**
   - 显示建筑名称
   - 显示Asset名称
   - 显示转让者姓名
   - 显示过期时间

3. **NFC验证**
   - 点击"Scan NFC to Accept"按钮
   - 前往实际位置
   - 扫描NFC标签

4. **完成接收**
   - NFC验证成功 → 转让完成
   - 记录出现在My History中
   - Owner自动改为用户B

### 错误处理

- **QR码过期**：显示"Transfer Expired"
- **NFC不匹配**：显示"NFC UUID mismatch"
- **已被接收**：显示"Transfer already completed"
- **扫描失败**：可以重新扫描

## 🔒 安全保证

### 防止重复接收
```sql
-- 数据库级别的原子锁
SELECT * FROM transfer_requests 
WHERE transfer_code = $1
FOR UPDATE;  -- 锁定行，防止并发

-- 状态检查
IF status != 'pending' THEN
    RETURN 'already completed';
END IF;
```

### NFC验证
- 接收者必须扫描与记录关联的实际NFC标签
- NFC UUID必须完全匹配
- 无法远程完成转让

### 时效性
- 默认5分钟有效期
- 过期自动标记为expired
- 可以配置更长或更短的有效期

## 📊 数据库架构

### transfer_requests表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| transfer_code | UUID | 转让码（唯一） |
| record_id | TEXT | 原记录ID |
| record_type | TEXT | building 或 oval_office |
| nfc_uuid | TEXT | NFC UUID |
| building_name | TEXT | 建筑名称 |
| asset_name | TEXT | Asset名称 |
| from_user | TEXT | 转让者用户名 |
| to_user | TEXT | 接收者用户名 |
| status | TEXT | pending/completed/expired/cancelled |
| created_at | TIMESTAMP | 创建时间 |
| expires_at | TIMESTAMP | 过期时间 |
| completed_at | TIMESTAMP | 完成时间 |

## 🛠️ 待添加的UI元素

### 1. 主界面添加"接收转让"入口

建议在Welcome页面或主地图添加：

```swift
Button("Receive Transfer") {
    showReceiveTransfer = true
}
.fullScreenCover(isPresented: $showReceiveTransfer) {
    ReceiveTransferView(
        appGreen: appGreen,
        username: username,
        onClose: { showReceiveTransfer = false },
        onTransferComplete: { 
            // 刷新My History
            showReceiveTransfer = false
        }
    )
}
```

### 2. 集成NFC扫描

在ReceiveTransferView中集成NFCManager：

```swift
func startNFCVerification(data: TransferQRData) {
    nfcManager.startExploreScan()
    
    nfcManager.onNFCDetected = {
        let scannedUuid = nfcManager.assetUUID
        completeTransfer(data: data, scannedNfcUuid: scannedUuid)
    }
}
```

## 📝 后续优化建议

1. **推送通知**：转让完成时通知双方
2. **转让历史**：查看所有转让记录
3. **批量转让**：一次转让多个记录
4. **转让条件**：设置接收者限制（如好友）
5. **转让费用**：游戏化元素（消耗虚拟货币）

## 🐛 故障排除

### QR码不显示
- 检查TransferRequest是否正确创建
- 检查QRCodeGenerator是否正常工作

### 转让失败
- 检查Supabase函数是否正确部署
- 查看数据库日志
- 验证NFC UUID是否匹配

### 性能优化
- QR码生成在后台线程
- 图片加载使用缓存
- 定期清理过期的转让请求

## 📞 技术支持

遇到问题时：
1. 检查Xcode控制台日志（Logger输出）
2. 查看Supabase日志
3. 验证网络连接
4. 检查用户权限

---

**版本**: 1.0  
**最后更新**: 2025-10-24

