# Tab按钮设计规范 - Market界面

## 🎨 设计概述

Market界面的Tab切换采用垂直列表布局，高度与左侧Echo+XP卡片对齐，提供清晰的视觉层次和交互反馈。

## 📐 布局规范

### 整体结构
```
┌─────────────────────────────────────────┐
│ Echo/XP (左)      Tab列表 (右)          │
│ ┌──────┐        ┌────────────────────┐ │
│ │Echo  │        │ 🔥 Trending      ▶││ 选中
│ │      │        └────────────────────┘ │
│ │XP    │        ┌────────────────────┐ │
│ │▓▓░   │        │ 📊 Most Traded    ││ 未选中
│ └──────┘        └────────────────────┘ │
│                 ┌────────────────────┐ │
│                 │ 👥 Top Users       ││ 未选中
│                 └────────────────────┘ │
└─────────────────────────────────────────┘
```

### 尺寸规范
- **左侧区域**: 140px固定宽度
- **右侧区域**: 自适应宽度
- **区域间距**: 16px
- **Tab间距**: 8px
- **Tab内边距**: 横向12px，纵向10px

## 🎯 Tab状态设计

### 1️⃣ 选中状态 (Active)

#### 视觉特征
```
┌────────────────────────────┐
│ 🔥 Trending              ▶│
└────────────────────────────┘
绿色渐变背景 + 白色文字 + 阴影
```

#### 样式参数
| 属性 | 值 |
|------|---|
| 背景 | 绿色渐变 (100% → 80%) |
| 文字颜色 | 白色 |
| 文字粗细 | Semibold (600) |
| 图标颜色 | 白色 |
| 图标粗细 | Semibold |
| 圆角 | 10px |
| 阴影 | 绿色30%，模糊4px，Y偏移2px |
| 边框 | 无 |
| 指示器 | ▶ chevron.right（白色）|

#### CSS等效
```css
background: linear-gradient(to right, #appGreen, rgba(appGreen, 0.8));
color: white;
font-weight: 600;
border-radius: 10px;
box-shadow: 0 2px 4px rgba(appGreen, 0.3);
```

### 2️⃣ 未选中状态 (Inactive)

#### 视觉特征
```
┌────────────────────────────┐
│ 📊 Most Traded            │
└────────────────────────────┘
半透明背景 + 深色文字 + 细边框
```

#### 样式参数
| 属性 | 值 |
|------|---|
| 背景 | 绿色8%透明度 |
| 文字颜色 | 深色（系统primary）|
| 文字粗细 | Medium (500) |
| 图标颜色 | 绿色 |
| 图标粗细 | Regular |
| 圆角 | 8px |
| 阴影 | 无 |
| 边框 | 绿色20%透明度，1px |
| 指示器 | 无 |

#### CSS等效
```css
background: rgba(appGreen, 0.08);
color: var(--text-primary);
font-weight: 500;
border: 1px solid rgba(appGreen, 0.2);
border-radius: 8px;
```

## 🎭 交互效果

### 切换动画
```swift
withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
    selectedTab = newTab
}
```

**效果**:
- 响应时间: 0.3秒
- 阻尼系数: 0.7
- 动画类型: 弹簧动画（有回弹）

### 视觉变化序列
1. **点击Tab** → 弹簧动画开始
2. **背景渐变** → 从半透明变为实色渐变
3. **文字变色** → 深色 → 白色
4. **图标变化** → 绿色 → 白色
5. **箭头出现** → ▶ 从无到有
6. **阴影显现** → 浮起效果
7. **圆角微调** → 8px → 10px

## 📊 Tab列表

### Tab 1: Trending (热门)
- **图标**: 🔥 `flame.fill`
- **文字**: "Trending"
- **功能**: 显示热门建筑

### Tab 2: Most Traded (最常交易)
- **图标**: 📊 `chart.bar.fill`
- **文字**: "Most Traded"
- **功能**: 显示交易最频繁的记录

### Tab 3: Top Users (顶级用户)
- **图标**: 👥 `person.2.fill`
- **文字**: "Top Users"
- **功能**: 显示活跃用户排行

## 🎨 颜色系统

### 主色调
- **appGreen**: 系统主题绿色
- **appGreen 80%**: `appGreen.opacity(0.8)`
- **appGreen 30%**: `appGreen.opacity(0.3)` (阴影)
- **appGreen 20%**: `appGreen.opacity(0.2)` (边框)
- **appGreen 8%**: `appGreen.opacity(0.08)` (背景)

### 文字颜色
- **选中**: 白色 (white)
- **未选中**: 系统深色 (primary)

## 💡 用户体验要点

### 可交互性提示
✅ **明确的选中状态** - 绿色渐变 + 白色文字
✅ **箭头指示器** - 当前选中项右侧显示▶
✅ **阴影浮起效果** - 选中项有立体感
✅ **弹簧动画** - 切换时有回弹，增加趣味性
✅ **不同圆角** - 选中10px，未选中8px，微妙区别

### 可发现性
✅ **图标 + 文字** - 双重标识，易识别
✅ **全宽按钮** - 大点击区域，易操作
✅ **垂直排列** - 与左侧对齐，视觉平衡
✅ **等高设计** - 充分利用空间

## 🔧 技术实现

### SwiftUI代码结构
```swift
VStack(spacing: 0) {
    ForEach(tabs) { tab in
        Button {
            // 弹簧动画
            withAnimation(.spring(...)) {
                selectedTab = tab
            }
        } label: {
            HStack {
                Icon + Text + Spacer + Indicator
            }
            .background(gradient/color)
            .cornerRadius(selected ? 10 : 8)
            .shadow(...)
        }
        
        Spacer(8px) // Tab间距
    }
}
```

### 性能优化
- ✅ 使用`PlainButtonStyle()`避免默认按钮效果
- ✅ 条件渲染箭头指示器
- ✅ 动画参数优化（0.3秒适中）

## 📱 响应式考虑

### 不同屏幕尺寸
- **小屏**: Tab文字可能换行（已设置Spacer）
- **大屏**: 右侧有更多空间，Tab更宽
- **左侧固定**: 140px确保一致性

## 更新日期
2025-10-27

