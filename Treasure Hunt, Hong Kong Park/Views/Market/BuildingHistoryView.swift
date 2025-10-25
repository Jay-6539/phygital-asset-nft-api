//
//  BuildingHistoryView.swift
//  Treasure Hunt, Hong Kong Park
//
//  显示建筑的历史记录列表（Market中使用，不显示图片）
//

import SwiftUI

struct BuildingHistoryView: View {
    let building: BuildingWithStats
    let appGreen: Color
    let onClose: () -> Void
    let currentUsername: String?
    
    @State private var buildingRecords: [BuildingCheckIn] = []
    @State private var ovalRecords: [OvalOfficeCheckIn] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedBuildingRecord: BuildingCheckIn?
    @State private var selectedOvalRecord: OvalOfficeCheckIn?
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - 顶部导航栏
                HStack {
                    // 返回按钮
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
                    
                    VStack(spacing: 2) {
                        Text(building.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        
                        Text("\(buildingRecords.count + ovalRecords.count) records")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 占位符保持标题居中
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                
                Divider()
                
                // MARK: - 内容区域
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading records...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red.opacity(0.6))
                        
                        Text("Failed to load")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if buildingRecords.isEmpty && ovalRecords.isEmpty {
                    // 空状态
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(appGreen.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "doc.text")
                                .font(.system(size: 48))
                                .foregroundColor(appGreen.opacity(0.6))
                        }
                        
                        VStack(spacing: 8) {
                            Text("No Records Yet")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Be the first to check in\nat this building!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Building check-ins
                            ForEach(buildingRecords) { record in
                                CompactHistoryRow(
                                    username: record.username,
                                    description: record.description,
                                    createdAt: record.createdAt,
                                    appGreen: appGreen
                                )
                                .onTapGesture {
                                    selectedBuildingRecord = record
                                }
                            }
                            
                            // Oval Office check-ins
                            ForEach(ovalRecords) { record in
                                CompactHistoryRow(
                                    username: record.username,
                                    description: record.description.isEmpty ? record.assetName : record.description,
                                    createdAt: record.createdAt,
                                    appGreen: appGreen,
                                    isOvalOffice: true
                                )
                                .onTapGesture {
                                    selectedOvalRecord = record
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .onAppear {
            loadBuildingHistory()
        }
        // Detail overlays
        .overlay {
            if let record = selectedBuildingRecord {
                CheckInDetailView(
                    checkIn: record,
                    appGreen: appGreen,
                    currentUsername: currentUsername,
                    onClose: { selectedBuildingRecord = nil }
                )
            }
        }
        .overlay {
            if let record = selectedOvalRecord {
                OvalOfficeCheckInDetailView(
                    checkIn: record,
                    appGreen: appGreen,
                    currentUsername: currentUsername,
                    onClose: { selectedOvalRecord = nil }
                )
            }
        }
    }
    
    // MARK: - Load History
    private func loadBuildingHistory() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 并行加载建筑和Oval Office记录
                async let buildingTask = BuildingCheckInManager.shared.loadCheckIns(forBuilding: building.id)
                async let ovalTask = OvalOfficeCheckInManager.shared.loadCheckIns(forBuilding: building.id)
                
                let (buildings, ovals) = try await (buildingTask, ovalTask)
                
                await MainActor.run {
                    self.buildingRecords = buildings.sorted { $0.createdAt > $1.createdAt }
                    self.ovalRecords = ovals.sorted { $0.createdAt > $1.createdAt }
                    self.isLoading = false
                }
                
                Logger.success("✅ Loaded \(buildings.count) building records + \(ovals.count) oval records")
            } catch {
                Logger.error("❌ Failed to load building history: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Compact History Row (无图片版本)
struct CompactHistoryRow: View {
    let username: String
    let description: String
    let createdAt: Date
    let appGreen: Color
    var isOvalOffice: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 用户头像占位符
            ZStack {
                Circle()
                    .fill(appGreen.opacity(0.2))
                
                Image(systemName: isOvalOffice ? "square.grid.2x2" : "building.2")
                    .font(.system(size: 16))
                    .foregroundColor(appGreen)
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("@\(username)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(timeAgo(createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        
        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else {
            let minutes = max(1, Int(interval / 60))
            return "\(minutes)m ago"
        }
    }
}

#Preview {
    BuildingHistoryView(
        building: BuildingWithStats(
            id: "1",
            name: "Victoria Peak",
            district: "Central",
            coordinate: .init(latitude: 22.27, longitude: 114.15),
            recordCount: 125,
            lastActivityTime: Date(),
            rank: 1
        ),
        appGreen: .green,
        onClose: {},
        currentUsername: "testuser"
    )
}

