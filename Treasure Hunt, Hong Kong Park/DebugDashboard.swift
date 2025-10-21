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

// 扩展StartupTime以支持获取当前经过时间
extension StartupTime {
    static func getElapsedTime() -> Double {
        return CFAbsoluteTimeGetCurrent() - start
    }
}
#endif

