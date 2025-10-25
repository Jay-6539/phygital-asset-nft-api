//
//  OvalOfficeCheckInDetailView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Oval Office Check-in详情页
//

import SwiftUI

struct OvalOfficeCheckInDetailView: View {
    let checkIn: OvalOfficeCheckIn
    let appGreen: Color
    let onClose: () -> Void
    let onNavigateToOvalOffice: (() -> Void)? // 导航到Oval Office
    let currentUsername: String? // 当前用户名
    
    @State private var image: UIImage? = nil
    @State private var isLoadingImage = false
    @State private var showTransferView = false
    @State private var transferRequest: TransferRequest?
    @State private var isCreatingTransfer = false
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }
            
            // 详情卡片
            VStack(spacing: 0) {
                // 头部
                HStack {
                    Spacer()
                    
                    Text("Check-in Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 图片
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(maxHeight: 200)
                                .cornerRadius(12)
                        } else if isLoadingImage {
                            ZStack {
                                Rectangle()
                                    .fill(Color(.systemGray6))
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                
                                ProgressView()
                            }
                        }
                        
                        // Asset名称
                        if let assetName = checkIn.assetName, !assetName.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Asset Name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(assetName)
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        // 描述
                        if !checkIn.description.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Description")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(checkIn.description)
                                    .font(.body)
                            }
                        }
                        
                        // Grid坐标
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Grid Position")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Grid: (\(checkIn.gridX), \(checkIn.gridY))")
                                    .font(.body)
                            }
                            
                            Spacer()
                            
                            // GO!按钮 - 导航到Oval Office
                            if let onNavigateToOvalOffice = onNavigateToOvalOffice {
                                Button(action: {
                                    onNavigateToOvalOffice()
                                }) {
                                    Text("GO!")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(appGreen)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
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
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
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
                                        .shadow(color: appGreen.opacity(0.2), radius: 4, x: 0, y: 2)
                                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                                }
                            }
                        }
                        
                        // 时间
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Check-in Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(checkIn.createdAt, style: .date)
                                .font(.body)
                            Text(checkIn.createdAt, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // 用户名
                        VStack(alignment: .leading, spacing: 4) {
                            Text("User")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(checkIn.username)
                                .font(.body)
                        }
                        
                        // Transfer按钮 - 仅当是自己的记录时显示
                        if let username = currentUsername, username == checkIn.username {
                            Divider()
                                .padding(.vertical, 8)
                            
                            Button(action: {
                                startTransfer()
                            }) {
                                HStack(spacing: 12) {
                                    if isCreatingTransfer {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: appGreen))
                                    } else {
                                        Text("Transfer")
                                            .font(.headline)
                                            .foregroundColor(appGreen)
                                    }
                                }
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
                                .shadow(color: appGreen.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .disabled(isCreatingTransfer)
                        }
                    }
                    .padding(20)
                }
            }
            .frame(maxWidth: 400)
            .frame(maxHeight: 600)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            
            // 转让界面overlay
            if showTransferView, let request = transferRequest {
                TransferQRView(
                    transferRequest: request,
                    appGreen: appGreen,
                    onClose: {
                        showTransferView = false
                        transferRequest = nil
                    },
                    onCancel: {
                        showTransferView = false
                        transferRequest = nil
                        onClose()
                    }
                )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let imageUrl = checkIn.imageUrl else { return }
        guard !imageUrl.isEmpty else { return }
        
        isLoadingImage = true
        Task {
            do {
                if let loadedImage = try await OvalOfficeCheckInManager.shared.downloadImage(from: imageUrl) {
                    await MainActor.run {
                        self.image = loadedImage
                        self.isLoadingImage = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingImage = false
                }
            }
        }
    }
    
    private func startTransfer() {
        guard let username = currentUsername else {
            Logger.error("Cannot transfer: no current username")
            return
        }
        
        isCreatingTransfer = true
        
        Task {
            do {
                let request = try await TransferManager.shared.createOvalOfficeTransfer(
                    checkIn: checkIn,
                    fromUser: username
                )
                
                await MainActor.run {
                    self.transferRequest = request
                    self.isCreatingTransfer = false
                    self.showTransferView = true
                }
            } catch {
                Logger.error("Failed to create transfer: \(error.localizedDescription)")
                await MainActor.run {
                    self.isCreatingTransfer = false
                }
            }
        }
    }
}

