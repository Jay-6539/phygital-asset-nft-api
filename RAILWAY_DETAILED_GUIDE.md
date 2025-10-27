# 🚂 Railway部署详细指南

## 📋 步骤1：访问Railway

1. 打开浏览器访问：https://railway.app
2. 点击右上角的 "Login" 按钮
3. 选择 "Login with GitHub"
4. 授权Railway访问您的GitHub账号

## 📋 步骤2：创建新项目

1. 登录后，点击 "New Project"
2. 选择 "Deploy from GitHub repo"
3. 在仓库列表中找到 `phygital-asset-nft-api`
4. 点击仓库名称
5. Railway会自动开始部署

## 📋 步骤3：配置环境变量

### 3.1 进入项目设置
1. 点击项目名称进入项目详情
2. 点击 "Variables" 标签页
3. 点击 "New Variable" 添加环境变量

### 3.2 添加环境变量
按照以下顺序添加：

```
AMOY_RPC_URL = https://rpc-amoy.polygon.technology/
AMOY_CHAIN_ID = 80002
CONTRACT_ADDRESS = 0xA0fA27fC547D544528e9BE0cb6569E9B925e533E
AMOY_PRIVATE_KEY = 你的私钥
NODE_ENV = production
```

**⚠️ 重要提醒**：
- `AMOY_PRIVATE_KEY` 必须是64位十六进制字符串
- 不要包含 `0x` 前缀
- 确保私钥格式正确

## 📋 步骤4：等待部署完成

### 4.1 部署过程
- Railway会自动检测 `package.json`
- 自动安装依赖（express, ethers, dotenv等）
- 自动启动服务
- 生成HTTPS URL

### 4.2 部署时间
- 通常需要2-5分钟
- 可以在 "Deployments" 标签页查看进度
- 部署完成后会显示绿色状态

## 📋 步骤5：获取部署URL

### 5.1 查看部署URL
1. 部署完成后，在项目首页会显示URL
2. 格式类似：`https://phygital-asset-nft-api-production.up.railway.app`
3. 点击URL可以访问API服务

### 5.2 测试API
```bash
# 健康检查
curl https://your-railway-url.up.railway.app/api/health

# NFT铸造测试
curl -X POST https://your-railway-url.up.railway.app/api/mint-thread \
  -H "Content-Type: application/json" \
  -d '{"threadId":"test-railway","username":"Railway Test"}'
```

## 📋 步骤6：更新iOS应用

### 6.1 修改NFTManager.swift
在 `Phygital Asset/Managers/NFTManager.swift` 文件中：

```swift
private let apiURL: String = {
    #if DEBUG
    return "http://127.0.0.1:3000/api"  // 开发环境
    #else
    return "https://your-railway-url.up.railway.app/api"  // 生产环境
    #endif
}()
```

### 6.2 测试iOS应用
1. 在iOS模拟器中运行应用
2. 创建一个新的Thread
3. 检查控制台日志确认API调用成功

## ✅ 部署完成验证

### 技术验证
- [ ] API服务正常运行
- [ ] 健康检查端点响应正常
- [ ] NFT铸造功能正常
- [ ] 错误处理完善

### 用户体验验证
- [ ] iOS应用可连接云端API
- [ ] NFT铸造功能正常
- [ ] 网络错误时自动降级
- [ ] 用户无感知切换

## 🔧 故障排除

### 问题1：部署失败
**可能原因**：
- 环境变量配置错误
- 私钥格式不正确
- 依赖安装失败

**解决方案**：
1. 检查环境变量设置
2. 确认私钥格式（64位十六进制）
3. 查看Railway日志

### 问题2：API调用失败
**可能原因**：
- 服务未正常启动
- 环境变量缺失
- 网络连接问题

**解决方案**：
1. 检查服务状态
2. 验证环境变量
3. 测试网络连接

### 问题3：iOS应用连接失败
**可能原因**：
- API URL配置错误
- 网络权限问题
- 服务未运行

**解决方案**：
1. 检查API URL配置
2. 确认服务正在运行
3. 验证网络连接

## 🎉 完成！

部署完成后，您将拥有：
- ✅ **24/7运行的API服务**
- ✅ **全球可访问的HTTPS端点**
- ✅ **自动扩展和监控**
- ✅ **企业级可靠性**

## 🚀 下一步

现在可以开始**目标2：增强NFT功能**，包括：
- NFT转移功能
- NFT展示功能
- 区块链链接集成
