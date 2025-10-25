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
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(appGreen.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "arrow.left.arrow.right.circle")
                                .font(.system(size: 48))
                                .foregroundColor(appGreen.opacity(0.6))
                        }
                        
                        VStack(spacing: 8) {
                            Text("No Trades Yet")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Use the Sell button to transfer\nyour assets to other collectors!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
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
        HStack(spacing: 12) {
            // 左侧：资产信息和转账次数
            VStack(alignment: .leading, spacing: 6) {
                // Asset Name（如果有）
                if let assetName = record.assetName, !assetName.isEmpty {
                    Text(assetName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                // Building Name
                Text(record.buildingName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
            
            // 右侧：当前拥有者
            VStack(alignment: .trailing, spacing: 4) {
                Text("Owner")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("@\(record.ownerUsername)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(appGreen)
                    .lineLimit(1)
            }
        }
        .padding(16)
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
                assetName: "Peak View Collection",
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
                assetName: "Ferry Sunset Shot",
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

