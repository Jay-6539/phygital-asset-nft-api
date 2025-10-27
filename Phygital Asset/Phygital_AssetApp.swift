//
//  Phygital_AssetApp.swift
//  Phygital Asset
//
//  Created by Jay on 19/8/2025.
//

import SwiftUI
import FacebookCore
import GoogleSignIn
import os

// MARK: - 启动时间测量
enum StartupTime {
    static let osLogger = os.Logger(subsystem: "com.jay.phygitalasset", category: "startup")
    static let start = CFAbsoluteTimeGetCurrent()

    static func mark(_ label: String) {
        let t = CFAbsoluteTimeGetCurrent() - start
        osLogger.log("⏱️ \(label, privacy: .public): \(String(format: "%.3f", t))s")
        Logger.info("⏱️ \(label): \(String(format: "%.3f", t))s")
    }
}

@main
struct Phygital_AssetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .onAppear {
                        StartupTime.mark("ContentView onAppear")
                    }
                // 启动覆盖层（带进度条和Logo放大淡出）
                SplashOverlayHost()
            }
                .onOpenURL { url in
                    // 处理 Google Sign-In 回调
                    GIDSignIn.sharedInstance.handle(url)
                    
                    // 处理 Facebook 回调
                    ApplicationDelegate.shared.application(
                        UIApplication.shared,
                        open: url,
                        sourceApplication: nil,
                        annotation: [UIApplication.OpenURLOptionsKey.annotation]
                    )
                }
        }
    }
}

// App Delegate for Facebook SDK initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        StartupTime.mark("AppDelegate.didFinishLaunching start")
        
        // 初始化 Facebook SDK
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        // 🎨 启用NFT铸造功能
        NFTManager.shared.setNFTEnabled(true)
        
        // 🏥 检查NFT服务健康状态（后台执行）
        Task.detached {
            let isHealthy = await NFTManager.shared.checkServiceHealth()
            Logger.debug("🎨 NFT服务状态: \(isHealthy ? "可用" : "不可用")")
        }
        
        StartupTime.mark("AppDelegate.didFinishLaunching end")
        return true
    }
}

// 容器：控制启动覆盖层的显示与消失
private struct SplashOverlayHost: View {
    @State private var showSplash: Bool = true
    @ObservedObject private var loadingState = AppLoadingState.shared
    
    var body: some View {
        Group {
            if showSplash {
                SplashOverlayView(
                    isShowing: $showSplash,
                    isContentReady: $loadingState.isContentReady
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.25), value: showSplash)
    }
}

// 全局应用加载状态
class AppLoadingState: ObservableObject {
    static let shared = AppLoadingState()
    @Published var isContentReady: Bool = false
    
    private init() {}
}
