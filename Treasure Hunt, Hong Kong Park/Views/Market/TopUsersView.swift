//
//  TopUsersView.swift
//  Treasure Hunt, Hong Kong Park
//
//  最活跃用户排行榜
//

import SwiftUI

struct TopUsersView: View {
    let users: [UserStats]
    let appGreen: Color
    let onUserTap: (UserStats) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if users.isEmpty {
                    // 空状态
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(appGreen.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "person.2")
                                .font(.system(size: 48))
                                .foregroundColor(appGreen.opacity(0.6))
                        }
                        
                        VStack(spacing: 8) {
                            Text("No Active Users")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Start your adventure and\nbecome the top explorer!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    ForEach(users) { user in
                        TopUserRow(
                            user: user,
                            appGreen: appGreen
                        )
                        .onTapGesture {
                            onUserTap(user)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

struct TopUserRow: View {
    let user: UserStats
    let appGreen: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // 排名徽章
            ZStack {
                Circle()
                    .fill(rankColor)
                    .shadow(color: rankColor.opacity(0.3), radius: 4, x: 0, y: 2)
                
                if user.rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(user.rank)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 36, height: 36)
            
            // 用户头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                appGreen.opacity(0.3),
                                appGreen.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Image(systemName: "person.fill")
                    .font(.system(size: 18))
                    .foregroundColor(appGreen)
            }
            .frame(width: 44, height: 44)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("@\(user.username)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    // 记录数
                    HStack(spacing: 2) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 10))
                        Text("\(user.totalRecords)")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    // 建筑数
                    HStack(spacing: 2) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 10))
                        Text("\(user.uniqueBuildings)")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    
                    if user.transferCount > 0 {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        // 转账数
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 10))
                            Text("\(user.transferCount)")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 活跃度分数
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(user.activityScore)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(appGreen)
                
                Text("credits")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    var rankColor: Color {
        switch user.rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0) // 金色
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // 银色
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // 铜色
        default: return appGreen.opacity(0.6)
        }
    }
    
    var rankIcon: String {
        switch user.rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "star.fill"
        default: return ""
        }
    }
}

#Preview {
    TopUsersView(
        users: [
            UserStats(
                username: "alice_explorer",
                totalRecords: 45,
                uniqueBuildings: 23,
                transferCount: 8,
                activityScore: 1600,
                rank: 1
            ),
            UserStats(
                username: "bob_collector",
                totalRecords: 38,
                uniqueBuildings: 19,
                transferCount: 12,
                activityScore: 1330,
                rank: 2
            )
        ],
        appGreen: .green,
        onUserTap: { _ in }
    )
}

