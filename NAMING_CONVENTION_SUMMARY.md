# 系统命名规范总结

本文档总结了 TreasureHuntHK 系统中的核心命名约定。

## 📍 核心概念

### 1. Building（建筑）
**定义**: 在主地图界面中标注出来的点

**用途**:
- 地图上的历史建筑标记
- 用户可以导航到的目标点
- 对应 `Treasure` 数据结构

**相关文件**:
- `HistoricBuildingsManager.swift`
- `BuildingCheckInManager.swift`

---

### 2. Thread（线索/记录）
**定义**: 用户在NFC标签上留下的记录

**用途**:
- 用户在某个NFC位置留下的签到记录
- 包含用户名、时间戳、描述、图片等信息
- 可以在用户之间转移和交易

**相关文件**:
- `ThreadRecord.swift`（模型定义）
- Thread 记录存储在 `asset_checkins` 表中

**数据库字段**:
- `id`: UUID
- `username`: 记录拥有者
- `asset_name`: 资产名称
- `description`: 描述
- `image_url`: 图片URL
- `nfc_uuid`: NFC标签唯一标识符

---

### 3. Echo（代币）
**定义**: 用户的代币财产，用于交易和竞价

**用途**:
- 用户的虚拟货币
- 用于出价（Bid）购买其他用户的 Thread
- 可以被冻结（在出价时）
- 在交易完成时转移

**相关文件**:
- `EchoManager.swift`
- Echo 金额显示在 Market 和 Bid 相关界面

**主要功能**:
- `getEcho()`: 获取用户的 Echo
- `addEcho()`: 增加 Echo
- `deductEcho()`: 扣除 Echo
- `freezeEcho()`: 冻结 Echo（出价时）
- `unfreezeEcho()`: 解冻 Echo
- `transferEcho()`: 转账 Echo

---

### 4. XP（经验值）
**定义**: 用户活跃度的数值指标，用于提升等级

**用途**:
- 跟踪用户的活跃度
- 累积 XP 提升用户等级
- 显示在用户资料和排行榜中

**等级计算**:
```
Level = (XP / 1000) + 1
```

**XP奖励规则**:
- Thread创建: +10 XP
- 发现新建筑: +50 XP
- Thread转移: +20 XP
- Bid被接受: +30 XP
- 每日登录: +5 XP

**相关文件**:
- `XPManager.swift`
- `XP_SYSTEM_SETUP.sql`（数据库设置）

**主要功能**:
- `getXP()`: 获取用户的 XP
- `addXP()`: 增加 XP
- `getLevel()`: 获取用户等级
- `getLevelProgress()`: 获取当前等级进度

---

## 🔄 系统流程

### Thread 创建流程
1. 用户扫描NFC标签
2. 填写 Thread 信息（asset_name, description, image）
3. 保存到数据库
4. 奖励 +10 XP

### Echo 交易流程
1. 买家对 Thread 出价（Bid）
2. Echo 被冻结
3. 卖家接受/拒绝/反价
4. 交易完成时：
   - Echo 从买家转移到卖家
   - Thread 所有权转移
   - 买家获得 +30 XP

---

## 📊 数据库表

### `asset_checkins`
存储 Thread 记录（NFC 签到）

### `oval_office_checkins`
存储 Oval Office 的特殊记录

### `bids`
存储竞价记录

### `user_xp`
存储用户 XP 和等级

---

## 🎯 UI 显示规范

**重要**: 所有用户可见的文字必须使用英文

- Echo: 显示为 "Echo"（不是 "Credits"）
- Thread: 显示为 "Thread" 或相关上下文（如 "Check-in Record"）
- Building: 显示为 "Building"
- XP: 显示为 "XP" 或 "Experience Points"
- Level: 显示为 "Level" 或 "Lv."

---

## 📝 更新日志

- **2025-10-27**: 统一命名规范
  - Credit → Echo
  - CheckIn → Thread
  - 新增 XP 系统
  - 新增本命名规范文档

