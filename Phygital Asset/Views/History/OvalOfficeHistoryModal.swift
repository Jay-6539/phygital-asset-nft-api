//
//  OvalOfficeHistoryModal.swift
//  Phygital Asset
//
//  Oval Office 历史记录弹窗（包含 ZOOM IN 按钮）
//

import SwiftUI

struct OvalOfficeHistoryModal: View {
    let building: Treasure?
    let appGreen: Color
    let onStartCheckIn: (String) -> Void
    let onZoomIn: () -> Void // 新增：ZOOM IN 回调
    let onClose: () -> Void
    let nfcUuid: String? // 新增：NFC UUID，用于获取特定NFC的历史记录
    
    @State private var checkIns: [BuildingCheckIn] = []
    @State private var ovalOfficeCheckIns: [OvalOfficeCheckIn] = []
    @State private var isLoading = false
    
    // 初始化方法
    init(building: Treasure?, appGreen: Color, onStartCheckIn: @escaping (String) -> Void, onZoomIn: @escaping () -> Void, onClose: @escaping () -> Void, nfcUuid: String? = nil) {
        self.building = building
        self.appGreen = appGreen
        self.onStartCheckIn = onStartCheckIn
        self.onZoomIn = onZoomIn
        self.onClose = onClose
        self.nfcUuid = nfcUuid
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("Oval Office History")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    onClose()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .padding(.bottom, 10)
            
            // 建筑信息
            if let building = building {
                VStack(spacing: 16) {
                    Text(building.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(building.address)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            
            // 历史记录区域
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.vertical, 40)
                    } else if checkIns.isEmpty && ovalOfficeCheckIns.isEmpty {
                        // 显示空状态
                        VStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No check-in history yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // 显示历史记录
                        ForEach(checkIns) { checkIn in
                            BuildingCheckInRow(checkIn: checkIn)
                        }
                        
                        ForEach(ovalOfficeCheckIns) { checkIn in
                            OvalOfficeCheckInRow(checkIn: checkIn, appGreen: appGreen)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
            
            // Check-in 按钮
            Button(action: {
                if let building = building {
                    Logger.debug("Starting check-in for Oval Office: \(building.name)")
                    onStartCheckIn(building.id)
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
            .padding(.top, 10)
            
            // ZOOM IN 按钮
            Button(action: {
                Logger.debug("🔍 Zoom In button tapped - opening Oval Office map")
                onZoomIn()
            }) {
                Text("Zoom In")
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
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: 340, maxHeight: 600)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 20)
        .onAppear {
            Logger.debug("🏛️ OvalOfficeHistoryModal 已显示")
            Logger.debug("   building: \(building?.name ?? "nil")")
            Logger.debug("   nfcUuid: \(nfcUuid ?? "nil")")
            loadHistory()
        }
    }
    
    // 加载历史记录
    private func loadHistory() {
        Logger.debug("📋 ========== 开始加载Oval Office历史记录 ==========")
        Logger.debug("📋 nfcUuid: '\(nfcUuid ?? "nil")'")
        Logger.debug("📋 building: \(building?.name ?? "nil")")
        
        isLoading = true
        
        Task {
            do {
                var fetchedCheckIns: [BuildingCheckIn] = []
                var fetchedOvalOfficeCheckIns: [OvalOfficeCheckIn] = []
                
                if let nfcUuid = nfcUuid {
                    // 根据NFC UUID获取所有表的历史记录
                    Logger.success("✅ 检测到 NFC UUID，将从两个表查询")
                    Logger.debug("📋 查询的 NFC UUID: '\(nfcUuid)'")
                    
                    // 1. 从 threads 表获取
                    do {
                        Logger.debug("📋 [1/2] 开始查询 threads 表...")
                        fetchedCheckIns = try await BuildingCheckInManager.shared.getCheckInsByNFC(nfcUuid: nfcUuid)
                        Logger.success("📋 [1/2] ✅ 从 threads 获取到 \(fetchedCheckIns.count) 条记录")
                    } catch {
                        Logger.error("📋 [1/2] ❌ 从 threads 获取失败: \(error.localizedDescription)")
                    }
                    
                    // 2. 从 oval_office_threads 表获取
                    do {
                        Logger.debug("📋 [2/2] 开始查询 oval_office_threads 表...")
                        fetchedOvalOfficeCheckIns = try await OvalOfficeCheckInManager.shared.getCheckInsByNFC(nfcUuid: nfcUuid)
                        Logger.success("📋 [2/2] ✅ 从 oval_office_threads 获取到 \(fetchedOvalOfficeCheckIns.count) 条记录")
                    } catch {
                        Logger.error("📋 [2/2] ❌ 从 oval_office_threads 获取失败: \(error.localizedDescription)")
                    }
                    
                } else if let building = building {
                    // 根据建筑ID获取历史记录（只查 threads）
                    Logger.debug("📋 根据建筑ID获取历史记录: \(building.id)")
                    fetchedCheckIns = try await BuildingCheckInManager.shared.getCheckIns(for: building.id)
                    Logger.success("📋 获取到 \(fetchedCheckIns.count) 条建筑历史记录")
                } else {
                    Logger.warning("📋 没有指定建筑或NFC UUID")
                }
                
                let totalCount = fetchedCheckIns.count + fetchedOvalOfficeCheckIns.count
                
                await MainActor.run {
                    self.checkIns = fetchedCheckIns
                    self.ovalOfficeCheckIns = fetchedOvalOfficeCheckIns
                    self.isLoading = false
                    Logger.success("📋 Oval Office历史记录加载完成，共 \(totalCount) 条")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    Logger.error("❌ 加载历史记录失败: \(error.localizedDescription)")
                }
            }
        }
    }
}

