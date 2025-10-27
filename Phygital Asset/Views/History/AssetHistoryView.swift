//
//  AssetHistoryView.swift
//  Phygital Asset
//
//  Created by AI Assistant on 2024
//

import SwiftUI
import CoreLocation

struct AssetHistoryView: View {
    let targetBuilding: Treasure?
    let nfcCoordinate: CLLocationCoordinate2D?
    let nfcUuid: String? // 新增：NFC UUID
    let onBackToNavigation: () -> Void
    let onShowNFCMismatch: () -> Void
    let onStartCheckIn: (String) -> Void // 启动Check-in的回调
    let currentUsername: String? // 当前用户名
    
    @State private var isFirstRegistration: Bool = false
    @State private var isCheckingHistory: Bool = true
    
    var body: some View {
        // 检查坐标匹配
        Group {
            if let building = targetBuilding, let nfcCoord = nfcCoordinate {
                // 调试日志
                let _ = {
                    Logger.debug("🔍 AssetHistoryView 显示逻辑判断:")
                    Logger.debug("   isCheckingHistory: \(isCheckingHistory)")
                    Logger.debug("   isFirstRegistration: \(isFirstRegistration)")
                }()
                
                if isCheckingHistory {
                    // 正在检查历史记录
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Checking history...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                } else if isFirstRegistration {
                    // 🆕 第一次注册，跳过GPS检查，直接显示历史框
                    let _ = Logger.success("✅ 显示历史框（第一次注册，已跳过GPS检查）")
                    AssetHistoryModal(
                        building: building, 
                        onBack: onBackToNavigation,
                        onStartCheckIn: onStartCheckIn,
                        nfcUuid: nfcUuid,
                        currentUsername: currentUsername
                    )
                } else if isCoordinateMatch(building: building, nfcCoordinate: nfcCoord) {
                    // 坐标匹配，显示正常的历史信息框
                    let _ = Logger.success("✅ 显示历史框（GPS坐标匹配）")
                    AssetHistoryModal(
                        building: building, 
                        onBack: onBackToNavigation,
                        onStartCheckIn: onStartCheckIn,
                        nfcUuid: nfcUuid,
                        currentUsername: currentUsername
                    )
                } else {
                    // 坐标不匹配，显示错误信息
                    let _ = Logger.error("❌ 显示GPS错误框（坐标不匹配）")
                    NFCErrorModal(onBack: onBackToNavigation)
                }
            } else {
                // 探索模式：没有 targetBuilding，直接显示历史记录
                let _ = Logger.debug("🔍 探索模式：targetBuilding = nil，直接显示历史记录")
                AssetHistoryModal(
                    building: targetBuilding, 
                    onBack: onBackToNavigation,
                    onStartCheckIn: onStartCheckIn,
                    nfcUuid: nfcUuid,
                    currentUsername: currentUsername
                )
            }
        }
        .onAppear {
            Logger.debug("🏛️ AssetHistoryView 已显示")
            Logger.debug("   targetBuilding: \(targetBuilding?.name ?? "nil")")
            Logger.debug("   nfcCoordinate: \(nfcCoordinate != nil ? "有坐标" : "nil")")
            Logger.debug("   nfcUuid: \(nfcUuid ?? "nil")")
            
            // 检查是否为第一次注册
            if let building = targetBuilding {
                Task {
                    do {
                        let existingCheckIns = try await BuildingCheckInManager.shared.getCheckIns(for: building.id)
                        await MainActor.run {
                            isFirstRegistration = existingCheckIns.isEmpty
                            isCheckingHistory = false
                            
                            if isFirstRegistration {
                                Logger.success("🆕 第一次注册此建筑，跳过GPS距离检查")
                            } else {
                                Logger.debug("📋 建筑已有 \(existingCheckIns.count) 条记录，将进行GPS验证")
                            }
                        }
                    } catch {
                        Logger.error("❌ 检查历史记录失败: \(error.localizedDescription)")
                        // 失败时默认跳过GPS检查
                        await MainActor.run {
                            isFirstRegistration = true
                            isCheckingHistory = false
                        }
                    }
                }
            } else {
                isCheckingHistory = false
            }
        }
    }
    
    // 检查坐标是否匹配（距离小于30米）
    private func isCoordinateMatch(building: Treasure, nfcCoordinate: CLLocationCoordinate2D) -> Bool {
        let buildingLocation = CLLocation(latitude: building.coordinate.latitude, longitude: building.coordinate.longitude)
        let nfcLocation = CLLocation(latitude: nfcCoordinate.latitude, longitude: nfcCoordinate.longitude)
        let distance = buildingLocation.distance(from: nfcLocation)
        
        Logger.location("📍 Coordinate match check:")
        Logger.debug("   Building: \(building.name) - \(building.coordinate)")
        Logger.debug("   NFC: \(nfcCoordinate)")
        Logger.debug("   Distance: \(String(format: "%.2f", distance)) meters")
        Logger.debug("   isFirstRegistration: \(isFirstRegistration)")
        Logger.debug("   Match: \(distance < 40.0 ? "✅ YES" : "❌ NO") (< 40m)")
        
        return distance < 40.0 // 小于40米
    }
}
