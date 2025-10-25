//
//  NFCHistoryFullScreenView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Created by AI Assistant on 2024
//

import SwiftUI

// 建筑分组数据结构
struct BuildingGroup: Identifiable {
    let id: String
    let buildingName: String
    let checkInCount: Int
    let checkIns: [BuildingCheckIn]
}

// NFC历史记录全屏视图（与MyHistoryFullScreenView样式一致）
// 只读模式：仅查看历史记录，不支持新增Check-in
struct NFCHistoryFullScreenView: View {
    let nfcUuid: String
    let appGreen: Color
    let onClose: () -> Void
    let onNavigateToBuilding: ((Double, Double) -> Void)? // 导航到建筑的回调
    let onNavigateToOvalOffice: (() -> Void)? // 导航到Oval Office的回调
    let treasures: [Treasure]? // 建筑列表，用于显示真实建筑名称
    let currentUsername: String? // 当前用户名
    
    @State private var checkIns: [BuildingCheckIn] = []
    @State private var ovalCheckIns: [OvalOfficeCheckIn] = []
    @State private var buildingGroups: [BuildingGroup] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedBuildingGroup: BuildingGroup?
    @State private var selectedBuildingCheckIn: BuildingCheckIn?
    @State private var selectedOvalCheckIn: OvalOfficeCheckIn?
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Spacer()
                
                Text("NFC History")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 关闭按钮
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            Divider()
            
            // NFC信息卡片 - 毛玻璃样式
            HStack(spacing: 16) {
                // NFC图标 - 毛玻璃样式
                ZStack {
                    // 渐变背景
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    appGreen.opacity(0.3),
                                    appGreen.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // 图标
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .frame(width: 45, height: 45)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(0.6), location: 0.0),
                                    .init(color: Color.white.opacity(0.0), location: 0.3),
                                    .init(color: appGreen.opacity(0.3), location: 0.7),
                                    .init(color: appGreen.opacity(0.5), location: 1.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: appGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("NFC Tag")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    let totalBuildings = buildingGroups.count + (ovalCheckIns.isEmpty ? 0 : 1)
                    Text("\(totalBuildings) Building\(totalBuildings > 1 ? "s" : "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                ZStack {
                    Color.clear.background(.ultraThinMaterial)
                    LinearGradient(
                        gradient: Gradient(colors: [
                            appGreen.opacity(0.08),
                            appGreen.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            
            // 内容区域
            if isLoading {
                Spacer()
                ProgressView("Loading history...")
                    .progressViewStyle(CircularProgressViewStyle(tint: appGreen))
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(appGreen)
                    Text("Failed to load history")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        loadHistory()
                    }
                    .foregroundColor(appGreen)
                }
                Spacer()
            } else if checkIns.isEmpty && ovalCheckIns.isEmpty {
                Spacer()
                VStack(spacing: 24) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Check-ins Yet")
                        .font(.headline)
                    Text("This NFC tag has no check-in history.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Buildings Section - 显示建筑分组
                        if !buildingGroups.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "building.2")
                                        .foregroundColor(appGreen)
                                    Text("Buildings")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("\(buildingGroups.count)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                
                                ForEach(buildingGroups) { group in
                                    BuildingGroupRow(
                                        buildingName: group.buildingName,
                                        checkInCount: group.checkInCount,
                                        appGreen: appGreen
                                    )
                                    .padding(.horizontal, 20)
                                    .onTapGesture {
                                        selectedBuildingGroup = group
                                    }
                                }
                            }
                        }
                        
                        // Oval Office Section
                        if !ovalCheckIns.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "circle")
                                        .foregroundColor(appGreen)
                                    Text("Oval Office")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("\(ovalCheckIns.count)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                
                                // Oval Office作为一个整体，点击后显示所有记录
                                BuildingGroupRow(
                                    buildingName: "Oval Office",
                                    checkInCount: ovalCheckIns.count,
                                    appGreen: appGreen
                                )
                                .padding(.horizontal, 20)
                                .onTapGesture {
                                    // 显示Oval Office的第一条记录详情（或创建专门的列表视图）
                                    if let first = ovalCheckIns.first {
                                        selectedOvalCheckIn = first
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .overlay {
            // 建筑分组详情页 - 显示该建筑的所有记录
            if let group = selectedBuildingGroup {
                BuildingGroupDetailView(
                    buildingGroup: group,
                    appGreen: appGreen,
                    onClose: {
                        selectedBuildingGroup = nil
                    },
                    onSelectCheckIn: { checkIn in
                        selectedBuildingCheckIn = checkIn
                    }
                )
            }
            
            // 建筑Check-in详情页
            if let checkIn = selectedBuildingCheckIn {
                CheckInDetailView(
                    checkIn: checkIn,
                    appGreen: appGreen,
                    onClose: {
                        selectedBuildingCheckIn = nil
                    },
                    onNavigate: onNavigateToBuilding,
                    currentUsername: currentUsername
                )
            }
            
            // Oval Office Check-in详情页
            if let checkIn = selectedOvalCheckIn {
                OvalOfficeCheckInDetailView(
                    checkIn: checkIn,
                    appGreen: appGreen,
                    onClose: {
                        selectedOvalCheckIn = nil
                    },
                    onNavigateToOvalOffice: onNavigateToOvalOffice,
                    currentUsername: currentUsername
                )
            }
        }
        .onAppear {
            loadHistory()
        }
    }
    
    private func loadHistory() {
        Logger.debug("📋 开始加载NFC历史记录: \(nfcUuid)")
        isLoading = true
        errorMessage = nil
        
        Task {
            var fetchedCheckIns: [BuildingCheckIn] = []
            var fetchedOvalCheckIns: [OvalOfficeCheckIn] = []
            
            // 从 asset_checkins 表获取
            do {
                Logger.debug("📋 查询 asset_checkins 表...")
                fetchedCheckIns = try await BuildingCheckInManager.shared.getCheckInsByNFC(nfcUuid: nfcUuid)
                Logger.success("📋 从 asset_checkins 获取到 \(fetchedCheckIns.count) 条记录")
            } catch {
                Logger.error("📋 从 asset_checkins 获取失败: \(error.localizedDescription)")
            }
            
            // 从 oval_office_checkins 表获取
            do {
                Logger.debug("📋 查询 oval_office_checkins 表...")
                fetchedOvalCheckIns = try await OvalOfficeCheckInManager.shared.getCheckInsByNFC(nfcUuid: nfcUuid)
                Logger.success("📋 从 oval_office_checkins 获取到 \(fetchedOvalCheckIns.count) 条记录")
            } catch {
                Logger.error("📋 从 oval_office_checkins 获取失败: \(error.localizedDescription)")
            }
            
            await MainActor.run {
                self.checkIns = fetchedCheckIns
                self.ovalCheckIns = fetchedOvalCheckIns
                
                // 按building_id分组
                self.buildingGroups = groupCheckInsByBuilding(fetchedCheckIns)
                
                self.isLoading = false
                Logger.success("📋 NFC历史记录加载完成，共 \(fetchedCheckIns.count + fetchedOvalCheckIns.count) 条")
                Logger.debug("📋 建筑分组: \(self.buildingGroups.count) 个建筑")
            }
        }
    }
    
    private func groupCheckInsByBuilding(_ checkIns: [BuildingCheckIn]) -> [BuildingGroup] {
        let grouped = Dictionary(grouping: checkIns, by: { $0.buildingId })
        
        return grouped.map { buildingId, checkIns in
            // 根据building_id查找真实建筑名称
            let buildingName: String
            if buildingId.starts(with: "nfc_exploration_") {
                buildingName = "Unknown Location"
            } else if let treasure = treasures?.first(where: { $0.id == buildingId }) {
                buildingName = treasure.name
            } else {
                buildingName = "Building #\(buildingId)"
            }
            
            return BuildingGroup(
                id: buildingId,
                buildingName: buildingName,
                checkInCount: checkIns.count,
                checkIns: checkIns.sorted { $0.createdAt > $1.createdAt }
            )
        }.sorted { $0.checkInCount > $1.checkInCount }
    }
}

// 建筑分组行组件
struct BuildingGroupRow: View {
    let buildingName: String
    let checkInCount: Int
    let appGreen: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // 建筑图标
            ZStack {
                Circle()
                    .fill(appGreen.opacity(0.1))
                
                Image(systemName: "building.2.fill")
                    .font(.system(size: 18))
                    .foregroundColor(appGreen)
            }
            .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(buildingName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(checkInCount) Check-in\(checkInCount > 1 ? "s" : "")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// 建筑分组详情视图
struct BuildingGroupDetailView: View {
    let buildingGroup: BuildingGroup
    let appGreen: Color
    let onClose: () -> Void
    let onSelectCheckIn: (BuildingCheckIn) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Text(buildingGroup.buildingName)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            Divider()
            
            // 记录列表
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(buildingGroup.checkIns, id: \.id) { checkIn in
                        CompactCheckInRow(
                            time: checkIn.createdAt,
                            assetName: checkIn.assetName ?? "Unknown",
                            description: checkIn.description,
                            appGreen: appGreen
                        )
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            onSelectCheckIn(checkIn)
                        }
                    }
                }
                .padding(.vertical, 20)
            }
        }
        .background(Color(.systemBackground))
    }
}
