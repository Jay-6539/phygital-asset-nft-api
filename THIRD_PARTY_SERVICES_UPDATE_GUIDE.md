# 第三方服务更新指南 - Bundle ID 变更

## 🎯 概述

应用重命名后，Bundle ID从 `com.jay.treasurehunt` 变更为 `com.jay.phygitalasset`，需要更新以下第三方服务配置。

---

## 1️⃣ Google Sign-In 配置更新

### 步骤 1.1: 访问Google Cloud Console
1. 打开浏览器，访问：https://console.cloud.google.com
2. 使用您的Google账号登录
3. 选择您的项目（如果有多个项目）

### 步骤 1.2: 更新OAuth客户端ID

#### 找到OAuth配置
1. 左侧菜单 → **API和服务** (APIs & Services)
2. 点击 **凭据** (Credentials)
3. 在 "OAuth 2.0 客户端 ID" 部分，找到您的iOS客户端

#### 更新iOS客户端配置
1. 点击您的iOS客户端名称（可能显示为 "iOS client" 或自定义名称）
2. 在编辑页面中找到：
   - **Bundle ID**: 
     - 删除旧的：`com.jay.treasurehunt`
     - 添加新的：`com.jay.phygitalasset`
3. **URL schemes** (如果配置了):
   - 删除旧的：`com.googleusercontent.apps.YOUR_CLIENT_ID`
   - 保持不变（URL scheme基于Client ID，不是Bundle ID）

#### 保存更改
1. 滚动到底部，点击 **保存** (Save)
2. 记录您的 **客户端ID** (Client ID) - 稍后需要

### 步骤 1.3: 下载新配置（可选）
1. 如果Google提供了配置文件下载选项，下载新的配置文件
2. 替换项目中的 `GoogleService-Info.plist`（如果需要）

### 步骤 1.4: 验证Info.plist中的URL Scheme

检查 `Phygital-Asset-Info.plist` 中：
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- 应该包含您的Google Client ID反转格式 -->
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 步骤 1.5: 测试Google登录
1. 运行应用
2. 点击 "Sign in with Google"
3. 验证登录流程是否正常

---

## 2️⃣ Facebook Login 配置更新

### 步骤 2.1: 访问Facebook开发者平台
1. 打开浏览器，访问：https://developers.facebook.com
2. 使用您的Facebook账号登录
3. 点击右上角 **我的应用** (My Apps)
4. 选择您的应用

### 步骤 2.2: 更新iOS平台设置

#### 进入iOS设置
1. 左侧菜单 → **设置** (Settings) → **基本** (Basic)
2. 滚动到 **平台** (Platforms) 部分
3. 找到 **iOS** 平台（如果没有，点击 "添加平台" 并选择iOS）

#### 更新Bundle ID
1. 在iOS平台设置中，找到 **Bundle ID** 字段
2. 将 `com.jay.treasurehunt` 改为 `com.jay.phygitalasset`
3. 其他字段保持不变：
   - **iPhone Store ID**: 保持不变
   - **iPad Store ID**: 保持不变（如果有）

### 步骤 2.3: 更新Single Sign On设置

1. 在同一页面，找到 **Single Sign On** 部分
2. 确保已启用
3. 检查 **URL Scheme Suffix** 是否正确

### 步骤 2.4: 保存更改
1. 滚动到页面底部
2. 点击 **保存更改** (Save Changes)
3. 等待保存完成

### 步骤 2.5: 验证Info.plist中的Facebook配置

检查 `Phygital-Asset-Info.plist` 中：
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fbYOUR_APP_ID</string>
        </array>
    </dict>
</array>

<key>FacebookAppID</key>
<string>YOUR_APP_ID</string>

<key>FacebookDisplayName</key>
<string>Phygital Asset</string>
```

### 步骤 2.6: 测试Facebook登录
1. 运行应用
2. 点击 "Sign in with Facebook"
3. 验证登录流程是否正常

---

## 3️⃣ Apple Developer 配置更新

### 步骤 3.1: 访问Apple Developer账号
1. 打开浏览器，访问：https://developer.apple.com/account
2. 使用您的Apple ID登录
3. 选择 **Certificates, Identifiers & Profiles**

### 步骤 3.2: 创建新的App ID

#### 进入Identifiers
1. 左侧菜单 → **Identifiers**
2. 点击右上角的 **+** 按钮
3. 选择 **App IDs**，点击 **Continue**
4. 选择 **App**，点击 **Continue**

#### 配置App ID
1. **Description**: `Phygital Asset`
2. **Bundle ID**: 选择 **Explicit**
   - 输入：`com.jay.phygitalasset`
3. **Capabilities**: 勾选您需要的功能
   - ✅ **Sign in with Apple** (如果使用)
   - ✅ **Push Notifications** (如果使用)
   - ✅ **Associated Domains** (如果使用)
   - ✅ **NFC Tag Reading** (您的应用需要)
   - 其他根据需要选择

4. 点击 **Continue**
5. 检查信息，点击 **Register**

### 步骤 3.3: 创建Development证书（如果需要）

#### 检查现有证书
1. 左侧菜单 → **Certificates**
2. 检查是否有有效的 **iOS App Development** 证书
3. 如果已有且未过期，可以跳过此步骤

#### 创建新证书
1. 点击右上角的 **+** 按钮
2. 选择 **iOS App Development**
3. 点击 **Continue**
4. 按照提示生成CSR（Certificate Signing Request）:
   ```
   在Mac上：
   - 打开 "钥匙串访问" (Keychain Access)
   - 菜单栏 → 钥匙串访问 → 证书助理 → 从证书颁发机构请求证书
   - 填写邮箱地址
   - 选择"存储到磁盘"
   - 保存CSR文件
   ```
5. 上传CSR文件
6. 下载证书并双击安装

### 步骤 3.4: 创建Development Provisioning Profile

#### 创建Profile
1. 左侧菜单 → **Profiles**
2. 点击右上角的 **+** 按钮
3. 选择 **iOS App Development**
4. 点击 **Continue**

#### 配置Profile
1. **App ID**: 选择刚创建的 `com.jay.phygitalasset`
2. 点击 **Continue**
3. **Certificates**: 选择您的开发证书
4. 点击 **Continue**
5. **Devices**: 选择测试设备（至少选择您的iPhone）
6. 点击 **Continue**
7. **Provisioning Profile Name**: 输入 `Phygital Asset Development`
8. 点击 **Generate**

#### 下载和安装
1. 点击 **Download** 下载 `.mobileprovision` 文件
2. 双击文件安装到Xcode
3. 或者将文件拖到Xcode图标上

### 步骤 3.5: 创建Distribution Provisioning Profile（发布用）

#### 创建App Store Profile
1. Profiles → 点击 **+**
2. 选择 **App Store** (用于提交App Store)
3. 选择 App ID: `com.jay.phygitalasset`
4. 选择Distribution证书
5. 命名：`Phygital Asset App Store`
6. Generate并下载

#### 创建Ad Hoc Profile（测试分发）
1. Profiles → 点击 **+**
2. 选择 **Ad Hoc**
3. 选择 App ID: `com.jay.phygitalasset`
4. 选择Distribution证书
5. 选择测试设备
6. 命名：`Phygital Asset Ad Hoc`
7. Generate并下载

### 步骤 3.6: 在Xcode中配置

#### 打开项目设置
1. 打开 `Phygital Asset.xcodeproj`
2. 选择项目根节点
3. 选择 **Phygital Asset** target

#### Signing & Capabilities
1. 选择 **Signing & Capabilities** 标签
2. **Team**: 选择您的开发团队
3. **Bundle Identifier**: 确认显示 `com.jay.phygitalasset`
4. **Provisioning Profile**: 
   - Debug: 选择 "Phygital Asset Development"
   - Release: 选择 "Phygital Asset App Store"
5. 如果看到 "Signing for 'Phygital Asset' requires a development team"，选择您的团队

#### 检查Capabilities
确保以下功能已启用：
- ✅ **Near Field Communication Tag Reading** (NFC)
- ✅ **Sign in with Apple** (如果使用)
- ✅ **Push Notifications** (如果使用)

---

## 4️⃣ 推送通知配置（如果使用）

### 步骤 4.1: 创建APNs证书
1. Apple Developer → Certificates
2. 点击 **+** 创建新证书
3. 选择 **Apple Push Notification service SSL (Sandbox & Production)**
4. 选择 App ID: `com.jay.phygitalasset`
5. 生成并下载证书

### 步骤 4.2: 上传到后端服务
如果使用推送通知服务（如Firebase、OneSignal等），需要：
1. 上传新的APNs证书
2. 更新Bundle ID配置
3. 测试推送功能

---

## 5️⃣ 其他可能需要更新的服务

### Firebase（如果使用）
1. 访问 https://console.firebase.google.com
2. 选择项目
3. 项目设置 → iOS Apps
4. 添加新应用或更新现有应用的Bundle ID
5. 下载新的 `GoogleService-Info.plist`
6. 替换项目中的文件

### 崩溃报告服务（Crashlytics/Sentry等）
1. 登录服务平台
2. 更新应用的Bundle ID配置
3. 如果需要，重新集成SDK

### 分析服务（Google Analytics/Mixpanel等）
1. 更新应用标识符
2. 验证事件跟踪正常

---

## 📋 验证清单

### Google Sign-In验证
- [ ] Bundle ID已在Google Console更新
- [ ] URL Scheme在Info.plist中正确配置
- [ ] 可以打开Google登录页面
- [ ] 可以成功登录
- [ ] 登录后用户信息正确显示

### Facebook Login验证
- [ ] Bundle ID已在Facebook开发者平台更新
- [ ] FacebookAppID在Info.plist中正确
- [ ] URL Scheme在Info.plist中正确配置
- [ ] 可以打开Facebook登录页面
- [ ] 可以成功登录
- [ ] 登录后用户信息正确显示

### Apple Developer验证
- [ ] 新App ID已创建 (com.jay.phygitalasset)
- [ ] Development Provisioning Profile已创建
- [ ] Distribution Provisioning Profile已创建
- [ ] 证书已安装到Xcode
- [ ] Xcode中Team和Signing配置正确
- [ ] 可以在真机上运行
- [ ] 可以构建Archive用于发布

---

## 🔍 常见问题排查

### Google登录失败

**问题**: 点击Google登录后返回应用，显示错误
**原因**: URL Scheme配置不正确
**解决**:
1. 检查 `Info.plist` 中的 URL Scheme
2. 确认格式：`com.googleusercontent.apps.YOUR_CLIENT_ID`
3. YOUR_CLIENT_ID 应该是Google Console中显示的完整Client ID

### Facebook登录失败

**问题**: Facebook登录后返回应用失败
**原因**: Bundle ID不匹配或URL Scheme错误
**解决**:
1. 检查Facebook App配置中的Bundle ID
2. 检查 `Info.plist` 中的 `FacebookAppID`
3. 检查 URL Scheme: `fbYOUR_APP_ID`

### Xcode签名错误

**问题**: "Failed to create provisioning profile"
**原因**: Bundle ID不存在或Provisioning Profile未下载
**解决**:
1. 确认App ID已在Apple Developer创建
2. 确认Provisioning Profile已生成并下载
3. 在Xcode中刷新：Preferences → Accounts → Download Manual Profiles
4. 或者使用 Automatic Signing（推荐）

### 真机运行失败

**问题**: 无法在真机上运行
**原因**: 设备未添加到Provisioning Profile
**解决**:
1. Apple Developer → Devices
2. 添加您的设备UDID
3. 重新生成Provisioning Profile并下载
4. 在Xcode中刷新Profile

---

## 📱 测试步骤

### 完整测试流程

#### 1. Google登录测试
```
1. 打开应用
2. 点击 "Sign in with Google" 
3. 选择Google账号
4. 授权应用权限
5. 验证：返回应用后自动登录
6. 验证：用户信息正确显示
```

#### 2. Facebook登录测试
```
1. 打开应用
2. 点击 "Sign in with Facebook"
3. 输入Facebook账号密码
4. 授权应用权限
5. 验证：返回应用后自动登录
6. 验证：用户信息正确显示
```

#### 3. Apple Sign In测试（如果使用）
```
1. 打开应用
2. 点击 "Sign in with Apple"
3. 使用Face ID/Touch ID确认
4. 验证：自动登录成功
```

---

## 🛠️ Xcode配置详解

### Automatic Signing（推荐）

#### 优点
- ✅ 自动管理证书和Profile
- ✅ 自动续期
- ✅ 简化配置流程

#### 设置方法
1. Xcode项目 → Target → **Signing & Capabilities**
2. 勾选 **Automatically manage signing**
3. **Team**: 选择您的开发团队
4. Bundle ID会自动识别：`com.jay.phygitalasset`
5. Xcode会自动：
   - 创建开发证书（如果需要）
   - 创建Provisioning Profile
   - 注册设备

### Manual Signing（高级用户）

#### 何时使用
- 需要精细控制证书
- 多团队协作
- 企业发布

#### 设置方法
1. 取消勾选 **Automatically manage signing**
2. **Debug** 配置:
   - Provisioning Profile: "Phygital Asset Development"
3. **Release** 配置:
   - Provisioning Profile: "Phygital Asset App Store"

---

## 📝 配置文件检查

### Info.plist 完整配置示例

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Bundle信息 -->
    <key>CFBundleIdentifier</key>
    <string>com.jay.phygitalasset</string>
    
    <key>CFBundleDisplayName</key>
    <string>Phygital Asset</string>
    
    <!-- URL Schemes -->
    <key>CFBundleURLTypes</key>
    <array>
        <!-- Google Sign-In -->
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLName</key>
            <string>GoogleSignIn</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
            </array>
        </dict>
        
        <!-- Facebook Login -->
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLName</key>
            <string>FacebookLogin</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>fbYOUR_FACEBOOK_APP_ID</string>
            </array>
        </dict>
    </array>
    
    <!-- Facebook配置 -->
    <key>FacebookAppID</key>
    <string>YOUR_FACEBOOK_APP_ID</string>
    
    <key>FacebookDisplayName</key>
    <string>Phygital Asset</string>
    
    <!-- Google配置 -->
    <key>GIDClientID</key>
    <string>YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com</string>
</dict>
</plist>
```

---

## 🔐 安全检查

### 步骤 1: 验证Bundle ID一致性
```bash
# 检查所有配置文件中的Bundle ID
cd /Users/Jay/Documents/TreasureHuntHK

# 1. project.pbxproj
grep "PRODUCT_BUNDLE_IDENTIFIER" "Phygital Asset.xcodeproj/project.pbxproj"

# 2. Info.plist
grep -A 1 "CFBundleIdentifier" "Phygital-Asset-Info.plist"

# 应该都显示: com.jay.phygitalasset
```

### 步骤 2: 验证Entitlements
```bash
# 检查entitlements文件
cat "Phygital Asset/Phygital_Asset.entitlements"
cat "Phygital Asset/Phygital AssetDebug.entitlements"
```

---

## 🎯 快速检查命令

### 一键验证配置
```bash
cd /Users/Jay/Documents/TreasureHuntHK

echo "📋 检查Bundle ID配置..."
echo ""
echo "1. Xcode Project:"
grep -m 1 "PRODUCT_BUNDLE_IDENTIFIER" "Phygital Asset.xcodeproj/project.pbxproj" | head -1

echo ""
echo "2. 文件结构:"
ls -d "Phygital Asset"* 2>/dev/null

echo ""
echo "3. 主App文件:"
ls "Phygital Asset/"Phygital_AssetApp.swift

echo ""
echo "✅ 如果以上都显示 'Phygital Asset' 或 'phygitalasset'，配置正确！"
```

---

## 📞 需要帮助？

### Google Sign-In问题
- 文档: https://developers.google.com/identity/sign-in/ios
- 确认Client ID正确
- 确认URL Scheme正确

### Facebook Login问题  
- 文档: https://developers.facebook.com/docs/facebook-login/ios
- 确认App ID正确
- 确认Bundle ID匹配

### Apple Developer问题
- 支持: https://developer.apple.com/support/
- 确认App ID已创建
- 确认Provisioning Profile已安装

---

## 🎉 完成后

所有第三方服务更新完成后：

1. ✅ 在Xcode中运行应用（⌘+R）
2. ✅ 测试所有登录方式
3. ✅ 验证用户信息正确获取
4. ✅ 确认应用名称显示为 "Phygital Asset"
5. ✅ 准备提交App Store（如果需要）

---

## 📝 更新记录模板

完成所有更新后，请记录：

```
✅ Google Sign-In
  - Console更新日期: ____
  - Client ID: ____
  - 测试状态: [ ] 通过 / [ ] 失败

✅ Facebook Login
  - 平台更新日期: ____
  - App ID: ____
  - 测试状态: [ ] 通过 / [ ] 失败

✅ Apple Developer
  - App ID创建日期: ____
  - Profile创建日期: ____
  - 测试状态: [ ] 通过 / [ ] 失败
```

---

## 更新日期
2025-10-27

## Bundle ID
- 旧: `com.jay.treasurehunt`
- 新: `com.jay.phygitalasset`
- 状态: ✅ 已更新

