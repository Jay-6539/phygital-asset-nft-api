//
//  NFCScanView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Created by AI Assistant on 2024
//

import SwiftUI
import CoreLocation

struct NFCScanView: View {
    let onNFCDetected: (CLLocationCoordinate2D) -> Void
    let onCancel: () -> Void
    
    @StateObject private var nfcManager = NFCManager()
    @State private var isScanning = false
    
    var body: some View {
        VStack(spacing: 30) {
            // 顶部导航栏
            HStack {
                Button(action: onCancel) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                        Text("Back")
                            .font(.headline)
                    }
                    .foregroundColor(appGreen)
                }
                
                Spacer()
                
                Text("NFC Scan")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 占位符，保持标题居中
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                    Text("Back")
                        .font(.headline)
                }
                .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // 内容区域
            VStack(spacing: 30) {
                // NFC图标
                Image(systemName: isScanning ? "sensor.tag.radiowaves.forward.fill" : "sensor.tag.radiowaves.forward")
                    .font(.system(size: 80))
                    .foregroundColor(isScanning ? appGreen : .gray)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isScanning)
                
                // 说明文字
                VStack(spacing: 16) {
                    Text(isScanning ? "Scanning for NFC..." : "Ready to Scan NFC")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(isScanning ? "Hold your iPhone near the NFC tag" : "Tap the button below to start scanning")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // NFC状态消息
                if !nfcManager.nfcMessage.isEmpty {
                    Text(nfcManager.nfcMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // 按钮
                VStack(spacing: 16) {
                    if !isScanning {
                        Button(action: {
                            startNFCScan()
                        }) {
                            HStack {
                                Image(systemName: "sensor.tag.radiowaves.forward")
                                    .font(.title2)
                                Text("Start NFC Scan")
                                    .font(.headline)
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(appGreen)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background {
                                ZStack {
                                    Color.clear.background(.ultraThinMaterial)
                                    appGreen.opacity(0.1)
                                }
                            }
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(appGreen.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 40)
                    } else {
                        Button(action: {
                            stopNFCScan()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle")
                                    .font(.title2)
                                Text("Stop Scanning")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    // 测试按钮（开发用）
                    Button(action: {
                        // 模拟NFC检测成功，返回一个坐标
                        onNFCDetected(CLLocationCoordinate2D(latitude: 22.35, longitude: 114.15))
                    }) {
                        Text("Simulate NFC Detection (Test)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            setupNFCCallbacks()
        }
        .onDisappear {
            stopNFCScan()
        }
    }
    
    private func setupNFCCallbacks() {
        nfcManager.onNFCDetected = {
            // NFC检测成功，返回当前位置或NFC标签位置
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isScanning = false
                // 使用当前位置作为NFC坐标（实际应用中应该从NFC标签读取）
                if let location = CLLocationManager().location {
                    onNFCDetected(location.coordinate)
                } else {
                    // 备用坐标
                    onNFCDetected(CLLocationCoordinate2D(latitude: 22.35, longitude: 114.15))
                }
            }
        }
        
        nfcManager.onNFCError = { error in
            DispatchQueue.main.async {
                isScanning = false
                Logger.nfc("NFC Error: \(error)")
            }
        }
    }
    
    private func startNFCScan() {
        guard nfcManager.isNFCAvailable else {
            nfcManager.nfcMessage = "NFC is not available on this device"
            return
        }
        
        isScanning = true
        nfcManager.nfcMessage = ""
        
        // 使用探索扫描模式来读取任何NFC标签
        nfcManager.startExploreScan()
    }
    
    private func stopNFCScan() {
        isScanning = false
        nfcManager.stopScanning()
        nfcManager.nfcMessage = "Scanning stopped"
    }
}
