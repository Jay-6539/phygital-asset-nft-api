//
//  TransferQRView.swift
//  Treasure Hunt, Hong Kong Park
//
//  转让QR码显示界面
//

import SwiftUI

struct TransferQRView: View {
    let transferRequest: TransferRequest
    let appGreen: Color
    let onClose: () -> Void
    let onCancel: () -> Void
    
    @State private var qrCodeImage: UIImage?
    @State private var transferStatus: TransferRequest.TransferStatus = .pending
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if transferStatus != .pending {
                        onClose()
                    }
                }
            
            // 主内容卡片
            VStack(spacing: 0) {
                // 顶部栏
                HStack {
                    Spacer()
                    
                    Text("Transfer")
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
                    .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: 24) {
                        if transferStatus == .pending {
                            // 待转让状态
                            pendingTransferView
                        } else if transferStatus == .completed {
                            // 转让完成
                            completedTransferView
                        } else if transferStatus == .expired {
                            // 转让过期
                            expiredTransferView
                        } else if transferStatus == .cancelled {
                            // 已取消
                            cancelledTransferView
                        }
                    }
                    .padding(24)
                }
            }
            .frame(maxWidth: 400, maxHeight: 650)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .onAppear {
            generateQRCode()
            startMonitoring()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - 待转让视图
    
    private var pendingTransferView: some View {
        VStack(spacing: 20) {
            // 记录信息
            VStack(alignment: .leading, spacing: 8) {
                Text("Transferring")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(transferRequest.buildingName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(transferRequest.assetName)
                    .font(.headline)
                    .foregroundColor(appGreen)
                
                if !transferRequest.description.isEmpty {
                    Text(transferRequest.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // QR码
            if let qrCode = qrCodeImage {
                VStack(spacing: 12) {
                    Image(uiImage: qrCode)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                    
                    Text("Scan to receive")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Receiver must scan NFC at location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                ProgressView()
                    .frame(height: 250)
            }
            
            // 倒计时
            if timeRemaining > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(appGreen)
                    Text("Expires in \(formatTime(timeRemaining))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // 取消按钮
            Button(action: {
                Task {
                    await cancelTransfer()
                }
            }) {
                Text("Cancel Transfer")
                    .font(.headline)
                    .foregroundColor(appGreen)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(appGreen, lineWidth: 2)
                    )
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 完成视图
    
    private var completedTransferView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Transfer Completed!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("The record has been successfully transferred")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let toUser = transferRequest.toUser {
                Text("Transferred to: \(toUser)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button(action: onClose) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(appGreen)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 过期视图
    
    private var expiredTransferView: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("Transfer Expired")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This transfer request has expired. You can create a new one.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onClose) {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 取消视图
    
    private var cancelledTransferView: some View {
        VStack(spacing: 24) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("Transfer Cancelled")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This transfer has been cancelled")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onClose) {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func generateQRCode() {
        let qrData = TransferQRData(
            transferCode: transferRequest.transferCode,
            nfcUuid: transferRequest.nfcUuid,
            buildingName: transferRequest.buildingName,
            assetName: transferRequest.assetName,
            fromUser: transferRequest.fromUser,
            expiresAt: transferRequest.expiresAt
        )
        
        qrCodeImage = QRCodeGenerator.shared.generateTransferQRCode(from: qrData)
    }
    
    private func startMonitoring() {
        updateTimeRemaining()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimeRemaining()
            
            // 检查是否过期
            if timeRemaining <= 0 {
                transferStatus = .expired
                timer?.invalidate()
            }
        }
    }
    
    private func updateTimeRemaining() {
        timeRemaining = max(0, transferRequest.expiresAt.timeIntervalSince(Date()))
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    private func cancelTransfer() async {
        do {
            try await TransferManager.shared.cancelTransfer(transferCode: transferRequest.transferCode)
            await MainActor.run {
                transferStatus = .cancelled
                onCancel()
            }
        } catch {
            Logger.error("Failed to cancel transfer: \(error.localizedDescription)")
        }
    }
}

