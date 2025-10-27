# XP显示功能 - Market界面

本文档介绍在Market界面中添加的XP显示功能。

## 📊 功能概述

在Market界面的Tab切换区域添加了XP和等级显示，包括：
- 当前等级（Lv.X）
- 当前等级的XP进度（X/1000 XP）
- 可视化进度条

## 🎨 UI设计

### 布局结构
```
┌──────────────────────────────────────────────────┐
│ ┌───────────────────────┐                        │
│ │ ⭐ 100 Echo           │ 浅绿色卡片            │
│ │ ⚡ Lv.5 XP  ▓▓░░░░   │                        │
│ └───────────────────────┘                        │
│                                                   │
│ ┌──────┐  ┌───────────┐  ┌──────────┐          │
│ │  🔥  │  │  📊       │  │  👥      │          │
│ │Trend │  │Most Traded│  │Top Users │          │
│ └──────┘  └───────────┘  └──────────┘          │
│  ▲选中       未选中         未选中               │
└──────────────────────────────────────────────────┘
```

**第一行：Echo和XP合并卡片**
- **单一浅绿色背景** (`appGreen.opacity(0.1)`)
- Echo行（上）：绿色文字
- XP行（下）：紫色文字
- 进度条：60px宽，紫色渐变

**第二行：三个Tab横向排列**
- 图标 + 文字垂直排列
- 选中：绿色渐变背景 + 白色文字 + 阴影
- 未选中：半透明背景 + 细边框
- 弹簧动画切换效果

### 视觉元素

#### Echo和XP合并卡片
- **统一背景**: 浅绿色 (appGreen.opacity(0.1))
- **圆角**: 10px
- **内边距**: 横向12px，纵向10px

**Echo行（上）**：
- **图标**: ⭐ (star.fill) - 绿色
- **数值**: 绿色粗体，16pt
- **标签**: "Echo" - 绿色70%透明度，11pt
- **冻结提示**: 橙色（如果有）

**XP行（下）**：
- **图标**: ⚡ (bolt.fill) - 紫色
- **数值**: "Lv.X" - 紫色粗体，16pt
- **标签**: "XP" - 紫色70%透明度，11pt
- **进度条**: 60px宽紫色渐变（无数值显示）

### 进度条设计
- **宽度**: 80px（固定）
- **高度**: 5px
- **圆角**: 3px
- **背景色**: 灰色半透明 (gray.opacity(0.2))
- **进度色**: 紫色渐变 (purple → purple.opacity(0.7))
- **动画**: 0.3秒缓动动画
- **无数值显示**: 纯视觉化进度

## 💻 代码实现

### 状态变量
```swift
@State private var userXP = 0              // 总XP
@State private var userLevel = 1           // 当前等级
@State private var xpProgress: Float = 0.0 // 进度百分比
@State private var currentLevelXP = 0      // 当前等级的XP
@State private var xpForNextLevel = 1000   // 下一级需要的XP
```

### 数据加载
```swift
private func loadUserXP() async {
    // 从XPManager获取XP数据
    let xp = XPManager.shared.getXP(for: username)
    let levelProgress = XPManager.shared.getLevelProgress(for: username)
    
    // 更新UI状态
    self.userXP = xp
    self.userLevel = levelProgress.currentLevel
    self.currentLevelXP = levelProgress.currentXP
    self.xpForNextLevel = levelProgress.xpForNextLevel
    self.xpProgress = levelProgress.progressPercentage
}
```

### 刷新时机
- ✅ 界面首次加载（onAppear）
- ✅ 手动刷新（刷新按钮）
- ✅ 与Echo、Market数据同时加载

## 🔢 XP计算逻辑

### 等级计算
```
Level = (Total XP / 1000) + 1
```

示例：
- 0-999 XP → Level 1
- 1000-1999 XP → Level 2
- 2000-2999 XP → Level 3

### 进度计算
```
当前等级XP = Total XP % 1000
进度百分比 = 当前等级XP / 1000
```

示例：
- 总XP: 2350
- 等级: 3
- 当前等级XP: 350
- 进度: 35%

## 📱 用户体验

### 信息层级
1. **等级** - 最显眼（Lv.X，粗体、16pt）
2. **进度条** - 视觉化辅助（80px宽，无数值）
3. **标签** - 说明文字（Echo/XP，11pt）

### 尺寸规范
- **左侧卡片区域**: 140px宽
- **Echo卡片**: 全宽，6px内边距
- **XP卡片**: 全宽，6px内边距
- **卡片间距**: 8px
- **进度条**: 80px × 5px
- **圆角**: 8px（卡片），3px（进度条）

### 颜色编码
- 🟢 **Echo (绿色)** - 表示财富/代币
- 🟣 **XP (紫色)** - 表示经验/活跃度

### 动画效果
- 进度条增长：0.3秒缓动动画
- Tab切换：弹簧动画（0.3秒，阻尼0.7）
- 选中状态：渐变背景 + 阴影效果
- 刷新时平滑过渡

### Tab按钮交互设计

#### 选中状态（Active）
- **背景**: 绿色渐变 (appGreen → appGreen 80%)
- **文字**: 白色，加粗（semibold）
- **图标**: 白色，加粗
- **指示器**: 右侧显示 ▶ 箭头
- **圆角**: 10px
- **阴影**: 绿色阴影，4px模糊，y偏移2px
- **效果**: 突出、立体

#### 未选中状态（Inactive）
- **背景**: 绿色半透明 (8%透明度)
- **文字**: 深色，中等粗细（medium）
- **图标**: 绿色
- **边框**: 绿色细边框（20%透明度）
- **圆角**: 8px
- **效果**: 低调、可点击感

#### 视觉提示
- ✅ **图标**: 每个Tab都有独特的图标
- ✅ **选中箭头**: 当前Tab显示chevron.right
- ✅ **渐变背景**: 选中Tab有明显的颜色对比
- ✅ **阴影效果**: 选中Tab有浮起感
- ✅ **弹簧动画**: 切换时有回弹效果

## 🎯 未来扩展

### 可能的增强功能
1. **点击查看详情**
   - 显示XP获取历史
   - 显示升级奖励
   - 显示下一级解锁内容

2. **升级动画**
   - 等级提升时的特效
   - 成就徽章显示

3. **排名对比**
   - 显示在所有用户中的排名
   - 与好友对比

4. **XP加成**
   - VIP加成显示
   - 活动加成提示

## 📝 相关文件

- `MarketView.swift` - 主界面实现
- `XPManager.swift` - XP管理逻辑
- `XP_SYSTEM_SETUP.sql` - 数据库设置
- `NAMING_CONVENTION_SUMMARY.md` - 命名规范

## 更新日期
2025-10-27

