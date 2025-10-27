# Apple Developer 详细操作步骤

## 📍 找到 Identifiers 的详细指引

### 第一步：登录Apple Developer

1. 打开浏览器，访问：**https://developer.apple.com/account**
2. 点击右上角的 **登录** (Sign In)
3. 使用您的Apple ID登录
4. 如果有双重认证，完成验证

### 第二步：进入Account页面

登录后，您应该看到以下页面之一：

#### 情况A：看到侧边栏菜单（新版界面）
页面左侧应该有一个侧边栏，包含：
- Overview（概览）
- **Certificates, Identifiers & Profiles** ← 点击这个
- Keys
- Devices
- 其他选项...

#### 情况B：看到卡片式界面（旧版界面）
页面中间应该有多个卡片/方块，找到：
- **Certificates, Identifiers & Profiles** 卡片 ← 点击这个

#### 情况C：直接访问链接
如果找不到，直接访问：
```
https://developer.apple.com/account/resources/identifiers/list
```

### 第三步：进入 Identifiers 页面

点击 **Certificates, Identifiers & Profiles** 后：

#### 您会看到左侧菜单栏：
```
Certificates, Identifiers & Profiles
├─ Certificates
├─ Identifiers  ← 点击这个
├─ Devices
├─ Profiles
└─ Keys
```

或者页面顶部有标签栏：
```
[Certificates] [Identifiers] [Devices] [Profiles] [Keys]
              ↑ 点击这个
```

### 第四步：查看 Identifiers 列表

进入 Identifiers 页面后：

#### 页面布局
```
┌─────────────────────────────────────────────┐
│ Identifiers                          [+]    │ ← 右上角有+号
├─────────────────────────────────────────────┤
│ 左侧筛选器：                                 │
│ □ App IDs                                   │
│ □ Service IDs                               │
│ □ Website Push IDs                          │
│ ...                                         │
├─────────────────────────────────────────────┤
│ 列表：                                       │
│ Name              | Platform | Identifier   │
│ ─────────────────────────────────────────── │
│ Your existing apps...                       │
└─────────────────────────────────────────────┘
```

#### 如果列表是空的
- 说明您还没有创建任何App ID
- 这是正常的，继续下一步创建

### 第五步：创建新的 App ID

#### 5.1 点击 + 按钮
在 Identifiers 页面右上角，点击蓝色的 **+** (加号)按钮

#### 5.2 选择类型
您会看到 "Register a new identifier" 页面：

**选择 App IDs**：
```
● App IDs              ← 选择这个（圆点应该被选中）
○ Service IDs
○ Website Push IDs
○ Merchant IDs
○ iCloud Containers
...
```

点击右上角蓝色 **Continue** 按钮

#### 5.3 选择 App ID 类型
下一个页面：

**选择 App**：
```
● App                  ← 选择这个
○ App Clip
```

点击 **Continue**

#### 5.4 填写 App ID 信息

**Description（描述）**：
```
Phygital Asset
```
这是给您自己看的名称，方便识别

**Bundle ID（重要！）**：
选择 **Explicit**（明确的）
```
● Explicit Bundle ID   ← 选中这个
  Bundle ID: com.jay.phygitalasset  ← 在这里输入
  
○ Wildcard Bundle ID
```

⚠️ 注意：
- 必须选择 "Explicit"
- 必须完全匹配：`com.jay.phygitalasset`
- 不能有拼写错误
- 不能有空格
- 全小写

#### 5.5 选择 Capabilities（功能）

在页面下方，勾选您需要的功能：

**必须勾选**：
- ✅ **NFC Tag Reading** ← 您的应用需要NFC功能，必须勾选！

**根据需要勾选**：
- ✅ **Sign in with Apple** （如果使用Apple登录）
- ✅ **Push Notifications** （如果使用推送通知）
- ✅ **Associated Domains** （如果使用Universal Links）
- ✅ **App Groups** （如果使用）
- ✅ **iCloud** （如果使用云同步）

其他功能根据实际需要选择。

#### 5.6 提交创建
1. 滚动到页面底部
2. 点击蓝色 **Continue** 按钮
3. 检查信息是否正确：
   - Description: Phygital Asset
   - Bundle ID: com.jay.phygitalasset
   - Capabilities: NFC Tag Reading 等
4. 点击 **Register** 按钮

✅ 成功！您应该看到 "Registration Complete" 或类似提示

---

## 第六步：创建 Provisioning Profile

### 6.1 进入 Profiles 页面

#### 方式1：侧边栏
左侧菜单 → 点击 **Profiles**

#### 方式2：标签栏
顶部标签 → 点击 **Profiles**

#### 方式3：直接链接
访问：https://developer.apple.com/account/resources/profiles/list

### 6.2 创建 Development Profile

#### 点击 + 按钮
在 Profiles 页面右上角，点击蓝色的 **+** 按钮

#### 选择 Profile 类型
在 "Register a New Provisioning Profile" 页面：

**Development 部分**，选择：
```
● iOS App Development  ← 选择这个
```

点击 **Continue**

#### 选择 App ID
在下拉菜单中选择：
```
Phygital Asset (com.jay.phygitalasset)  ← 选择这个
```

如果找不到，说明上一步的App ID创建可能没成功，请返回检查。

点击 **Continue**

#### 选择证书 (Certificate)

**如果您已有开发证书**：
- 勾选您的证书（通常显示您的名字）

**如果没有证书**：
- 返回 Certificates 页面
- 点击 + 创建 **Apple Development** 证书
- 需要生成 CSR（证书签名请求）：
  ```
  Mac上操作：
  1. 打开"钥匙串访问" (Keychain Access)
  2. 菜单栏 → 钥匙串访问 → 证书助理 → 从证书颁发机构请求证书
  3. 填写：
     - 用户电子邮件地址：您的邮箱
     - 常用名称：您的名字
     - 请求是：存储到磁盘
  4. 保存 CSR 文件
  5. 在Apple Developer上传此文件
  6. 下载证书并双击安装
  ```

勾选证书后，点击 **Continue**

#### 选择设备 (Devices)

**如果您已注册设备**：
- 勾选您要测试的iPhone设备

**如果没有设备**：
- 返回 Devices 页面
- 点击 + 添加设备
- 需要设备的 UDID：
  ```
  获取iPhone UDID方法：
  1. iPhone连接到Mac
  2. 打开Finder（macOS Catalina+）或iTunes
  3. 选择您的iPhone
  4. 点击设备名称下方的信息
  5. 会显示序列号，再次点击会显示UDID
  6. 右键点击UDID → 拷贝
  ```

勾选设备后，点击 **Continue**

#### 命名 Profile
输入Provisioning Profile名称：
```
Phygital Asset Development
```

点击 **Generate**

#### 下载 Profile
1. 等待生成完成
2. 点击 **Download** 按钮下载 `.mobileprovision` 文件
3. 保存到桌面或Downloads文件夹

### 6.3 安装 Provisioning Profile

**方式1：双击安装**
```
双击下载的 .mobileprovision 文件
→ 自动导入到Xcode
```

**方式2：拖拽到Xcode**
```
拖拽 .mobileprovision 文件到Xcode图标上
```

**方式3：手动复制**
```bash
# 复制到Profiles目录
cp ~/Downloads/Phygital_Asset_Development.mobileprovision \
   ~/Library/MobileDevice/Provisioning\ Profiles/
```

---

## 第七步：在 Xcode 中配置签名

### 7.1 打开项目
```
打开：Phygital Asset.xcodeproj
```

### 7.2 进入 Signing 设置

1. 在左侧项目导航器中，点击最上方的蓝色项目图标
2. 在中间区域，选择 **TARGETS** 下的 **Phygital Asset**
3. 在顶部标签栏，选择 **Signing & Capabilities**

### 7.3 配置签名（推荐方式：Automatic）

#### Automatic Signing（推荐）
```
✅ Automatically manage signing  ← 勾选这个

Team: 
  [选择您的开发团队]  ← 从下拉菜单选择

Bundle Identifier:
  com.jay.phygitalasset  ← 应该自动显示
  
Provisioning Profile:
  Xcode Managed Profile  ← 自动管理
  
Signing Certificate:
  Apple Development: Your Name  ← 自动选择
```

**优点**：
- Xcode自动处理一切
- 自动续期
- 无需手动下载Profile

#### Manual Signing（高级用户）
```
☐ Automatically manage signing  ← 取消勾选

Team:
  [选择您的开发团队]
  
Provisioning Profile:
  Debug: Phygital Asset Development  ← 选择您下载的Profile
  Release: Phygital Asset App Store  ← 如果有
  
Signing Certificate:
  Apple Development: Your Name
```

### 7.4 检查状态

在 Signing 区域，您应该看到：

**成功状态**：
```
✅ Signing for "Phygital Asset" requires a development team. 
   Select a development team in the Signing & Capabilities editor.
   
   Team: Your Team Name
   ✓ Phygital Asset
```

**如果看到错误**：
```
❌ Failed to register bundle identifier
   → 返回Apple Developer检查App ID是否创建成功

❌ No profiles for 'com.jay.phygitalasset' were found
   → 返回创建Provisioning Profile

❌ Signing for "Phygital Asset" requires a development team
   → 在Team下拉菜单选择您的团队
```

### 7.5 验证 Capabilities

在同一个 **Signing & Capabilities** 标签：

检查以下功能是否已添加：
- ✅ **Near Field Communication Tag Reading** (NFC)
  - 如果没有，点击 **+ Capability** 添加
- ✅ **Sign in with Apple**（如果使用）
- ✅ **Push Notifications**（如果使用）

---

## 🔍 找不到的常见情况

### 情况1：找不到 "Certificates, Identifiers & Profiles"

**可能原因**：
- 您的Apple Developer账号没有开发者权限
- 您不是团队管理员
- 页面还在加载

**解决方法**：
1. 确认您的Apple Developer账号已付费（$99/年）
2. 直接访问：https://developer.apple.com/account/resources
3. 刷新页面（⌘+R）
4. 尝试不同浏览器（Safari/Chrome）

### 情况2：Identifiers 列表是空的

**这是正常的！**
- 说明您还没有创建过App ID
- 点击右上角的 **+** 开始创建即可

### 情况3：Bundle ID已被使用

**错误提示**：
```
An App ID with Identifier 'com.jay.phygitalasset' is not available.
```

**解决方法**：
1. 使用不同的Bundle ID，例如：
   - `com.jay.phygital.asset`
   - `com.jay.app.phygitalasset`
   - `com.yourcompany.phygitalasset`
2. 如果是您自己之前创建的，在列表中找到并重用
3. 如果被其他人使用，必须更换

### 情况4：看不到 NFC Tag Reading 选项

**可能原因**：
- 滚动页面，功能列表可能很长
- 搜索框中输入 "NFC" 快速定位

**NFC Tag Reading 位置**：
在 Capabilities 列表中，按字母顺序排列，在 **N** 部分
```
...
□ Multipath
□ Network Extensions
✅ NFC Tag Reading  ← 勾选这个
□ Personal VPN
...
```

---

## 🖼️ 界面参考

### Identifiers 页面应该长这样：

```
╔═══════════════════════════════════════════════════╗
║ Certificates, Identifiers & Profiles              ║
╠═══════════════════════════════════════════════════╣
║ [Certificates] [Identifiers] [Devices] [Profiles] ║
║                     ↑ 当前页                      ║
╠═══════════════════════════════════════════════════╣
║                                             [+]   ║ ← 加号按钮
║ ───────────────────────────────────────────────  ║
║ Filter: App IDs ▼                                ║
║                                                   ║
║ Name                Platform    Identifier        ║
║ ───────────────────────────────────────────────  ║
║ (您现有的App IDs会显示在这里)                     ║
║ ...                                               ║
╚═══════════════════════════════════════════════════╝
```

### 创建 App ID 页面应该长这样：

```
╔═══════════════════════════════════════════════════╗
║ Register a new identifier                         ║
╠═══════════════════════════════════════════════════╣
║ Select a type:                                    ║
║ ● App IDs          ← 选中                         ║
║ ○ Service IDs                                     ║
║ ○ Website Push IDs                                ║
║                                    [Continue] →   ║
╠═══════════════════════════════════════════════════╣
║ Select a type:                                    ║
║ ● App             ← 选中                          ║
║ ○ App Clip                                        ║
║                                    [Continue] →   ║
╠═══════════════════════════════════════════════════╣
║ Description:                                      ║
║ ┌───────────────────────────────────────────┐    ║
║ │ Phygital Asset                            │    ║
║ └───────────────────────────────────────────┘    ║
║                                                   ║
║ Bundle ID:                                        ║
║ ● Explicit Bundle ID                              ║
║ ┌───────────────────────────────────────────┐    ║
║ │ com.jay.phygitalasset                     │    ║
║ └───────────────────────────────────────────┘    ║
║                                                   ║
║ Capabilities:                                     ║
║ ✅ NFC Tag Reading                                ║
║ □ Push Notifications                              ║
║ ...                                               ║
║                                    [Continue] →   ║
╚═══════════════════════════════════════════════════╝
```

---

## 💡 快速访问链接

如果您还是找不到，直接点击这些链接：

### 主要页面
```
Apple Developer Account:
https://developer.apple.com/account

Certificates, Identifiers & Profiles:
https://developer.apple.com/account/resources

Identifiers 列表:
https://developer.apple.com/account/resources/identifiers/list

Profiles 列表:
https://developer.apple.com/account/resources/profiles/list

Certificates 列表:
https://developer.apple.com/account/resources/certificates/list

Devices 列表:
https://developer.apple.com/account/resources/devices/list
```

### 创建新资源
```
创建新 App ID:
https://developer.apple.com/account/resources/identifiers/add/bundleId

创建新 Profile:
https://developer.apple.com/account/resources/profiles/add

创建新证书:
https://developer.apple.com/account/resources/certificates/add
```

---

## 🎬 视频教程参考

如果您是视觉学习者，可以在YouTube搜索：
```
"How to create App ID in Apple Developer"
"How to create iOS Provisioning Profile"
```

---

## 📞 还是找不到？

### 检查账号状态

1. **访问**：https://developer.apple.com/account
2. 查看页面顶部是否显示：
   ```
   "Apple Developer Program"
   Status: Active
   ```

3. **如果显示 "Join the Apple Developer Program"**：
   - 说明您还没有付费订阅
   - 需要加入Apple Developer Program（$99/年）
   - 访问：https://developer.apple.com/programs/enroll/

4. **如果您是团队成员**：
   - 联系团队管理员
   - 确认您有 "Developer" 或 "Admin" 权限
   - "App Manager" 角色可能看不到完整功能

---

## ✅ 成功标志

当您成功创建后，应该能看到：

### Identifiers 列表中
```
Name                Platform    Identifier
Phygital Asset      iOS         com.jay.phygitalasset
```

### Profiles 列表中
```
Name                              Type              Status
Phygital Asset Development        Development       Active
```

---

## 🆘 仍然需要帮助？

### 联系方式
- Apple Developer Support: https://developer.apple.com/contact/
- 电话支持（如果有权限）
- 开发者论坛：https://developer.apple.com/forums/

### 提供信息
联系支持时准备：
- 您的Apple ID
- Bundle Identifier: com.jay.phygitalasset
- 遇到的具体错误信息
- 截图

---

## 📝 备选方案：Automatic Signing

### 如果手动创建太复杂

您可以让Xcode自动处理：

1. 打开 `Phygital Asset.xcodeproj`
2. 选择 Target → **Signing & Capabilities**
3. ✅ 勾选 **Automatically manage signing**
4. **Team**: 选择您的团队
5. Xcode会自动：
   - 创建App ID（如果不存在）
   - 创建Provisioning Profile
   - 下载并安装

**这是最简单的方式！** 推荐新手使用。

---

## 更新日期
2025-10-27

