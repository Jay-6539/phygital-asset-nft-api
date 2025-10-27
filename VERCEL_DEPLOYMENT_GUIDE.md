# 🚀 Vercel部署详细指南

## 📋 步骤1：访问Vercel

1. **打开浏览器**，访问：https://vercel.com
2. **点击右上角的 "Sign Up" 或 "Login"**
3. **选择 "Continue with GitHub"**
4. **授权Vercel访问您的GitHub账号**

## 📋 步骤2：导入项目

1. **登录后，点击 "New Project"**
2. **选择 "Import Git Repository"**
3. **找到 `phygital-asset-nft-api` 仓库**
4. **点击 "Import"**

## 📋 步骤3：配置项目

### 项目设置
- **Framework Preset**: Other
- **Root Directory**: `./`
- **Build Command**: (留空)
- **Output Directory**: `./`
- **Install Command**: `npm install`

### 环境变量设置
在 "Environment Variables" 部分添加：

```
AMOY_RPC_URL = https://rpc-amoy.polygon.technology/
AMOY_CHAIN_ID = 80002
CONTRACT_ADDRESS = 0xA0fA27fC547D544528e9BE0cb6569E9B925e533E
AMOY_PRIVATE_KEY = 你的私钥
NODE_ENV = production
```

**⚠️ 重要**：
- `AMOY_PRIVATE_KEY` 必须是64位十六进制字符串
- 不要包含 `0x` 前缀
- 确保私钥格式正确

## 📋 步骤4：部署

1. **点击 "Deploy" 按钮**
2. **等待部署完成**（通常2-3分钟）
3. **Vercel会自动提供HTTPS URL**

## 📋 步骤5：获取部署URL

部署完成后，您会得到类似这样的URL：
```
https://phygital-asset-nft-api-xxx.vercel.app
```

## 📋 步骤6：测试API

部署完成后，测试API功能：

```bash
# 健康检查
curl https://your-vercel-url.vercel.app/api/health

# NFT铸造测试
curl -X POST https://your-vercel-url.vercel.app/api/mint-thread \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-vercel","username":"Vercel Test"}'
```

## 📋 步骤7：更新iOS应用

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

## ✅ Vercel优势

相比Railway，Vercel的优势：
- ✅ **更稳定** - 没有依赖冲突问题
- ✅ **更快速** - 全球CDN加速
- ✅ **更简单** - 自动配置
- ✅ **更可靠** - 企业级服务
- ✅ **免费额度充足** - 适合开发和小型项目

## 🔧 故障排除

### 问题1：部署失败
- 检查环境变量设置
- 确认私钥格式正确
- 查看Vercel部署日志

### 问题2：API调用失败
- 检查部署URL
- 确认服务正在运行
- 验证环境变量

### 问题3：iOS应用连接失败
- 检查API URL配置
- 确认服务正在运行
- 验证网络连接

## 🎯 预期结果

部署完成后，您将拥有：
- ✅ **24/7运行的API服务**
- ✅ **全球可访问的HTTPS端点**
- ✅ **自动扩展和监控**
- ✅ **企业级可靠性**

## 🚀 开始部署

现在请访问 https://vercel.com 开始部署！