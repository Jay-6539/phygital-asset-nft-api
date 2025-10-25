//
//  MyHistoryFullScreenView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Created by AI Assistant on 2024
//

import SwiftUI

struct MyHistoryFullScreenView: View {
    let username: String
    let appGreen: Color
    let onClose: () -> Void
    let onNavigateToBuilding: ((Double, Double) -> Void)? // 导航到建筑的回调
    let onNavigateToOvalOffice: (() -> Void)? // 导航到Oval Office的回调
    let treasures: [Treasure]? // 建筑列表，用于显示真实建筑名称
    let nfcManager: NFCManager // NFC管理器，用于转让验证
    
    @State private var myCheckIns: [BuildingCheckIn] = []
    @State private var ovalCheckIns: [OvalOfficeCheckIn] = []
    @State private var buildingGroups: [BuildingGroup] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedBuildingGroup: BuildingGroup?
    @State private var selectedBuildingCheckIn: BuildingCheckIn? = nil
    @State private var selectedOvalCheckIn: OvalOfficeCheckIn? = nil
    @State private var showReceiveTransfer = false
    @State private var showMyBids = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    // 返回按钮 - 白色圆形按钮 + 黑色<
                    Button(action: onClose) {
                        ZStack {
                            Circle().fill(Color.white)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.black)
                        }
                        .frame(width: 36, height: 36)
                        .shadow(radius: 2)
                    }
                    
                    Spacer()
                    
                Text("My Assets")
                    .font(.title2)
                    .fontWeight(.bold)
                    
                    Spacer()
                    
                    // 占位符保持标题居中
                    ZStack {
                        Circle().fill(Color.white)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16))
                            .foregroundStyle(.black)
                    }
                    .frame(width: 36, height: 36)
                    .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                
                Divider()
                
                // 用户信息卡片 - 毛玻璃样式
                HStack(spacing: 16) {
                    // 用户头像 - 毛玻璃样式（缩小到70%）
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
                        Image(systemName: "person.fill")
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
                        Text(username)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(myCheckIns.count + ovalCheckIns.count) Check-ins")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // My Bids按钮
                        Button(action: {
                            showMyBids = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 14))
                                Text("My Bids")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(appGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background {
                                ZStack {
                                    Color.clear.background(.ultraThinMaterial)
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            appGreen.opacity(0.15),
                                            appGreen.opacity(0.05)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                            }
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(appGreen.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Scan QR按钮
                        Button(action: {
                            showReceiveTransfer = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 16))
                                Text("Scan QR")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(appGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background {
                                ZStack {
                                    Color.clear.background(.ultraThinMaterial)
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            appGreen.opacity(0.15),
                                            appGreen.opacity(0.05)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                            }
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(appGreen.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
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
                    ProgressView("Loading your history...")
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
                } else if myCheckIns.isEmpty && ovalCheckIns.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Check-ins Yet")
                            .font(.headline)
                        Text("Start exploring and check in to buildings!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                                        // 显示Oval Office的第一条记录详情
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
                        currentUsername: username
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
                        onNavigateToOvalOffice: {
                            Logger.debug("📍 导航到Oval Office")
                            // 关闭详情
                            selectedOvalCheckIn = nil
                            
                            // 使用传入的回调
                            if let navigateCallback = onNavigateToOvalOffice {
                                navigateCallback()
                            }
                        },
                        currentUsername: username
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $showReceiveTransfer) {
            ReceiveTransferView(
                appGreen: appGreen,
                username: username,
                onClose: {
                    showReceiveTransfer = false
                },
                onTransferComplete: {
                    showReceiveTransfer = false
                    // 刷新历史记录
                    loadHistory()
                },
                nfcManager: nfcManager
            )
        }
        .fullScreenCover(isPresented: $showMyBids) {
            MyBidsView(
                appGreen: appGreen,
                currentUsername: username,
                onClose: {
                    showMyBids = false
                }
            )
        }
        .onAppear {
            Logger.debug("MyHistoryFullScreenView appeared, loading data...")
            loadHistory()
        }
    }
    
    private func loadHistory() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 加载Historic Buildings check-ins
                let buildings = try await BuildingCheckInManager.shared.fetchUserCheckIns(username: username)
                
                // 加载Oval Office check-ins
                let oval = try await OvalOfficeCheckInManager.shared.fetchUserCheckIns(username: username)
                
                await MainActor.run {
                    self.myCheckIns = buildings
                    self.ovalCheckIns = oval
                    
                    // 按building_id分组
                    self.buildingGroups = groupCheckInsByBuilding(buildings)
                    
                    self.isLoading = false
                    Logger.success("Loaded \(buildings.count) building check-ins and \(oval.count) oval office check-ins")
                    Logger.debug("📋 建筑分组: \(self.buildingGroups.count) 个建筑")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    Logger.error("Failed to load history: \(error.localizedDescription)")
                }
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
