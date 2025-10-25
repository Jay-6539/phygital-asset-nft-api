//
//  TradedRecordDetailView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Most Traded记录详情界面（样式参考CheckInDetailView）
//

import SwiftUI

struct TradedRecordDetailView: View {
    let record: CheckInWithTransferStats
    let appGreen: Color
    let currentUsername: String?
    let onClose: () -> Void
    
    @State private var showBidInput = false
    
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
                // 头部 - 与CheckInDetailView一致
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
                        if let imageUrl = record.imageUrl, !imageUrl.isEmpty {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .frame(maxHeight: 200)
                                        .cornerRadius(12)
                                case .failure(_), .empty:
                                    ZStack {
                                        Rectangle()
                                            .fill(Color(.systemGray6))
                                            .frame(height: 200)
                                            .cornerRadius(12)
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                    }
                                @unknown default:
                                    ProgressView()
                                        .frame(height: 200)
                                }
                            }
                        }
                        
                        // Asset名称
                        if let assetName = record.assetName, !assetName.isEmpty {
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
                        if let notes = record.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Description")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(notes)
                                    .font(.body)
                            }
                        }
                        
                        // 建筑位置
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Building")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(record.buildingName)
                                .font(.body)
                        }
                        
                        // 转账统计
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.caption)
                                .foregroundColor(appGreen)
                            Text("\(record.transferCount) transfers")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Bid按钮（只在非拥有者时显示）
                        if let username = currentUsername, username != record.ownerUsername {
                            Button(action: {
                                Logger.debug("🎯 Bid button tapped")
                                showBidInput = true
                            }) {
                                Text("Bid")
                                    .font(.headline)
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
                                    .shadow(color: appGreen.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .frame(maxWidth: 550)
            .frame(maxHeight: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 30)
            .padding(.vertical, 50)
            
            // Bid Input界面
            if showBidInput {
                BidInputView(
                    recordId: UUID(uuidString: record.id) ?? UUID(),
                    recordType: "building",
                    buildingId: record.buildingId,
                    ownerUsername: record.ownerUsername,
                    recordDescription: record.notes ?? record.buildingName,
                    currentUsername: currentUsername ?? "Unknown",
                    appGreen: appGreen,
                    onClose: {
                        showBidInput = false
                    },
                    onSuccess: {
                        showBidInput = false
                        onClose() // 成功后关闭详情页
                    }
                )
            }
        }
    }
}

#Preview {
    TradedRecordDetailView(
        record: CheckInWithTransferStats(
            id: "1",
            buildingId: "100",
            buildingName: "Victoria Peak Tower",
            assetName: "Peak View Collection",
            imageUrl: nil,
            ownerUsername: "alice_hk",
            transferCount: 15,
            createdAt: Date(),
            notes: "Beautiful view from the top!"
        ),
        appGreen: .green,
        currentUsername: "bob_user",
        onClose: {}
    )
}

