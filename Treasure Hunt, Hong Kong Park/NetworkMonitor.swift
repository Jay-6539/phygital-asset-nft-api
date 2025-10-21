//
//  NetworkMonitor.swift
//  Treasure Hunt, Hong Kong Park
//
//  网络状态监控器 - 监听网络连接状态
//

import Foundation
import Network
import SwiftUI

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
        
        var description: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .unknown: return "Unknown"
            }
        }
    }
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasConnected = self?.isConnected ?? true
                self?.isConnected = path.status == .satisfied
                
                // 更新连接类型
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .ethernet
                } else {
                    self?.connectionType = .unknown
                }
                
                // 记录网络状态变化
                if let isConnected = self?.isConnected, wasConnected != isConnected {
                    if isConnected {
                        Logger.network("Network connected - \(self?.connectionType.description ?? "Unknown")")
                    } else {
                        Logger.warning("Network disconnected")
                    }
                }
            }
        }
        
        monitor.start(queue: queue)
        Logger.info("NetworkMonitor started")
    }
    
    func stopMonitoring() {
        monitor.cancel()
        Logger.info("NetworkMonitor stopped")
    }
    
    deinit {
        stopMonitoring()
    }
}

