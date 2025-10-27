# 🔐 GitHub认证指南

## 📋 方法1：使用GitHub Personal Access Token（推荐）

### 步骤1：创建Personal Access Token
1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token" → "Generate new token (classic)"
3. 填写描述：`Phygital Asset NFT API`
4. 选择权限：
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
5. 点击 "Generate token"
6. **重要**：复制生成的token（只显示一次）

### 步骤2：使用Token推送代码
```bash
# 使用token作为密码
git push -u origin main
# 用户名：Jay-6539
# 密码：粘贴您的Personal Access Token
```

## 📋 方法2：使用GitHub CLI

### 安装GitHub CLI
```bash
# macOS
brew install gh

# 或者下载安装包
# https://cli.github.com/
```

### 登录和推送
```bash
gh auth login
git push -u origin main
```

## 📋 方法3：手动上传（备选）

如果上述方法都不行，可以手动上传文件：

### 步骤1：下载代码
```bash
# 创建压缩包
tar -czf phygital-asset-nft-api.tar.gz \
  nft-api-server-amoy.js \
  package.json \
  .gitignore \
  vercel.json \
  contracts/ \
  scripts/ \
  *.md
```

### 步骤2：手动上传
1. 访问 https://github.com/Jay-6539/phygital-asset-nft-api
2. 点击 "uploading an existing file"
3. 拖拽文件到页面
4. 填写提交信息
5. 点击 "Commit changes"

## 🎯 推荐方案

**建议使用方法1（Personal Access Token）**，因为：
- ✅ 最安全
- ✅ 最简单
- ✅ Railway可以直接访问

## 🔧 故障排除

### 问题1：认证失败
- 检查用户名是否正确
- 确认token权限包含repo
- 验证token未过期

### 问题2：权限不足
- 确认仓库是Public
- 检查token权限设置
- 验证仓库URL正确

### 问题3：网络问题
- 检查网络连接
- 尝试使用VPN
- 使用手动上传方法
