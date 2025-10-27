//
//  MarketStatsView.swift
//  Phygital Asset
//
//  Market统计卡片组件
//

import SwiftUI

struct MarketStatsView: View {
    let stats: MarketStats
    let appGreen: Color
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Buildings",
                value: "\(stats.totalBuildings)",
                icon: "building.2",
                color: appGreen
            )
            
            StatCard(
                title: "Records",
                value: "\(stats.totalRecords)",
                icon: "doc.text",
                color: appGreen
            )
            
            StatCard(
                title: "Active Users",
                value: "\(stats.activeUsers)",
                icon: "person.2",
                color: appGreen
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 19))  // 16 * 1.2 ≈ 19
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)  // headline放大到title3
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 10))  // 9 * 1.2 ≈ 11, 微调为10
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)  // 8减少到6
        .padding(.horizontal, 4)  // 新增横向padding减小
        .background(.ultraThinMaterial)
        .cornerRadius(8)  // 10减少到8
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    MarketStatsView(
        stats: MarketStats(totalBuildings: 45, totalRecords: 523, activeUsers: 87),
        appGreen: Color.green
    )
}

