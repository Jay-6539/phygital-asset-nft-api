# ✅ Railway部署检查清单

## 📋 部署前检查

### ✅ 代码准备
- [x] `nft-api-server-amoy.js` - API服务主文件
- [x] `package.json` - 依赖配置
- [x] `.gitignore` - Git忽略文件
- [x] 代码已提交到Git

### ✅ 环境变量准备
- [x] `AMOY_RPC_URL` - Amoy测试网RPC地址
- [x] `AMOY_CHAIN_ID` - 链ID (80002)
- [x] `CONTRACT_ADDRESS` - 合约地址
- [x] `AMOY_PRIVATE_KEY` - 私钥（64位十六进制）
- [x] `NODE_ENV` - 环境标识

## 🚀 部署步骤

### 步骤1：GitHub仓库
- [ ] 访问 https://github.com
- [ ] 登录GitHub账号
- [ ] 创建新仓库：`phygital-asset-nft-api`
- [ ] 设置为Public
- [ ] 获取仓库URL

### 步骤2：推送代码
- [ ] 添加远程仓库：`git remote add origin <URL>`
- [ ] 推送代码：`git push -u origin main`
- [ ] 确认代码已上传

### 步骤3：Railway部署
- [ ] 访问 https://railway.app
- [ ] 使用GitHub登录
- [ ] 创建新项目
- [ ] 选择GitHub仓库
- [ ] 等待自动部署

### 步骤4：环境变量配置
- [ ] 在Railway Dashboard找到Variables标签
- [ ] 添加 `AMOY_RPC_URL=https://rpc-amoy.polygon.technology/`
- [ ] 添加 `AMOY_CHAIN_ID=80002`
- [ ] 添加 `CONTRACT_ADDRESS=0xA0fA27fC547D544528e9BE0cb6569E9B925e533E`
- [ ] 添加 `AMOY_PRIVATE_KEY=<你的私钥>`
- [ ] 添加 `NODE_ENV=production`

### 步骤5：获取部署URL
- [ ] 记录Railway提供的URL
- [ ] 确认URL格式：`https://xxx.up.railway.app`

## 🧪 测试验证

### API功能测试
- [ ] 健康检查：`curl https://your-url.up.railway.app/api/health`
- [ ] NFT铸造测试：发送POST请求到 `/api/mint-thread`
- [ ] 错误处理测试：发送无效请求
- [ ] 性能测试：检查响应时间

### 部署验证
- [ ] API服务24/7运行
- [ ] HTTPS支持正常
- [ ] 全球可访问
- [ ] 日志输出正常

## 📱 iOS应用更新

### 配置更新
- [ ] 打开 `NFTManager.swift`
- [ ] 找到 `apiURL` 配置
- [ ] 更新生产环境URL
- [ ] 测试iOS应用连接

### 功能验证
- [ ] 创建Thread测试NFT铸造
- [ ] 检查控制台日志
- [ ] 验证错误处理
- [ ] 确认用户体验

## 🎯 完成标准

### 技术指标
- [ ] API服务正常运行
- [ ] 所有端点响应正常
- [ ] 环境变量配置正确
- [ ] 错误处理完善

### 用户体验
- [ ] iOS应用可连接云端API
- [ ] NFT铸造功能正常
- [ ] 网络错误时自动降级
- [ ] 用户无感知切换

## 🔧 故障排除

### 常见问题
1. **GitHub推送失败**
   - 检查仓库URL
   - 确认仓库是Public
   - 检查网络连接

2. **Railway部署失败**
   - 检查环境变量
   - 确认私钥格式
   - 查看Railway日志

3. **API调用失败**
   - 检查部署URL
   - 确认服务运行
   - 验证环境变量

### 调试工具
- Railway Dashboard日志
- 浏览器开发者工具
- iOS模拟器网络日志
- curl命令测试

## ✅ 部署完成

当所有检查项都完成时，您将拥有：
- ✅ **24/7运行的API服务**
- ✅ **全球可访问的端点**
- ✅ **自动HTTPS支持**
- ✅ **完整的NFT功能**
- ✅ **企业级可靠性**

## 🎉 恭喜！

**目标1：部署API服务到云端** 已完成！

现在可以开始**目标2：增强NFT功能** 🚀✨
