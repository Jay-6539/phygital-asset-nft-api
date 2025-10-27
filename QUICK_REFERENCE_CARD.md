# 🚀 快速参考卡 - 第三方服务更新

## 📋 三步快速更新

### 1️⃣ Google Sign-In (5分钟)
```
网址: https://console.cloud.google.com
路径: API和服务 → 凭据 → OAuth 2.0客户端ID
操作: 将Bundle ID改为 com.jay.phygitalasset
```

### 2️⃣ Facebook Login (5分钟)
```
网址: https://developers.facebook.com
路径: 我的应用 → 设置 → 基本 → iOS平台
操作: 将Bundle ID改为 com.jay.phygitalasset
```

### 3️⃣ Apple Developer (15分钟)
```
网址: https://developer.apple.com/account
操作:
1. Identifiers → 创建App ID: com.jay.phygitalasset
2. Profiles → 创建Development Profile
3. Xcode → 配置Signing & Capabilities
```

---

## 📝 关键信息

### 新的应用标识
```
应用名称: Phygital Asset
Bundle ID: com.jay.phygitalasset
显示名称: Phygital Asset
```

### URL Schemes检查
```xml
<!-- Google -->
<string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>

<!-- Facebook -->
<string>fbYOUR_FACEBOOK_APP_ID</string>
```

---

## ✅ 验证清单

- [ ] Google Console - Bundle ID已更新
- [ ] Facebook平台 - Bundle ID已更新
- [ ] Apple Developer - App ID已创建
- [ ] Provisioning Profiles已下载
- [ ] Xcode Signing配置完成
- [ ] Google登录测试通过
- [ ] Facebook登录测试通过
- [ ] 应用在真机运行成功

---

## 📞 详细文档

需要详细步骤？查看：
```
THIRD_PARTY_SERVICES_UPDATE_GUIDE.md
```

需要完整检查清单？查看：
```
COMPLETE_RENAME_CHECKLIST.md
```

---

## ⏱️ 预计时间

| 任务 | 时间 |
|------|------|
| Google更新 | 5分钟 |
| Facebook更新 | 5分钟 |
| Apple Developer | 15分钟 |
| 测试验证 | 10分钟 |
| **总计** | **~35分钟** |

---

## 🎯 现在就开始！

1. 打开 `THIRD_PARTY_SERVICES_UPDATE_GUIDE.md`
2. 按步骤操作
3. 完成后测试登录
4. 享受新名称的应用！🎉

