//
//  AssetInfoModalView.swift
//  Phygital Asset
//
//  Created by refactoring on 21/10/2025.
//

import SwiftUI

/// 资产信息框视图
/// 显示Asset的历史记录和用户互动
struct AssetInfoModalView: View {
    @ObservedObject var viewModel: OvalOfficeViewModel
    @Binding var currentInteractionIndex: Int
    @Binding var selectedUserInteraction: UserInteraction?
    @Binding var showUserDetailModal: Bool
    @ObservedObject var nfcManager: NFCManager
    let appGreen: Color
    let username: String
    
    // 云端 Check-ins 状态
    @State private var cloudCheckIns: [OvalOfficeCheckIn] = []
    @State private var isLoadingCheckIns: Bool = false
    @State private var checkInsLoadError: String? = nil
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showAssetInfoModal = false
                }
            
            // 信息框
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text("Asset's History")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 关闭按钮
                    Button(action: {
                        viewModel.showAssetInfoModal = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Asset基本信息（包含Asset名称和GPS坐标）
                if let asset = viewModel.selectedAssetInfo,
                   let index = viewModel.officeAssets.firstIndex(where: { $0.coordinate.x == asset.coordinate.x && $0.coordinate.y == asset.coordinate.y }) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Asset名称
                        if !viewModel.officeAssets[index].name.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text(viewModel.officeAssets[index].name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        // GPS坐标
                        if viewModel.officeAssets[index].hasGPSCoordinates {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text("GPS: \(viewModel.officeAssets[index].gpsCoordinatesString)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "location.slash")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("GPS: Not available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                
                // 历史记录标题
                Text("Thread History")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                
                // 用户互动列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if isLoadingCheckIns {
                            // 加载中
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Loading threads...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if let error = checkInsLoadError {
                            // 加载失败
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.orange.opacity(0.5))
                                Text("Failed to load threads")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button("Retry") {
                                    loadCheckInsFromCloud()
                                }
                                .foregroundColor(appGreen)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if cloudCheckIns.isEmpty {
                            // 没有历史记录
                            VStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No thread history yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Be the first to create a thread!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            // 显示云端历史记录
                            ForEach(Array(cloudCheckIns.enumerated()), id: \.element.id) { index, checkIn in
                                CloudCheckInRow(
                                    checkIn: checkIn,
                                    onTap: {
                                        // TODO: 显示详细信息
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)
                .onAppear {
                    loadCheckInsFromCloud()
                }
                
                // Check in mine! 按钮
                Button(action: {
                    // 关闭历史信息框
                    viewModel.showAssetInfoModal = false
                    
                    // 设置当前资产为选中状态
                    if let asset = viewModel.selectedAssetInfo {
                        // 找到资产在数组中的索引
                        if let index = viewModel.officeAssets.firstIndex(where: { $0.coordinate.x == asset.coordinate.x && $0.coordinate.y == asset.coordinate.y }) {
                            viewModel.selectedAssetIndex = index
                            
                            // 检查Asset是否有NFC UUID
                            let assetNFCUUID = viewModel.officeAssets[index].nfcUUID
                            
                            if assetNFCUUID.isEmpty {
                                Logger.warning("Asset has no NFC UUID, cannot create thread")
                                // 可以显示一个提示，或者允许无NFC check-in
                                // 这里直接显示输入框（向后兼容没有NFC的Asset）
                                viewModel.assetName = ""
                                viewModel.assetImage = nil
                                viewModel.assetDescription = ""
                                viewModel.isNewAsset = false
                                viewModel.showAssetInputModal = true
                            } else {
                                Logger.debug("Starting NFC thread creation first scan for Asset with UUID: \(assetNFCUUID)")
                                // 启动第一次NFC扫描验证
                                nfcManager.startCheckInFirstScan(expectedUUID: assetNFCUUID)
                            }
                        }
                    }
                }) {
                    Text("Create my thread!")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(appGreen)
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
                        .shadow(color: appGreen.opacity(0.2), radius: 8, x: 0, y: 4)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
            .frame(maxHeight: 700)
        }
    }
    
    // MARK: - Helper Methods
    
    /// 从云端加载 Check-ins
    private func loadCheckInsFromCloud() {
        guard let asset = viewModel.selectedAssetInfo else {
            return
        }
        
        isLoadingCheckIns = true
        checkInsLoadError = nil
        
        Task {
            do {
                let checkIns = try await OvalOfficeCheckInManager.shared.getCheckIns(
                    forGridX: asset.coordinate.x,
                    gridY: asset.coordinate.y
                )
                
                await MainActor.run {
                    self.cloudCheckIns = checkIns
                    self.isLoadingCheckIns = false
                    Logger.success("✅ Loaded \(checkIns.count) threads from cloud")
                }
            } catch {
                await MainActor.run {
                    self.checkInsLoadError = error.localizedDescription
                    self.isLoadingCheckIns = false
                    Logger.error("❌ Failed to load threads: \(error.localizedDescription)")
                }
            }
        }
    }
}

/// 云端 Check-in 行视图
struct CloudCheckInRow: View {
    let checkIn: OvalOfficeCheckIn
    let onTap: () -> Void
    
    @State private var image: UIImage? = nil
    @State private var isLoadingImage: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 用户名和时间
                HStack {
                    Text(checkIn.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(checkIn.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Asset名称（粗体显示）
                if let assetName = checkIn.assetName, !assetName.isEmpty {
                    Text(assetName)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // 描述内容
                if !checkIn.description.isEmpty {
                    Text(checkIn.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                // 图片预览（如果有）
                if isLoadingImage {
                    HStack {
                        ProgressView()
                            .frame(height: 80)
                        Spacer()
                    }
                } else if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 80)
                        .clipped()
                        .cornerRadius(8)
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadImageIfNeeded()
        }
    }
    
    private func loadImageIfNeeded() {
        guard let imageUrl = checkIn.imageUrl, !imageUrl.isEmpty, image == nil else {
            return
        }
        
        isLoadingImage = true
        
        Task {
            do {
                let loadedImage = try await OvalOfficeCheckInManager.shared.downloadImage(from: imageUrl)
                await MainActor.run {
                    self.image = loadedImage
                    self.isLoadingImage = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingImage = false
                }
                Logger.error("Failed to load image: \(error.localizedDescription)")
            }
        }
    }
}

/// 用户互动行视图（保留用于向后兼容）
struct UserInteractionRow: View {
    let interaction: UserInteraction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 用户名和时间
                HStack {
                    Text(interaction.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(interaction.interactionTime, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Asset名称（粗体显示）
                if !interaction.assetName.isEmpty {
                    Text(interaction.assetName)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // 描述内容
                if !interaction.description.isEmpty {
                    Text(interaction.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                // 图片预览（如果有）
                if let image = interaction.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 80)
                        .clipped()
                        .cornerRadius(8)
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 用户详细信息框
struct UserDetailModalView: View {
    @ObservedObject var viewModel: OvalOfficeViewModel
    @Binding var showUserDetailModal: Bool
    @Binding var currentInteractionIndex: Int
    @Binding var selectedUserInteraction: UserInteraction?
    let appGreen: Color
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showUserDetailModal = false
                }
            
            // 详细信息框
            VStack(spacing: 0) {
                // 标题栏
                VStack(spacing: 8) {
                    HStack {
                        Text("Thread Details")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 关闭按钮
                        Button(action: {
                            showUserDetailModal = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundColor(.gray)
                                .frame(width: 44, height: 44)
                        }
                    }
                    
                    // 导航按钮 - 在当前Asset的历史记录中前后翻页
                    if let asset = viewModel.selectedAssetInfo,
                       let assetIndex = viewModel.officeAssets.firstIndex(where: { $0.coordinate.x == asset.coordinate.x && $0.coordinate.y == asset.coordinate.y }) {
                        let interactions = viewModel.officeAssets[assetIndex].userInteractions.reversed()
                        let totalCount = interactions.count
                        
                        if totalCount > 1 {
                            HStack {
                                Spacer()
                                
                                // 上一个按钮
                                Button(action: {
                                    if currentInteractionIndex > 0 {
                                        currentInteractionIndex -= 1
                                        selectedUserInteraction = Array(interactions)[currentInteractionIndex]
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.title3)
                                        .foregroundColor(currentInteractionIndex > 0 ? .primary : .gray)
                                        .frame(width: 30, height: 30)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(15)
                                }
                                .disabled(currentInteractionIndex <= 0)
                                
                                // 页数指示
                                Text("\(currentInteractionIndex + 1) / \(totalCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                
                                // 下一个按钮
                                Button(action: {
                                    if currentInteractionIndex < totalCount - 1 {
                                        currentInteractionIndex += 1
                                        selectedUserInteraction = Array(interactions)[currentInteractionIndex]
                                    }
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.title3)
                                        .foregroundColor(currentInteractionIndex < totalCount - 1 ? .primary : .gray)
                                        .frame(width: 30, height: 30)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(15)
                                }
                                .disabled(currentInteractionIndex >= totalCount - 1)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // 用户详细信息
                if let interaction = selectedUserInteraction {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // 用户名和时间
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                Text(interaction.username)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            // 互动时间
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Interaction Time")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                Text(interaction.interactionTime, style: .date)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            // Asset名称
                            if !interaction.assetName.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Asset Name")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    
                                    Text(interaction.assetName)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(appGreen)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            
                            // 图片（如果有）
                            if let image = interaction.image {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Photo")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 300)
                                        .cornerRadius(12)
                                }
                            }
                            
                            // 描述内容
                            if !interaction.description.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    
                                    Text(interaction.description)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
            .frame(maxHeight: 600)
        }
    }
}

