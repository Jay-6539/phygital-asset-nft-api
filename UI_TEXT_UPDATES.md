# UI文本更新总结 - Check-in → Thread

本文档记录了所有用户可见的UI文本更新，将"Check-in"改为"Thread"。

## ✅ 已更新的文件

### 1. Market 相关
- **TradedRecordDetailView.swift**
  - "Check-in Details" → "Thread Details"

- **BuildingHistoryView.swift**
  - "Be the first to check in\nat this building!" → "Be the first to create a thread\nat this building!"

- **TrendingBuildingsView.swift**
  - "Be the first to explore and check in\nat historic buildings!" → "Be the first to explore and create threads\nat historic buildings!"

### 2. History 相关
- **MyHistoryFullScreenView.swift**
  - "X Check-ins" → "X Threads"
  - "No Check-ins Yet" → "No Threads Yet"
  - "Start exploring and check in to buildings!" → "Start exploring and create threads!"
  - 日志: "building check-ins" → "building threads"

- **MyHistoryView.swift**
  - "My Check-in History" → "My Thread History"
  - "No check-in history yet" → "No thread history yet"
  - "Start checking in to see your history!" → "Start creating threads to see your history!"
  - 日志: "building check-ins, oval office check-ins" → "building threads, oval office threads"

- **AssetHistoryModal.swift**
  - "No check-in history yet" → "No thread history yet"
  - "Be the first to check in!" → "Be the first to create a thread!"
  - 日志: "Starting check-in" → "Starting thread creation"
  - 日志: "启动 Check-in" → "启动 Thread 创建"

### 3. Oval Office 相关
- **AssetInfoModalView.swift**
  - "Check-in History" → "Thread History"
  - "Loading check-ins..." → "Loading threads..."
  - "Failed to load check-ins" → "Failed to load threads"
  - "No check-in history yet" → "No thread history yet"
  - "Be the first to check in!" → "Be the first to create a thread!"
  - "Check in mine!" → "Create my thread!"
  - "Check-in Details" → "Thread Details"
  - 日志: "cannot check in" → "cannot create thread"
  - 日志: "Starting NFC check-in" → "Starting NFC thread creation"
  - 日志: "Loaded X check-ins" → "Loaded X threads"

### 4. Detail Views
- **CheckInDetailView.swift**
  - "Check-in Details" → "Thread Details"
  - "Check-in Time" → "Created Time"

- **OvalOfficeCheckInDetailView.swift**
  - "Check-in Details" → "Thread Details"
  - "Check-in Time" → "Created Time"

## 📝 注意事项

### 保留的术语
以下术语**未更改**，因为它们是代码层面的命名：
- 类名: `BuildingCheckInManager`, `OvalOfficeCheckInManager`
- 变量名: `myCheckIns`, `checkIn`, `cloudCheckIns`
- 数据库表名: `asset_checkins`, `oval_office_checkins`
- 函数名: `saveCheckIn()`, `getCheckIns()`

这些是内部实现细节，不会影响用户体验。

### UI显示规范
所有用户可见的文本必须使用英文：
- ✅ "Thread" 或 "Threads"
- ✅ "Create a thread" / "Create my thread"
- ✅ "Thread History"
- ✅ "Thread Details"
- ✅ "Created Time"（代替"Check-in Time"）

## 🎯 命名概念对应

| UI显示 | 实际含义 | 代码层面 |
|--------|---------|---------|
| Thread | 用户在NFC上留下的记录 | CheckIn / Record |
| Thread History | 历史记录列表 | Check-in History |
| Create a thread | 创建新记录 | Check in / Save record |
| Thread Details | 记录详情 | Check-in Details |

## 更新日期
2025-10-27

