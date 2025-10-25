//
//  MostTradedView.swift
//  Treasure Hunt, Hong Kong Park
//
//  交易最多的记录列表
//

import SwiftUI

struct MostTradedView: View {
    let records: [CheckInWithTransferStats]
    let appGreen: Color
    let onRecordTap: (CheckInWithTransferStats) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if records.isEmpty {
                    // 空状态
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.left.arrow.right.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No traded records yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Transfer your assets to see them here!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(records) { record in
                        MostTradedCard(
                            record: record,
                            appGreen: appGreen
                        )
                        .onTapGesture {
                            onRecordTap(record)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

struct MostTradedCard: View {
    let record: CheckInWithTransferStats
    let appGreen: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 图片（如果有）
            if let imageUrl = record.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 140)
                            .clipped()
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 140)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 140)
                            .overlay(
                                ProgressView()
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .cornerRadius(8)
            } else {
                // 无图片时显示占位符
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                appGreen.opacity(0.1),
                                appGreen.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 140)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 40))
                            .foregroundColor(appGreen.opacity(0.3))
                    )
                    .cornerRadius(8)
            }
            
            // 建筑信息和统计
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(record.buildingName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // 转账次数徽章
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.caption2)
                            .foregroundColor(.white)
                        
                        Text("\(record.transferCount) transfers")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(appGreen)
                    .cornerRadius(6)
                }
                
                Spacer()
                
                // 当前拥有者
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Owner")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("@\(record.ownerUsername)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(appGreen)
                        .lineLimit(1)
                }
            }
            
            // 备注（如果有）
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    MostTradedView(
        records: [
            CheckInWithTransferStats(
                id: "1",
                buildingId: "100",
                buildingName: "Victoria Peak Tower",
                imageUrl: nil,
                ownerUsername: "alice_hk",
                transferCount: 15,
                createdAt: Date(),
                notes: "Beautiful view from the top!"
            ),
            CheckInWithTransferStats(
                id: "2",
                buildingId: "101",
                buildingName: "Star Ferry Pier",
                imageUrl: nil,
                ownerUsername: "bob_traveler",
                transferCount: 12,
                createdAt: Date(),
                notes: "Historic ferry terminal"
            )
        ],
        appGreen: .green,
        onRecordTap: { _ in }
    )
}

