//
//  AssetHistoryModal.swift
//  Phygital Asset
//
//  Created by AI Assistant on 2024
//

import SwiftUI

struct AssetHistoryModal: View {
    let building: Treasure?
    let onBack: () -> Void
    let onStartCheckIn: (String) -> Void // 启动Check-in的回调
    let nfcUuid: String? // 新增：NFC UUID，用于获取特定NFC的历史记录
    let currentUsername: String? // 当前用户名
    
    @State private var checkIns: [BuildingCheckIn] = []
    @State private var ovalOfficeCheckIns: [OvalOfficeCheckIn] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedBuildingCheckIn: BuildingCheckIn? = nil
    @State private var selectedOvalCheckIn: OvalOfficeCheckIn? = nil
    
    // 初始化方法
    init(building: Treasure?, onBack: @escaping () -> Void, onStartCheckIn: @escaping (String) -> Void, nfcUuid: String? = nil, currentUsername: String? = nil) {
        self.building = building
        self.onBack = onBack
        self.onStartCheckIn = onStartCheckIn
        self.nfcUuid = nfcUuid
        self.currentUsername = currentUsername
    }
    
    var body: some View {
        // 信息框 - 使用与office map相同的样式
        VStack(spacing: 0) {
            // 顶部标题区域
            HStack {
                Spacer()
                
                Text("Asset History")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: onBack) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            
            // 建筑信息
            if let building = building {
                VStack(spacing: 16) {
                    Text(building.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(building.address)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
                .background(Color(.systemBackground))
            }
            
            // 历史记录区域
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        // 加载中
                        ProgressView()
                            .padding(.vertical, 40)
                    } else if let error = errorMessage {
                        // 错误提示
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(appGreen.opacity(0.5))
                            Text("Failed to load history")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                    } else if checkIns.isEmpty && ovalOfficeCheckIns.isEmpty {
                        // 无历史记录
                        VStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No thread history yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Be the first to create a thread!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // 显示Building历史记录（不显示图片，可点击）
                        ForEach(checkIns) { checkIn in
                            CompactCheckInRow(
                                time: checkIn.createdAt,
                                assetName: checkIn.assetName ?? "Unknown",
                                description: checkIn.description,
                                appGreen: appGreen
                            )
                            .onTapGesture {
                                selectedBuildingCheckIn = checkIn
                            }
                        }
                        
                        // 显示Oval Office历史记录（不显示图片，可点击）
                        ForEach(ovalOfficeCheckIns) { checkIn in
                            CompactCheckInRow(
                                time: checkIn.createdAt,
                                assetName: checkIn.assetName ?? "Unknown",
                                description: checkIn.description,
                                appGreen: appGreen
                            )
                            .onTapGesture {
                                selectedOvalCheckIn = checkIn
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
            
            // Check-in按钮
            Button(action: {
                // 启动Check-in功能 - 直接打开输入框，不关闭Asset History
                if let building = building {
                    Logger.debug("Starting thread creation for building: \(building.name)")
                    
                    // 直接启动Check-in，不需要延迟
                    onStartCheckIn(building.id)
                } else {
                    // 探索模式：没有 building，使用 NFC UUID 作为标识
                    Logger.debug("🔍 探索模式：启动 Thread 创建（没有关联建筑）")
                    Logger.debug("   NFC UUID: \(nfcUuid ?? "nil")")
                    
                    // 使用空字符串或特殊标识来表示这是探索模式的 check-in
                    onStartCheckIn("")
                }
            }) {
                Text("Check In Mine")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(appGreen)
                    .frame(maxWidth: .infinity)
                    .padding()
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
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.white.opacity(0.6), location: 0.0),
                                        .init(color: Color.white.opacity(0.0), location: 0.3),
                                        .init(color: appGreen.opacity(0.2), location: 0.7),
                                        .init(color: appGreen.opacity(0.4), location: 1.0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: appGreen.opacity(0.2), radius: 8, x: 0, y: 4)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 10)
        }
        .frame(maxWidth: 340, maxHeight: 600)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 20)
        .overlay {
            // 建筑Check-in详情页
            if let checkIn = selectedBuildingCheckIn {
                CheckInDetailView(
                    checkIn: checkIn,
                    appGreen: appGreen,
                    onClose: {
                        selectedBuildingCheckIn = nil
                    },
                    onNavigate: nil,
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
                    onNavigateToOvalOffice: nil,
                    currentUsername: currentUsername
                )
            }
        }
        .onAppear {
            Logger.debug("🏛️ AssetHistoryModal 已显示")
            Logger.debug("   building: \(building?.name ?? "nil")")
            Logger.debug("   nfcUuid: \(nfcUuid ?? "nil")")
            loadCheckIns()
        }
    }
    
    private func loadCheckIns() {
        Logger.debug("📋 ========== 开始加载历史记录 ==========")
        Logger.debug("📋 nfcUuid: '\(nfcUuid ?? "nil")'")
        Logger.debug("📋 nfcUuid 长度: \(nfcUuid?.count ?? 0)")
        Logger.debug("📋 building: \(building?.name ?? "nil")")
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                var fetchedCheckIns: [BuildingCheckIn] = []
                var fetchedOvalOfficeCheckIns: [OvalOfficeCheckIn] = []
                
                if let nfcUuid = nfcUuid {
                    // 根据NFC UUID获取所有表的历史记录
                    Logger.success("✅ 检测到 NFC UUID，将从两个表查询")
                    Logger.debug("📋 查询的 NFC UUID: '\(nfcUuid)'")
                    Logger.debug("📋 UUID 长度: \(nfcUuid.count) 字符")
                    
                    // 1. 从 threads 表获取
                    do {
                        Logger.debug("📋 [1/2] 开始查询 threads 表...")
                        fetchedCheckIns = try await BuildingCheckInManager.shared.getCheckInsByNFC(nfcUuid: nfcUuid)
                        Logger.success("📋 [1/2] ✅ 从 threads 获取到 \(fetchedCheckIns.count) 条记录")
                        
                        if fetchedCheckIns.isEmpty {
                            Logger.warning("📋 [1/2] ⚠️ threads 表中没有找到此 UUID 的记录")
                        } else {
                            for (i, checkIn) in fetchedCheckIns.enumerated() {
                                Logger.debug("📋    记录 \(i+1): \(checkIn.username) - \(checkIn.assetName ?? "无名称")")
                            }
                        }
                    } catch {
                        Logger.error("📋 [1/2] ❌ 从 threads 获取失败: \(error.localizedDescription)")
                    }
                    
                    // 2. 从 oval_office_threads 表获取
                    do {
                        Logger.debug("📋 [2/2] 开始查询 oval_office_threads 表...")
                        fetchedOvalOfficeCheckIns = try await OvalOfficeCheckInManager.shared.getCheckInsByNFC(nfcUuid: nfcUuid)
                        Logger.success("📋 [2/2] ✅ 从 oval_office_threads 获取到 \(fetchedOvalOfficeCheckIns.count) 条记录")
                        
                        if fetchedOvalOfficeCheckIns.isEmpty {
                            Logger.warning("📋 [2/2] ⚠️ oval_office_threads 表中没有找到此 UUID 的记录")
                        } else {
                            for (i, checkIn) in fetchedOvalOfficeCheckIns.enumerated() {
                                Logger.debug("📋    记录 \(i+1): \(checkIn.username) - \(checkIn.assetName ?? "无名称")")
                            }
                        }
                    } catch {
                        Logger.error("📋 [2/2] ❌ 从 oval_office_threads 获取失败: \(error.localizedDescription)")
                    }
                    
                } else if let building = building {
                    // 根据建筑ID获取历史记录（只查 threads）
                    Logger.debug("📋 根据建筑ID获取历史记录: \(building.id)")
                    fetchedCheckIns = try await BuildingCheckInManager.shared.getCheckIns(for: building.id)
                    Logger.success("📋 获取到 \(fetchedCheckIns.count) 条建筑历史记录")
                } else {
                    // 没有指定建筑或NFC UUID
                    Logger.warning("📋 没有指定建筑或NFC UUID")
                }
                
                let totalCount = fetchedCheckIns.count + fetchedOvalOfficeCheckIns.count
                
                await MainActor.run {
                    self.checkIns = fetchedCheckIns
                    self.ovalOfficeCheckIns = fetchedOvalOfficeCheckIns
                    self.isLoading = false
                    Logger.success("📋 历史记录加载完成，共 \(totalCount) 条 (Buildings: \(fetchedCheckIns.count), OvalOffice: \(fetchedOvalOfficeCheckIns.count))")
                    
                    // 详细调试信息
                    Logger.debug("📋 最终状态:")
                    Logger.debug("   checkIns.isEmpty: \(fetchedCheckIns.isEmpty)")
                    Logger.debug("   ovalOfficeCheckIns.isEmpty: \(fetchedOvalOfficeCheckIns.isEmpty)")
                    Logger.debug("   isLoading: \(self.isLoading)")
                    Logger.debug("   errorMessage: \(self.errorMessage ?? "nil")")
                    
                    if !fetchedCheckIns.isEmpty {
                        for (i, checkIn) in fetchedCheckIns.enumerated() {
                            Logger.debug("📋 Building记录 \(i+1): \(checkIn.username) - \(checkIn.assetName ?? "无名称") (NFC: \(checkIn.nfcUuid ?? "nil"))")
                        }
                    }
                    
                    if !fetchedOvalOfficeCheckIns.isEmpty {
                        for (i, checkIn) in fetchedOvalOfficeCheckIns.enumerated() {
                            Logger.debug("📋 OvalOffice记录 \(i+1): \(checkIn.username) - \(checkIn.assetName ?? "无名称") (NFC: \(checkIn.nfcUuid ?? "nil"))")
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                Logger.error("📋 加载历史记录失败: \(error.localizedDescription)")
            }
        }
    }
}
