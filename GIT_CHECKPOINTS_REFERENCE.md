# 🏷️ Git历史回溯点参考

快速查看项目中所有重要的历史回溯点。

---

## 📍 可用的历史回溯点

### 1. `backup-before-office-map-refactor`
**创建时间**: 2025-10-XX  
**用途**: Office Map拆分前的稳定版本  
**状态**: 安全备份点

```bash
git checkout backup-before-office-map-refactor
```

---

### 2. `checkpoint-market-complete` ⭐ **最新**
**创建时间**: 2025-10-26  
**提交**: `033205a`  
**用途**: Market功能完整实现  
**状态**: ✅ 稳定、功能完整

**包含功能**:
- ✅ Market市场页面（热门建筑、交易记录、活跃用户）
- ✅ Supabase RPC优化（所有SQL函数修复）
- ✅ 图片缓存系统（SHA256）
- ✅ 加载骨架屏
- ✅ Transfer转让功能

**回溯方法**:
```bash
# 创建新分支（推荐）
git checkout -b my-feature checkpoint-market-complete

# 仅查看代码
git checkout checkpoint-market-complete

# 硬重置（警告：丢失后续更改）
git reset --hard checkpoint-market-complete
```

**详细文档**: 查看 `CHECKPOINT_MARKET_COMPLETE.md`

---

## 🎯 快速命令

### 列出所有标签
```bash
git tag -l -n1
```

### 查看标签详细信息
```bash
git show checkpoint-market-complete
```

### 比较当前版本与回溯点
```bash
git diff checkpoint-market-complete
```

### 查看回溯点的提交历史
```bash
git log checkpoint-market-complete --oneline -20
```

---

## 📊 回溯点对比表

| 标签名称 | 日期 | 提交 | 主要功能 | 状态 |
|---------|------|------|---------|------|
| `backup-before-office-map-refactor` | 2025-10-XX | - | Office Map重构前 | 备份 |
| `checkpoint-market-complete` | 2025-10-26 | 033205a | Market完整实现 | ✅ 稳定 |

---

## 🚀 使用场景

### 场景1: 新功能开发出错，需要回退
```bash
# 回到Market完整实现的稳定版本
git checkout -b fix-branch checkpoint-market-complete
```

### 场景2: 查看历史版本代码
```bash
# 临时查看（detached HEAD）
git checkout checkpoint-market-complete

# 查看完毕后返回
git checkout main
```

### 场景3: 创建发布版本
```bash
# 基于稳定回溯点创建发布分支
git checkout -b release-v1.0 checkpoint-market-complete
```

---

## ⚠️ 注意事项

1. **不要删除标签**: 标签是永久的历史标记
2. **使用分支**: 从回溯点创建新分支而不是直接重置
3. **备份当前工作**: 回溯前确保当前工作已提交或stash
4. **检查配置**: 回溯后检查Supabase等配置是否需要更新

---

## 📝 创建新回溯点

当完成重要功能或达到稳定版本时：

```bash
# 创建带注释的标签
git tag -a "checkpoint-功能名" -m "详细说明"

# 创建说明文档
# 参考 CHECKPOINT_MARKET_COMPLETE.md 格式

# 提交说明文档
git add CHECKPOINT_*.md
git commit -m "文档: 创建历史回溯点 - 功能名"
```

---

**最后更新**: 2025-10-26  
**维护人**: AI Assistant  
**相关文档**: 
- `CHECKPOINT_MARKET_COMPLETE.md` - Market回溯点详情
- `OPTIMIZATION_SUMMARY.md` - 优化总结
- `MARKET_UPDATE_INSTRUCTIONS.md` - RPC更新指南

