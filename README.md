# Treasure Hunt HK

香港历史建筑寻宝应用

## 📱 项目概述

这是一个iOS应用，帮助用户探索香港的历史建筑，通过NFC技术进行签到（Check-in），查看地图上的历史地标，并记录访问历史。

## 🎯 主要功能

- **地图浏览** - 查看香港历史建筑在地图上的位置
- **NFC签到** - 使用NFC标签在历史建筑处签到
- **社交登录** - 支持Facebook和Google登录
- **访问历史** - 记录和查看所有签到历史
- **GPS导航** - 导航到目标历史建筑
- **云端同步** - 使用Supabase进行数据云端存储

## 🏗️ 项目结构

```
TreasureHuntHK/
├── Treasure Hunt, Hong Kong Park/           # 源代码
│   ├── ContentView.swift                    # 主界面（5799行）
│   ├── SocialLoginManager.swift             # 社交登录管理
│   ├── SupabaseManager.swift                # 云端数据管理
│   ├── PersistenceManager.swift             # 本地数据持久化
│   ├── HistoricBuildingsManager.swift       # 历史建筑数据管理
│   ├── Assets.xcassets/                     # 图片资源
│   └── GoogleService-Info.plist             # Google服务配置
├── Treasure Hunt, Hong Kong Park.xcodeproj/ # Xcode项目
├── Treasure Hunt, Hong Kong Park.xcworkspace/ # Xcode工作空间
├── Pods/                                    # CocoaPods依赖
├── Podfile                                  # CocoaPods配置
└── README.md                                # 本文件
```

## 🛠️ 技术栈

### 开发语言
- Swift
- SwiftUI

### 依赖管理
- CocoaPods

### 主要依赖包
- **FBSDKCoreKit** - Facebook SDK核心
- **FBSDKLoginKit** - Facebook登录
- **GoogleSignIn** - Google登录

### 后端服务
- **Supabase** - 云端数据库和存储

## 🚀 快速开始

### 环境要求

- macOS 13.0+
- Xcode 15.0+
- iOS 15.0+
- CocoaPods 1.10+

### 安装步骤

1. **打开终端，进入项目目录**
   ```bash
   cd ~/Documents/TreasureHuntHK
   ```

2. **安装CocoaPods依赖**
   ```bash
   pod install
   ```

3. **打开工作空间（重要！）**
   ```bash
   open "Treasure Hunt, Hong Kong Park.xcworkspace"
   ```
   
   ⚠️ **注意：** 必须打开 `.xcworkspace` 文件，不是 `.xcodeproj`

4. **选择目标设备**
   - 在Xcode顶部选择模拟器或真机

5. **运行项目**
   - 点击运行按钮（▶️）或按 `Cmd + R`

## ⚙️ 配置说明

### Facebook登录配置

需要在 `Info.plist` 中配置：
- `FacebookAppID` - Facebook应用ID
- `FacebookClientToken` - Facebook客户端令牌
- `CFBundleURLSchemes` - 包含 `fb[YOUR-APP-ID]`

### Google登录配置

需要配置：
- `GoogleService-Info.plist` 文件已包含在项目中
- 包含 `CLIENT_ID` 和其他Google服务配置

### Supabase配置

在 `SupabaseManager.swift` 中配置：
- Supabase URL
- Supabase API密钥

## 📦 核心文件说明

### ContentView.swift（253KB，5799行）
应用的主要界面，包含：
- 登录界面
- 地图显示
- NFC扫描
- 导航功能
- 历史记录查看

### SocialLoginManager.swift
管理Facebook和Google社交登录：
- `loginWithFacebook()` - Facebook登录
- `loginWithGoogle()` - Google登录
- `logout()` - 登出功能

### SupabaseManager.swift
管理云端数据同步：
- 上传签到记录
- 下载历史数据
- 用户数据管理

### PersistenceManager.swift
管理本地数据持久化：
- Core Data数据存储
- 本地缓存管理

### HistoricBuildingsManager.swift
管理历史建筑数据：
- 8000+历史建筑数据
- 地图标记管理
- GPS坐标处理

## 🔧 常见问题

### Q: 编译错误 "Multiple commands produce Framework"
**A:** 项目已优化，删除了重复的依赖。如果仍有问题：
```bash
cd ~/Documents/TreasureHuntHK
pod deintegrate
pod install
```

### Q: 无法登录Facebook/Google
**A:** 检查以下配置：
1. Info.plist中的Facebook和Google配置
2. GoogleService-Info.plist文件存在
3. Bundle ID匹配

### Q: 地图不显示
**A:** 确保：
1. 已授予位置权限
2. 网络连接正常
3. MapKit框架已正确链接

## 📊 项目统计

- **Swift文件数量：** 6个
- **代码行数：** 约6000+行
- **项目大小：** 170MB（包含所有依赖）
- **支持的历史建筑：** 8000+个

## 🎨 功能特色

### 1. 智能地图聚合
当地图缩小时，自动将附近的建筑聚合显示，避免标记重叠。

### 2. NFC保护机制
防止同一用户短时间内重复签到同一地点。

### 3. GPS精确导航
提供准确的路线规划和距离显示。

### 4. 云端数据同步
所有签到记录自动同步到云端，多设备数据共享。

### 5. 离线支持
本地缓存数据，即使离线也可以查看历史记录。

## 🔐 权限要求

应用需要以下权限：
- **位置权限** - 用于地图显示和导航
- **NFC权限** - 用于NFC标签扫描
- **网络权限** - 用于数据同步

## 📱 支持的设备

- iPhone (iOS 15.0+)
- iPad (iOS 15.0+)
- 需要NFC功能的设备（iPhone 7+）

## 🔄 更新日志

### 最近更新（2025年10月）
- ✅ 添加真实Facebook和Google登录
- ✅ 优化地图性能，支持8000+数据点
- ✅ 改进NFC扫描流程
- ✅ 添加云端数据同步
- ✅ 优化用户界面

## 📝 开发说明

### 添加新的历史建筑
在 `HistoricBuildingsManager.swift` 中添加建筑数据。

### 修改UI样式
主要颜色定义：
```swift
let appGreen = Color(red: 45/255, green: 156/255, blue: 73/255)
```

### 调试模式
在代码中搜索 `print("🔍")` 查看调试输出。

## 🤝 贡献

这是一个个人项目，目前不接受外部贡献。

## 📄 许可证

保留所有权利。

## 📞 联系方式

如有问题或建议，请通过项目Issues联系。

---

**版本：** 2.0  
**最后更新：** 2025年10月20日  
**开发者：** Jay

