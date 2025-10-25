//
//  TradedRecordDetailView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Most Traded记录详情界面
//

import SwiftUI

struct TradedRecordDetailView: View {
    let record: CheckInWithTransferStats
    let appGreen: Color
    let currentUsername: String?
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }
            
            VStack(spacing: 0) {
                // 顶部导航
                HStack {
                    Button(action: onClose) {
                        ZStack {
                            Circle().fill(Color(.systemGray6))
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(appGreen)
                        }
                        .frame(width: 32, height: 32)
                    }
                    
                    Spacer()
                    
                    Text("Asset Details")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Circle().fill(Color.clear).frame(width: 32, height: 32)
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // 内容区域
                ScrollView {
                    VStack(spacing: 20) {
                        // 图片
                        if let imageUrl = record.imageUrl, !imageUrl.isEmpty {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 200)
                                        .clipped()
                                case .failure(_), .empty:
                                    ZStack {
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(height: 200)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .cornerRadius(12)
                        }
                        
                        // Asset Name
                        if let assetName = record.assetName, !assetName.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Asset Name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Text(assetName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Building Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(appGreen)
                                
                                Text(record.buildingName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // 交易统计
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trade Statistics")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            HStack(spacing: 12) {
                                // 转账次数
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(record.transferCount)")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Text("Transfers")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .padding(16)
                                .background(appGreen)
                                .cornerRadius(12)
                                
                                Spacer()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // 当前拥有者
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Current Owner")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(appGreen)
                                
                                Text("@\(record.ownerUsername)")
                                    .font(.headline)
                                    .foregroundColor(appGreen)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // 备注
                        if let notes = record.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Description")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Bid按钮（如果不是自己的记录）
                        if let username = currentUsername, username != record.ownerUsername {
                            Button(action: {
                                // TODO: 打开Bid界面
                                Logger.debug("🎯 Bid button tapped for record: \(record.id)")
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .font(.system(size: 18))
                                    
                                    Text("Make an Offer")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(appGreen)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(16)
                }
                .background(Color(.systemGroupedBackground))
            }
            .frame(maxWidth: 500)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(40)
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

