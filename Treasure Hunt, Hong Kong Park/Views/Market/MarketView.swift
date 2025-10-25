//
//  MarketView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Market主页面 - 展示热门建筑、交易记录和活跃用户
//

import SwiftUI

struct MarketView: View {
    let appGreen: Color
    let treasures: [Treasure] // 所有建筑列表，用于匹配名称
    let onClose: () -> Void
    let onNavigateToBuilding: ((String) -> Void)? // 导航到建筑
    let currentUsername: String? // 当前用户名
    
    @State private var selectedTab: MarketTab = .trending
    @State private var marketStats = MarketStats()
    @State private var trendingBuildings: [BuildingWithStats] = []
    @State private var mostTradedRecords: [CheckInWithTransferStats] = []
    @State private var topUsers: [UserStats] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedBuilding: BuildingWithStats? // 选中的建筑，显示历史记录
    @State private var showBidList = false
    @State private var unreadBidCount = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 顶部导航栏
            HStack {
                // 返回按钮
                Button(action: onClose) {
                    ZStack {
                        Circle().fill(Color.white)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    .frame(width: 36, height: 36)
                    .shadow(radius: 2)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Market")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // 调试信息
                    Text("B:\(trendingBuildings.count) U:\(topUsers.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Bid通知按钮
                    if let username = currentUsername {
                        BidNotificationButton(
                            unreadCount: unreadBidCount,
                            appGreen: appGreen,
                            action: {
                                Logger.debug("🔔 Bid notification tapped")
                                showBidList = true
                            }
                        )
                    }
                    
                    // 刷新按钮
                    Button(action: {
                        Logger.debug("🔄 Manual refresh triggered")
                        Task {
                            await loadMarketData()
                            await loadUnreadBidCount()
                        }
                    }) {
                        ZStack {
                            Circle().fill(Color.white)
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16))
                                .foregroundStyle(isLoading ? .gray : appGreen)
                        }
                        .frame(width: 36, height: 36)
                        .shadow(radius: 2)
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                    }
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            
            Divider()
            
            // MARK: - 统计卡片区
            if isLoading && marketStats.totalBuildings == 0 {
                HStack(spacing: 12) {
                    StatCardSkeleton()
                    StatCardSkeleton()
                    StatCardSkeleton()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            } else {
                MarketStatsView(stats: marketStats, appGreen: appGreen)
            }
            
            Divider()
            
            // MARK: - Tab切换区
            HStack(spacing: 0) {
                ForEach(MarketTab.allCases, id: \.self) { tab in
                    MarketTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        appGreen: appGreen
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            Divider()
            
            // MARK: - 内容区域
            if isLoading {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { _ in
                            if selectedTab == .topUsers {
                                UserRowSkeleton()
                            } else {
                                BuildingCardSkeleton()
                            }
                        }
                    }
                    .padding(16)
                }
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red.opacity(0.6))
                    
                    Text("Failed to load data")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Retry") {
                        Task {
                            await loadMarketData()
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(appGreen)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 根据选中的tab显示不同内容
                Group {
                    switch selectedTab {
                    case .trending:
                        TrendingBuildingsView(
                            buildings: trendingBuildings,
                            appGreen: appGreen,
                            onBuildingTap: { building in
                                Logger.debug("Tapped building: \(building.name)")
                                selectedBuilding = building
                            }
                        )
                        
                    case .mostTraded:
                        MostTradedView(
                            records: mostTradedRecords,
                            appGreen: appGreen,
                            onRecordTap: { record in
                                Logger.debug("Tapped record: \(record.id)")
                                // TODO: 显示记录详情
                            }
                        )
                        
                    case .topUsers:
                        TopUsersView(
                            users: topUsers,
                            appGreen: appGreen,
                            onUserTap: { user in
                                Logger.debug("Tapped user: @\(user.username)")
                                // TODO: 显示用户详情
                            }
                        )
                    }
                }
                .transition(.opacity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            Task {
                await loadMarketData()
                await loadUnreadBidCount()
            }
        }
        // Building History overlay
        .overlay {
            if let building = selectedBuilding {
                BuildingHistoryView(
                    building: building,
                    appGreen: appGreen,
                    onClose: { selectedBuilding = nil },
                    currentUsername: currentUsername
                )
                .transition(.move(edge: .trailing))
            }
        }
        // Bid List overlay
        .fullScreenCover(isPresented: $showBidList) {
            if let username = currentUsername {
                BidListView(
                    appGreen: appGreen,
                    currentUsername: username,
                    onClose: {
                        showBidList = false
                        // 刷新未读计数
                        Task {
                            await loadUnreadBidCount()
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - 加载未读Bid数量
    private func loadUnreadBidCount() async {
        guard let username = currentUsername else {
            await MainActor.run {
                self.unreadBidCount = 0
            }
            return
        }
        
        do {
            let count = try await BidManager.shared.getUnreadBidCount(ownerUsername: username)
            await MainActor.run {
                self.unreadBidCount = count
            }
            Logger.debug("🔔 Unread bid count: \(count)")
        } catch {
            Logger.error("❌ Failed to load unread bid count: \(error.localizedDescription)")
            await MainActor.run {
                self.unreadBidCount = 0
            }
        }
    }
    
    // MARK: - 加载Market数据
    private func loadMarketData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 并行加载所有数据
            async let statsTask = MarketDataManager.shared.fetchMarketStats()
            async let buildingsTask = MarketDataManager.shared.fetchTrendingBuildings(limit: 20)
            async let usersTask = MarketDataManager.shared.fetchTopUsers(limit: 20)
            async let tradedTask = MarketDataManager.shared.fetchMostTradedRecords(limit: 20)
            
            let (stats, buildings, users, traded) = try await (statsTask, buildingsTask, usersTask, tradedTask)
            
            // 匹配真实建筑名称
            var enrichedBuildings = buildings
            for (index, building) in enrichedBuildings.enumerated() {
                if let treasure = treasures.first(where: { $0.id == building.id }) {
                    enrichedBuildings[index] = BuildingWithStats(
                        id: building.id,
                        name: treasure.name,
                        district: treasure.district,
                        coordinate: treasure.coordinate,
                        recordCount: building.recordCount,
                        lastActivityTime: building.lastActivityTime,
                        rank: building.rank
                    )
                }
            }
            
            await MainActor.run {
                self.marketStats = stats
                self.trendingBuildings = enrichedBuildings
                self.topUsers = users
                self.mostTradedRecords = traded
                self.isLoading = false
            }
            
            Logger.success("✅ Market data loaded: \(stats.totalBuildings) buildings, \(enrichedBuildings.count) trending, \(users.count) users, \(traded.count) traded")
            
        } catch {
            Logger.error("❌ Failed to load market data: \(error.localizedDescription)")
            
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Tab按钮组件
struct MarketTabButton: View {
    let tab: MarketTab
    let isSelected: Bool
    let appGreen: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? appGreen : .gray)
                
                Text(tab.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? appGreen : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected ? appGreen.opacity(0.1) : Color.clear
            )
            .cornerRadius(8)
        }
    }
}

#Preview {
    MarketView(
        appGreen: .green,
        treasures: [],
        onClose: {},
        onNavigateToBuilding: nil,
        currentUsername: "testuser"
    )
}

