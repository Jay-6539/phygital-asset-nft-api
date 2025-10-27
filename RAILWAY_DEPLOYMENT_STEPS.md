# 🚀 Railway部署 - GitHub仓库设置指南

## 📋 步骤1：创建GitHub仓库

### 1.1 访问GitHub
- 打开 https://github.com
- 登录您的GitHub账号

### 1.2 创建新仓库
- 点击右上角的 "+" 按钮
- 选择 "New repository"
- 仓库名称：`phygital-asset-nft-api`
- 描述：`Phygital Asset NFT API Server for Amoy Testnet`
- 选择 "Public"（Railway需要访问权限）
- **不要**勾选 "Add a README file"
- **不要**勾选 "Add .gitignore"
- **不要**勾选 "Choose a license"
- 点击 "Create repository"

### 1.3 获取仓库URL
创建完成后，GitHub会显示类似这样的URL：
```
https://github.com/你的用户名/phygital-asset-nft-api.git
```

## 📋 步骤2：推送代码到GitHub

### 2.1 添加远程仓库
```bash
git remote add origin https://github.com/你的用户名/phygital-asset-nft-api.git
```

### 2.2 推送代码
```bash
git push -u origin main
```

## 📋 步骤3：Railway部署

### 3.1 访问Railway
- 打开 https://railway.app
- 使用GitHub账号登录

### 3.2 创建新项目
- 点击 "New Project"
- 选择 "Deploy from GitHub repo"
- 选择 `phygital-asset-nft-api` 仓库

### 3.3 配置环境变量
在Railway Dashboard的Variables标签页添加：

```
AMOY_RPC_URL=https://rpc-amoy.polygon.technology/
AMOY_CHAIN_ID=80002
CONTRACT_ADDRESS=0xA0fA27fC547D544528e9BE0cb6569E9B925e533E
AMOY_PRIVATE_KEY=你的私钥
NODE_ENV=production
```

### 3.4 自动部署
- Railway会自动检测package.json
- 自动安装依赖
- 自动启动服务

## 📋 步骤4：获取部署URL

部署完成后，Railway会提供一个URL，类似：
```
https://phygital-asset-nft-api-production.up.railway.app
```

## 📋 步骤5：测试部署

### 5.1 健康检查
```bash
curl https://your-railway-url.up.railway.app/api/health
```

### 5.2 NFT铸造测试
```bash
curl -X POST https://your-railway-url.up.railway.app/api/mint-thread \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-railway","username":"Railway Test"}'
```

## 📋 步骤6：更新iOS应用

在 `NFTManager.swift` 中更新API URL：

```swift
private let apiURL: String = {
    #if DEBUG
    return "http://127.0.0.1:3000/api"  // 开发环境
    #else
    return "https://your-railway-url.up.railway.app/api"  // 生产环境
    #endif
}()
```

## ✅ 完成！

现在您的API服务已经：
- ✅ 运行在Railway云端
- ✅ 24/7可用
- ✅ 全球可访问
- ✅ 自动HTTPS

## 🔧 故障排除

### 问题1：GitHub推送失败
- 检查GitHub用户名和仓库名
- 确认仓库是Public
- 检查网络连接

### 问题2：Railway部署失败
- 检查环境变量设置
- 确认私钥格式正确
- 查看Railway日志

### 问题3：API调用失败
- 检查部署URL
- 确认服务正在运行
- 验证环境变量
