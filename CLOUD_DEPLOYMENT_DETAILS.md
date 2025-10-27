# 🌐 API服务云端部署详细步骤

## 📋 平台选择对比

### Vercel（推荐）
**优势**：
- ✅ 免费额度充足
- ✅ 部署简单快速
- ✅ 自动HTTPS
- ✅ 全球CDN

**部署步骤**：
```bash
# 1. 安装Vercel CLI
npm install -g vercel

# 2. 登录Vercel
vercel login

# 3. 在项目目录初始化
vercel init

# 4. 部署
vercel --prod
```

### Railway
**优势**：
- ✅ 支持数据库
- ✅ 环境变量管理
- ✅ 监控功能

**部署步骤**：
```bash
# 1. 安装Railway CLI
npm install -g @railway/cli

# 2. 登录Railway
railway login

# 3. 初始化项目
railway init

# 4. 部署
railway up
```

## 🔧 部署前准备

### 1. 创建生产环境配置
```bash
# 创建生产环境.env文件
cp .env-amoy .env.production

# 编辑生产环境配置
nano .env.production
```

### 2. 修改API服务代码
需要添加生产环境检测：
```javascript
const PORT = process.env.PORT || 3000;
const HOST = process.env.NODE_ENV === 'production' ? '0.0.0.0' : 'localhost';
```

### 3. 创建部署配置文件
**vercel.json** (Vercel部署):
```json
{
  "version": 2,
  "builds": [
    {
      "src": "nft-api-server-amoy.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "nft-api-server-amoy.js"
    }
  ]
}
```

## 📊 部署后验证

### 1. 健康检查
```bash
curl https://your-api-domain.vercel.app/api/health
```

### 2. NFT铸造测试
```bash
curl -X POST https://your-api-domain.vercel.app/api/mint-thread \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-cloud","username":"Cloud Test"}'
```

### 3. 更新iOS应用配置
```swift
// 修改NFTManager.swift
private let apiURL: String = {
    #if DEBUG
    return "http://127.0.0.1:3000/api"  // 开发环境
    #else
    return "https://your-api-domain.vercel.app/api"  // 生产环境
    #endif
}()
```
