# 🔄 部署后iOS应用更新指南

## 📱 更新iOS应用配置

### 步骤1：获取部署URL
部署完成后，您会得到类似这样的URL：
- **Vercel**: `https://phygital-asset-nft-api-xxx.vercel.app`
- **Railway**: `https://phygital-asset-nft-api-production.up.railway.app`

### 步骤2：更新NFTManager.swift

在 `Phygital Asset/Managers/NFTManager.swift` 文件中，找到第22行：

```swift
// 当前配置
return "https://phygital-asset-nft-api.vercel.app/api"
```

**替换为您的实际部署URL**：

```swift
// 更新为您的实际URL
return "https://your-actual-deployment-url.com/api"
```

### 步骤3：测试配置

#### 3.1 本地测试
```bash
# 测试云端API健康检查
curl https://your-deployment-url.com/api/health
```

#### 3.2 iOS应用测试
1. 在iOS模拟器中运行应用
2. 创建一个新的Thread
3. 检查控制台日志，确认API调用成功

### 步骤4：验证功能

#### 4.1 NFT铸造测试
- 创建Thread后，检查是否成功铸造NFT
- 查看控制台日志确认API调用

#### 4.2 错误处理测试
- 断网测试：确保应用在API不可用时仍能正常工作
- 备用服务：确认本地模拟功能正常

## 🔧 配置选项

### 选项1：Vercel部署
```swift
return "https://phygital-asset-nft-api.vercel.app/api"
```

### 选项2：Railway部署
```swift
return "https://phygital-asset-nft-api-production.up.railway.app/api"
```

### 选项3：自定义域名
```swift
return "https://api.phygital-asset.com/api"
```

## ✅ 部署完成检查清单

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

### 生产环境验证
- [ ] API服务24/7运行
- [ ] 全球可访问
- [ ] HTTPS支持
- [ ] 自动扩展

## 🎯 预期结果

更新完成后，您的应用将：
- ✅ **自动使用云端API服务**
- ✅ **24/7可用的NFT功能**
- ✅ **全球用户可访问**
- ✅ **完整的错误处理**

## 🔧 故障排除

### 问题1：API连接失败
**解决方案**：
1. 检查URL是否正确
2. 确认API服务正在运行
3. 检查网络连接

### 问题2：NFT铸造失败
**解决方案**：
1. 检查环境变量设置
2. 确认私钥正确
3. 检查合约地址

### 问题3：iOS应用崩溃
**解决方案**：
1. 检查URL格式
2. 确认网络权限
3. 查看控制台日志
