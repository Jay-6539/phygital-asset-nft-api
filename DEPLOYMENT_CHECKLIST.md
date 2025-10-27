# ✅ 云端部署检查清单

## 📋 部署前准备

### ✅ 文件检查
- [x] `nft-api-server-amoy.js` - API服务主文件
- [x] `package.json` - 依赖配置
- [x] `vercel.json` - Vercel配置（如果使用Vercel）
- [x] `.gitignore` - Git忽略文件
- [x] `.env-amoy` - 环境变量模板

### ✅ 环境变量准备
- [x] `AMOY_RPC_URL` - Amoy测试网RPC地址
- [x] `AMOY_CHAIN_ID` - 链ID (80002)
- [x] `CONTRACT_ADDRESS` - 合约地址
- [x] `AMOY_PRIVATE_KEY` - 私钥（用于API操作）
- [x] `NODE_ENV` - 环境标识

## 🚀 部署选项

### 选项1：Railway（推荐）
**优势**：
- ✅ 免费额度充足
- ✅ 部署简单
- ✅ 自动HTTPS
- ✅ 环境变量管理

**步骤**：
1. 访问 https://railway.app
2. GitHub登录
3. 创建新项目
4. 连接GitHub仓库
5. 设置环境变量
6. 自动部署

### 选项2：Vercel
**优势**：
- ✅ 全球CDN
- ✅ 自动扩展
- ✅ 免费额度

**步骤**：
1. 访问 https://vercel.com
2. GitHub登录
3. 导入项目
4. 配置环境变量
5. 部署

## 📱 部署后更新

### iOS应用配置更新
```swift
// NFTManager.swift
private let apiURL: String = {
    #if DEBUG
    return "http://127.0.0.1:3000/api"  // 开发环境
    #else
    return "https://your-deployed-url.com/api"  // 生产环境
    #endif
}()
```

### 测试API功能
```bash
# 健康检查
curl https://your-deployed-url.com/api/health

# NFT铸造测试
curl -X POST https://your-deployed-url.com/api/mint-thread \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-cloud","username":"Cloud Test"}'
```

## ✅ 部署完成验证

### API服务验证
- [ ] 健康检查端点正常
- [ ] NFT铸造功能正常
- [ ] 错误处理正常
- [ ] 日志输出正常

### iOS应用验证
- [ ] 应用可以连接云端API
- [ ] NFT铸造功能正常
- [ ] 错误处理正常
- [ ] 用户体验良好

## 🎯 预期结果

部署完成后，您将拥有：
- ✅ **24/7运行的API服务**
- ✅ **全球可访问的端点**
- ✅ **自动HTTPS支持**
- ✅ **自动扩展能力**
- ✅ **完整的NFT功能**

## 🔧 故障排除

### 常见问题
1. **部署失败** - 检查环境变量和依赖
2. **API调用失败** - 检查网络和配置
3. **iOS连接失败** - 检查URL和网络权限

### 调试工具
- Railway/Vercel Dashboard日志
- 浏览器开发者工具
- iOS模拟器网络日志
