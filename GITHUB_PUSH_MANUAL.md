# 🔐 GitHub代码推送详细指南

## 📋 方法1：在终端中手动推送

### 步骤1：打开终端
- 在macOS中按 `Cmd + Space`
- 输入 "Terminal" 并回车
- 或者使用您当前的终端窗口

### 步骤2：导航到项目目录
```bash
cd "/Users/Jay/Documents/Phygital Asset"
```

### 步骤3：运行推送命令
```bash
git push -u origin main
```

### 步骤4：输入认证信息
系统会提示您输入：
- **Username**: `Jay-6539`
- **Password**: 粘贴您的GitHub Personal Access Token

## 📋 方法2：创建GitHub Personal Access Token

### 步骤1：访问GitHub设置
1. 打开浏览器访问：https://github.com/settings/tokens
2. 点击 "Generate new token" → "Generate new token (classic)"

### 步骤2：配置Token
- **Note**: `Phygital Asset NFT API`
- **Expiration**: 选择合适的时间（建议90天）
- **Scopes**: 勾选 `repo` (Full control of private repositories)

### 步骤3：生成并复制Token
- 点击 "Generate token"
- **重要**：立即复制生成的token（只显示一次）
- 保存到安全的地方

## 📋 方法3：使用GitHub CLI（推荐）

### 步骤1：安装GitHub CLI
```bash
# 使用Homebrew安装
brew install gh

# 或者从官网下载
# https://cli.github.com/
```

### 步骤2：登录GitHub
```bash
gh auth login
# 选择 GitHub.com
# 选择 HTTPS
# 选择 Yes 来认证Git
# 选择 Login with a web browser
```

### 步骤3：推送代码
```bash
git push -u origin main
```

## 📋 方法4：手动上传文件（备选）

如果上述方法都不行，可以手动上传：

### 步骤1：访问GitHub仓库
- 打开 https://github.com/Jay-6539/phygital-asset-nft-api

### 步骤2：上传文件
1. 点击 "uploading an existing file"
2. 拖拽以下文件到页面：
   - `nft-api-server-amoy.js`
   - `package.json`
   - `.gitignore`
   - `vercel.json`
   - `contracts/` 文件夹
   - `scripts/` 文件夹
   - 所有 `.md` 文件

### 步骤3：提交
- 填写提交信息：`Initial commit: Phygital Asset NFT API`
- 点击 "Commit changes"

## 🎯 推荐流程

**建议使用方法3（GitHub CLI）**，因为：
- ✅ 最安全
- ✅ 最简单
- ✅ 一次设置，长期使用

## 🔧 故障排除

### 问题1：认证失败
- 检查用户名是否正确：`Jay-6539`
- 确认token权限包含 `repo`
- 验证token未过期

### 问题2：权限不足
- 确认仓库是Public
- 检查token权限设置
- 验证仓库URL正确

### 问题3：网络问题
- 检查网络连接
- 尝试使用VPN
- 使用手动上传方法

## 📱 推送成功后

推送成功后，下一步：
1. 访问 https://railway.app
2. 使用GitHub登录
3. 创建新项目
4. 选择仓库：`phygital-asset-nft-api`
5. 配置环境变量
6. 自动部署
