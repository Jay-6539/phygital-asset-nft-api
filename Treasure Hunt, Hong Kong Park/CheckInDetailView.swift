//
//  CheckInDetailView.swift
//  Treasure Hunt, Hong Kong Park
//
//  建筑Check-in详情页
//

import SwiftUI

struct CheckInDetailView: View {
    let checkIn: BuildingCheckIn
    let appGreen: Color
    let onClose: () -> Void
    let onNavigate: ((Double, Double) -> Void)? // 新增：导航回调
    
    @State private var image: UIImage? = nil
    @State private var isLoadingImage = false
    
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
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(4)
                            .background(Color.gray.opacity(0.1), in: Circle())
                    }
                    
                    Spacer()
                    
                    Text("Check-in Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // 占位符
                    Image(systemName: "xmark")
                        .font(.caption)
                        .padding(4)
                        .opacity(0)
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
                        
                        // GPS位置
                        if let lat = checkIn.gpsLatitude, let lon = checkIn.gpsLongitude {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Location")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Lat: \(String(format: "%.6f", lat)), Lon: \(String(format: "%.6f", lon))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // GO!按钮
                                if let onNavigate = onNavigate {
                                    Button(action: {
                                        onNavigate(lat, lon)
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
                    }
                    .padding(20)
                }
            }
            .frame(maxWidth: 400)
            .frame(maxHeight: 600)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let imageUrl = checkIn.imageUrl, !imageUrl.isEmpty else { return }
        
        isLoadingImage = true
        Task {
            do {
                if let loadedImage = try await BuildingCheckInManager.shared.downloadImage(from: imageUrl) {
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
}


