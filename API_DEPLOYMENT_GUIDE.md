# 🚀 API服务云端部署指南

## 📋 部署选项

### 选项1：Vercel部署（推荐）
```bash
# 安装Vercel CLI
npm install -g vercel

# 登录Vercel
vercel login

# 部署项目
vercel --prod
```

### 选项2：Railway部署
```bash
# 安装Railway CLI
npm install -g @railway/cli

# 登录Railway
railway login

# 初始化项目
railway init

# 部署项目
railway up
```

## 🔧 部署前准备

### 1. 创建生产环境配置
需要创建生产环境的.env文件，包含：
- AMOY_PRIVATE_KEY
- CONTRACT_ADDRESS
- 其他配置

### 2. 更新应用配置
部署成功后，需要更新iOS应用中的API URL：
```swift
// 从本地改为云端
return "https://your-api-domain.vercel.app/api"
```

## 📊 部署后的优势
- ✅ 24/7运行
- ✅ 全球访问
- ✅ 自动扩展
- ✅ HTTPS支持
