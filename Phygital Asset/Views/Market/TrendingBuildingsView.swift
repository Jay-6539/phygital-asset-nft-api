//
//  TrendingBuildingsView.swift
//  Phygital Asset
//
//  热门建筑列表视图
//

import SwiftUI

struct TrendingBuildingsView: View {
    let buildings: [BuildingWithStats]
    let appGreen: Color
    let onBuildingTap: (BuildingWithStats) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if buildings.isEmpty {
                    // 空状态
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(appGreen.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "building.2")
                                .font(.system(size: 48))
                                .foregroundColor(appGreen.opacity(0.6))
                        }
                        
                        VStack(spacing: 8) {
                            Text("No Buildings Yet")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Be the first to explore and create threads\nat historic buildings!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    ForEach(buildings) { building in
                        TrendingBuildingCard(
                            building: building,
                            appGreen: appGreen
                        )
                        .onTapGesture {
                            onBuildingTap(building)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

struct TrendingBuildingCard: View {
    let building: BuildingWithStats
    let appGreen: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // 排名徽章
            ZStack {
                Circle()
                    .fill(rankColor)
                
                if building.rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(building.rank)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(building.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // 记录数量
                    Label("\(building.recordCount)", systemImage: "doc.text.fill")
                        .font(.caption2)
                        .foregroundColor(appGreen)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                        .font(.caption2)
                    
                    // 最后活动时间
                    Text(timeAgo(building.lastActivityTime))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    var rankColor: Color {
        switch building.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // 铜色
        default: return appGreen.opacity(0.6)
        }
    }
    
    var rankIcon: String {
        switch building.rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "star.fill"
        default: return ""
        }
    }
    
    func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        
        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        }
    }
}

#Preview {
    TrendingBuildingsView(
        buildings: [
            BuildingWithStats(
                id: "1",
                name: "Victoria Peak",
                district: "Central",
                coordinate: .init(latitude: 22.27, longitude: 114.15),
                recordCount: 125,
                lastActivityTime: Date().addingTimeInterval(-3600),
                rank: 1
            ),
            BuildingWithStats(
                id: "2",
                name: "Star Ferry",
                district: "Tsim Sha Tsui",
                coordinate: .init(latitude: 22.28, longitude: 114.16),
                recordCount: 98,
                lastActivityTime: Date().addingTimeInterval(-7200),
                rank: 2
            )
        ],
        appGreen: .green,
        onBuildingTap: { _ in }
    )
}

