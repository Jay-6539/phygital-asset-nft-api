//
//  DebugDashboard.swift
//  Treasure Hunt, Hong Kong Park
//
//  Debug 性能监控面板 - 仅在 Debug 模式显示
//

import SwiftUI

#if DEBUG
struct DebugDashboard: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showDashboard = false
    
    let appGreen: Color
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                // 浮动按钮 - 白色毛玻璃效果（品牌绿色图标）
                Button(action: {
                    showDashboard.toggle()
                }) {
                    Image(systemName: "ladybug.fill")
                        .font(.system(size: 24))
                        .foregroundColor(appGreen)
                        .frame(width: 50, height: 50)
                        .background {
                            ZStack {
                                Color.clear.background(.ultraThinMaterial)
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.2)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                        }
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color.white.opacity(0.8), location: 0.0),
                                            .init(color: Color.white.opacity(0.0), location: 0.4),
                                            .init(color: Color.white.opacity(0.0), location: 0.6),
                                            .init(color: Color.white.opacity(0.3), location: 1.0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: appGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showDashboard) {
            DebugDashboardSheet()
        }
    }
}

struct DebugDashboardSheet: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // 网络状态
                Section("Network Status") {
                    HStack {
                        Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                            .foregroundColor(networkMonitor.isConnected ? .green : .red)
                        Text(networkMonitor.isConnected ? "Connected" : "Disconnected")
                        Spacer()
                        Text(networkMonitor.connectionType.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 启动性能
                Section("Performance") {
                    HStack {
                        Text("App Launch")
                        Spacer()
                        Text("~\(String(format: "%.2f", StartupTime.getElapsedTime()))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 配置信息
                Section("Configuration") {
                    HStack {
                        Text("Supabase URL")
                        Spacer()
                        Text(SupabaseConfig.url.replacingOccurrences(of: "https://", with: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Text("Buildings URL")
                        Spacer()
                        Text(HistoricBuildingsConfig.url.replacingOccurrences(of: "https://", with: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // 存储信息
                Section("Storage") {
                    HStack {
                        Text("Keychain Available")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("UserDefaults")
                        Spacer()
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 操作按钮
                Section("Actions") {
                    Button(action: {
                        // 清除所有缓存
                        UserSessionManager.shared.clearSession()
                        KeychainManager.shared.deleteAll()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clear All Data")
                                .foregroundColor(.red)
                        }
                    }
                    
                    ClearOfficeDataButton()
                }
            }
            .navigationTitle("Debug Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 清理 Office Map 数据的按钮
struct ClearOfficeDataButton: View {
    @State private var showConfirmation = false
    @State private var isClearing = false
    @State private var showResult = false
    @State private var resultMessage = ""
    
    var body: some View {
        Button(action: {
            showConfirmation = true
        }) {
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(.orange)
                Text("Clear Office Map Assets")
                    .foregroundColor(.orange)
            }
        }
        .disabled(isClearing)
        .alert("⚠️ 确认清空 Office Map", isPresented: $showConfirmation) {
            Button("取消", role: .cancel) {}
            Button("确认清空", role: .destructive) {
                clearOfficeData()
            }
        } message: {
            Text("此操作将删除：\n• 所有本地 Office Assets\n• 所有云端 Office Assets\n• 所有 Oval Office Check-ins\n\n⚠️ 此操作不可逆！")
        }
        .alert("清理结果", isPresented: $showResult) {
            Button("确定") {
                showResult = false
            }
        } message: {
            Text(resultMessage)
        }
        .overlay {
            if isClearing {
                ProgressView()
            }
        }
    }
    
    private func clearOfficeData() {
        isClearing = true
        
        Task {
            do {
                Logger.database("🗑️ 开始清理 Office Map 数据...")
                
                // 1. 清理本地和云端 Assets
                PersistenceManager.shared.clearAllData()
                
                // 2. 清理 Oval Office Check-ins
                try await clearOvalOfficeCheckIns()
                
                // 延迟确保操作完成
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    isClearing = false
                    resultMessage = "✅ 清理完成！\n\n已删除：\n• 本地 Office Assets\n• 云端 Office Assets\n• Oval Office Check-ins"
                    showResult = true
                    Logger.success("✅ Office Map 数据清理完成")
                }
            } catch {
                await MainActor.run {
                    isClearing = false
                    resultMessage = "❌ 清理失败\n\n\(error.localizedDescription)"
                    showResult = true
                    Logger.error("❌ 清理失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func clearOvalOfficeCheckIns() async throws {
        let baseURL = SupabaseConfig.url
        let apiKey = SupabaseConfig.anonKey
        
        // 删除所有 oval_office_checkins 记录
        guard let url = URL(string: "\(baseURL)/rest/v1/oval_office_checkins") else {
            throw NSError(domain: "InvalidURL", code: -1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("*", forHTTPHeaderField: "Prefer")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: -1)
        }
        
        Logger.debug("Clear response: \(httpResponse.statusCode)")
        Logger.debug("Clear response body: \(String(data: data, encoding: .utf8) ?? "")")
        
        guard httpResponse.statusCode == 204 || httpResponse.statusCode == 200 else {
            throw NSError(domain: "DeleteFailed", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"
            ])
        }
        
        Logger.success("✅ Oval Office Check-ins 清理完成")
    }
}

// 扩展StartupTime以支持获取当前经过时间
extension StartupTime {
    static func getElapsedTime() -> Double {
        return CFAbsoluteTimeGetCurrent() - start
    }
}
#endif

