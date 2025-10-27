# 🚀 Vercel部署指南（替代Railway）

## 📋 为什么选择Vercel？

- ✅ **更稳定** - 没有缓存问题
- ✅ **更简单** - 自动检测配置
- ✅ **更快速** - 全球CDN
- ✅ **免费额度充足**

## 🔧 步骤1：访问Vercel

1. 打开浏览器访问：https://vercel.com
2. 使用GitHub账号登录
3. 点击 "New Project"

## 🔧 步骤2：导入项目

1. 选择 "Import Git Repository"
2. 找到 `phygital-asset-nft-api` 仓库
3. 点击 "Import"

## 🔧 步骤3：配置项目

### 项目设置
- **Framework Preset**: Other
- **Root Directory**: `./`
- **Build Command**: (留空)
- **Output Directory**: `./`
- **Install Command**: `npm install`

### 环境变量
在Environment Variables部分添加：

```
AMOY_RPC_URL=https://rpc-amoy.polygon.technology/
AMOY_CHAIN_ID=80002
CONTRACT_ADDRESS=0xA0fA27fC547D544528e9BE0cb6569E9B925e533E
AMOY_PRIVATE_KEY=你的私钥
NODE_ENV=production
```

## 🔧 步骤4：部署

1. 点击 "Deploy"
2. 等待部署完成（通常2-3分钟）
3. 获取部署URL

## 🔧 步骤5：测试API

部署完成后，测试API：

```bash
# 健康检查
curl https://your-vercel-url.vercel.app/api/health

# NFT铸造测试
curl -X POST https://your-vercel-url.vercel.app/api/mint-thread \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-vercel","username":"Vercel Test"}'
```

## 🔧 步骤6：更新iOS应用

在 `NFTManager.swift` 中更新API URL：

```swift
private let apiURL: String = {
    #if DEBUG
    return "http://127.0.0.1:3000/api"  // 开发环境
    #else
    return "https://your-vercel-url.vercel.app/api"  // 生产环境
    #endif
}()
```

## ✅ 预期结果

部署完成后，您将拥有：
- ✅ **24/7运行的API服务**
- ✅ **全球可访问的HTTPS端点**
- ✅ **自动扩展和监控**
- ✅ **企业级可靠性**

## 🎯 优势

相比Railway，Vercel的优势：
- ✅ **更稳定** - 没有依赖冲突问题
- ✅ **更快速** - 全球CDN加速
- ✅ **更简单** - 自动配置
- ✅ **更可靠** - 企业级服务
