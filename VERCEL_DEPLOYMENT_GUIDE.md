# 🚀 Vercel部署指南

## 📋 部署步骤

### 1. 登录Vercel
```bash
npx vercel login
```
- 在浏览器中打开显示的链接
- 完成GitHub/Google登录
- 返回终端确认

### 2. 初始化项目
```bash
npx vercel init
```
- 项目名称：`phygital-asset-nft-api`
- 选择框架：`Other`
- 确认设置

### 3. 设置环境变量
在Vercel Dashboard中设置以下环境变量：

```
AMOY_RPC_URL=https://rpc-amoy.polygon.technology/
AMOY_CHAIN_ID=80002
CONTRACT_ADDRESS=0xA0fA27fC547D544528e9BE0cb6569E9B925e533E
AMOY_PRIVATE_KEY=你的私钥
NODE_ENV=production
```

### 4. 部署
```bash
npx vercel --prod
```

### 5. 获取部署URL
部署完成后，您会得到一个URL，例如：
`https://phygital-asset-nft-api.vercel.app`

## 🔧 手动部署步骤

如果CLI有问题，可以手动部署：

### 1. 访问Vercel网站
- 打开 https://vercel.com
- 使用GitHub登录

### 2. 导入项目
- 点击 "New Project"
- 选择 "Import Git Repository"
- 选择您的项目仓库

### 3. 配置项目
- **Framework Preset**: Other
- **Root Directory**: ./
- **Build Command**: (留空)
- **Output Directory**: ./
- **Install Command**: npm install

### 4. 设置环境变量
在Environment Variables部分添加：
```
AMOY_RPC_URL=https://rpc-amoy.polygon.technology/
AMOY_CHAIN_ID=80002
CONTRACT_ADDRESS=0xA0fA27fC547D544528e9BE0cb6569E9B925e533E
AMOY_PRIVATE_KEY=你的私钥
NODE_ENV=production
```

### 5. 部署
- 点击 "Deploy"
- 等待部署完成

## ✅ 部署验证

部署完成后，测试以下端点：

```bash
# 健康检查
curl https://your-app-name.vercel.app/api/health

# NFT铸造测试
curl -X POST https://your-app-name.vercel.app/api/mint-thread \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-cloud","username":"Cloud Test"}'
```

## 📱 更新iOS应用

部署成功后，更新iOS应用配置：

```swift
// 在NFTManager.swift中
private let apiURL: String = {
    #if DEBUG
    return "http://127.0.0.1:3000/api"  // 开发环境
    #else
    return "https://your-app-name.vercel.app/api"  // 生产环境
    #endif
}()
```
