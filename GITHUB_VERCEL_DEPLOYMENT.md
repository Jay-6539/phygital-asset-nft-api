# 🚀 快速部署到Vercel - GitHub集成方法

## 📋 步骤1：准备GitHub仓库

### 1.1 创建.gitignore文件
```bash
echo "node_modules/
.env
.env.local
.env.production
*.log
.DS_Store" > .gitignore
```

### 1.2 初始化Git仓库
```bash
git init
git add .
git commit -m "Initial commit: Phygital Asset NFT API"
```

### 1.3 推送到GitHub
```bash
# 在GitHub上创建新仓库，然后：
git remote add origin https://github.com/你的用户名/phygital-asset-nft-api.git
git push -u origin main
```

## 📋 步骤2：Vercel部署

### 2.1 访问Vercel
- 打开 https://vercel.com
- 使用GitHub账号登录

### 2.2 导入项目
- 点击 "New Project"
- 选择 "Import Git Repository"
- 选择 `phygital-asset-nft-api` 仓库

### 2.3 配置项目
- **Framework Preset**: Other
- **Root Directory**: `./`
- **Build Command**: (留空)
- **Output Directory**: `./`
- **Install Command**: `npm install`

### 2.4 设置环境变量
在Environment Variables部分添加：

```
AMOY_RPC_URL = https://rpc-amoy.polygon.technology/
AMOY_CHAIN_ID = 80002
CONTRACT_ADDRESS = 0xA0fA27fC547D544528e9BE0cb6569E9B925e533E
AMOY_PRIVATE_KEY = 你的私钥
NODE_ENV = production
```

### 2.5 部署
- 点击 "Deploy"
- 等待部署完成（通常2-3分钟）

## 📋 步骤3：获取部署URL

部署完成后，您会得到类似这样的URL：
`https://phygital-asset-nft-api-xxx.vercel.app`

## 📋 步骤4：测试API

```bash
# 健康检查
curl https://your-app-name.vercel.app/api/health

# NFT铸造测试
curl -X POST https://your-app-name.vercel.app/api/mint-thread \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-cloud","username":"Cloud Test"}'
```

## 📋 步骤5：更新iOS应用

在 `NFTManager.swift` 中更新API URL：

```swift
private let apiURL: String = {
    #if DEBUG
    return "http://127.0.0.1:3000/api"  // 开发环境
    #else
    return "https://your-app-name.vercel.app/api"  // 生产环境
    #endif
}()
```

## ✅ 完成！

现在您的API服务已经：
- ✅ 24/7运行在云端
- ✅ 全球可访问
- ✅ 自动HTTPS
- ✅ 自动扩展

## 🔧 故障排除

### 问题1：部署失败
- 检查环境变量是否正确设置
- 确保私钥格式正确（64位十六进制）

### 问题2：API调用失败
- 检查Vercel函数日志
- 验证合约地址和RPC URL

### 问题3：iOS应用无法连接
- 确认API URL正确
- 检查网络连接
