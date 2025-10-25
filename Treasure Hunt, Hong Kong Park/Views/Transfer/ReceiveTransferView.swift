//
//  ReceiveTransferView.swift
//  Treasure Hunt, Hong Kong Park
//
//  接收转让界面
//

import SwiftUI
import AVFoundation

struct ReceiveTransferView: View {
    let appGreen: Color
    let username: String
    let onClose: () -> Void
    let onTransferComplete: () -> Void
    let nfcManager: NFCManager
    
    @State private var isScanning = true
    @State private var transferData: TransferQRData?
    @State private var transferRequest: TransferRequest?
    @State private var isVerifying = false
    @State private var showNFCScanner = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showCameraScanner = false
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部栏
                HStack {
                    Spacer()
                    
                    Text("Receive Transfer")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                Divider()
                
                // 主内容
                if showCameraScanner {
                    // 相机扫描界面
                    Color.clear
                        .overlay(
                            QRCodeScannerView(
                                onCodeScanned: { code in
                                    showCameraScanner = false
                                    processQRCode(code)
                                },
                                onCancel: {
                                    showCameraScanner = false
                                    isScanning = true
                                }
                            )
                            .ignoresSafeArea()
                        )
                } else if isScanning {
                    // QR码扫描引导界面
                    qrScannerView
                } else if let data = transferData {
                    // 转让确认界面
                    transferConfirmationView(data: data)
                }
            }
            .frame(maxWidth: 400, maxHeight: 650)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                isScanning = true
            }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
    
    // MARK: - QR码扫描视图
    
    private var qrScannerView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // 扫描图标
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 100))
                .foregroundColor(appGreen)
            
            Text("Scan Transfer QR Code")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Point your camera at the QR code shown on the sender's screen")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            // 扫描按钮
            Button(action: {
                showCameraScanner = true
            }) {
                Text("Start Scanning")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(appGreen)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - 转让确认视图
    
    private func transferConfirmationView(data: TransferQRData) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // 转让信息
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(appGreen)
                    
                    Text("Transfer Received")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // 记录信息
                    VStack(alignment: .leading, spacing: 12) {
                        infoRow(label: "Building", value: data.buildingName)
                        infoRow(label: "Asset", value: data.assetName)
                        infoRow(label: "From", value: data.fromUser)
                        
                        // 过期时间
                        HStack {
                            Text("Expires")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(data.expiresAt, style: .relative)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                // 警告提示
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Verification Required")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("You must scan the NFC tag at the location to accept this transfer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
                // 按钮组
                VStack(spacing: 12) {
                    // 扫描NFC按钮
                    Button(action: {
                        startNFCVerification(data: data)
                    }) {
                        HStack {
                            Image(systemName: "wave.3.right")
                            Text("Scan NFC to Accept")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(appGreen)
                        .cornerRadius(12)
                    }
                    .disabled(isVerifying)
                    
                    // 拒绝按钮
                    Button(action: {
                        isScanning = true
                        transferData = nil
                    }) {
                        Text("Decline")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 2)
                            )
                            .cornerRadius(12)
                    }
                }
                
                if isVerifying {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Verifying...")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - 辅助视图
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - 辅助方法
    
    private func processQRCode(_ qrString: String) {
        Logger.debug("Processing QR code: \(qrString)")
        
        // 解析URL scheme
        guard qrString.hasPrefix("treasurehunt://transfer/") else {
            showErrorMessage("Invalid QR code")
            return
        }
        
        let jsonString = String(qrString.dropFirst("treasurehunt://transfer/".count))
        
        guard let data = TransferQRData.fromJSONString(jsonString) else {
            showErrorMessage("Failed to parse transfer data")
            return
        }
        
        // 检查是否过期
        if Date() > data.expiresAt {
            showErrorMessage("This transfer has expired")
            return
        }
        
        // 显示确认界面
        self.transferData = data
        self.isScanning = false
        
        // 获取完整的转让请求信息
        Task {
            do {
                let request = try await TransferManager.shared.getTransferRequest(transferCode: data.transferCode)
                await MainActor.run {
                    self.transferRequest = request
                }
            } catch {
                Logger.error("Failed to fetch transfer request: \(error.localizedDescription)")
            }
        }
    }
    
    private func startNFCVerification(data: TransferQRData) {
        Logger.debug("Starting NFC verification for transfer")
        Logger.debug("  Expected NFC UUID: \(data.nfcUuid)")
        isVerifying = true
        
        // 启动NFC探索扫描
        nfcManager.startExploreScan()
        
        // 设置NFC回调
        nfcManager.onNFCDetected = {
            Logger.success("✅ NFC扫描成功（Transfer验证）")
            
            DispatchQueue.main.async {
                let scannedUuid = self.nfcManager.assetUUID
                Logger.debug("  Scanned NFC UUID: \(scannedUuid)")
                
                // 验证UUID是否匹配
                if scannedUuid == data.nfcUuid {
                    Logger.success("✅ NFC UUID匹配，完成转让")
                    self.completeTransfer(data: data, scannedNfcUuid: scannedUuid)
                } else {
                    Logger.error("❌ NFC UUID不匹配")
                    self.isVerifying = false
                    self.showErrorMessage("NFC tag does not match. Please scan the correct tag.")
                }
                
                // 重置NFC管理器
                self.nfcManager.reset()
            }
        }
        
        nfcManager.onNFCError = { error in
            Logger.error("❌ NFC扫描失败: \(error)")
            
            DispatchQueue.main.async {
                self.isVerifying = false
                self.showErrorMessage("NFC scan failed: \(error)")
                self.nfcManager.reset()
            }
        }
    }
    
    private func completeTransfer(data: TransferQRData, scannedNfcUuid: String) {
        Task {
            do {
                let result = try await TransferManager.shared.completeTransfer(
                    transferCode: data.transferCode,
                    scannedNfcUuid: scannedNfcUuid,
                    toUser: username
                )
                
                await MainActor.run {
                    isVerifying = false
                    
                    if result.success {
                        Logger.success("Transfer completed successfully")
                        onTransferComplete()
                        onClose()
                    } else {
                        showErrorMessage(result.error ?? "Transfer failed")
                    }
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    showErrorMessage(error.localizedDescription)
                }
            }
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

