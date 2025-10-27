//
//  MarketView.swift
//  Phygital Asset
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
    let onBidCountUpdate: ((Int) -> Void)? // Bid计数更新回调
    
    @State private var selectedTab: MarketTab = .trending
    @State private var marketStats = MarketStats()
    @State private var trendingBuildings: [BuildingWithStats] = []
    @State private var mostTradedRecords: [CheckInWithTransferStats] = []
    @State private var topUsers: [UserStats] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedBuilding: BuildingWithStats? // 选中的建筑，显示历史记录
    @State private var selectedTradedRecord: CheckInWithTransferStats? // 选中的交易记录
    @State private var showBidList = false
    @State private var unreadBidCount = 0
    @State private var userEcho = 0
    @State private var frozenEcho = 0
    @State private var userXP = 0
    @State private var userLevel = 1
    @State private var xpProgress: Float = 0.0
    @State private var currentLevelXP = 0
    @State private var xpForNextLevel = 1000
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 顶部导航栏
            ZStack {
                // 左侧：返回按钮
                HStack {
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
                }
                
                // 中间：标题（绝对居中）
                Text("Echo Market")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // 右侧：功能按钮
                HStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Bid通知按钮
                        if currentUsername != nil {
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
                                await loadUserEcho() // 刷新Echo
                                await loadUserXP() // 刷新XP
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
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
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
            HStack(spacing: 12) {
                // 左侧：Echo和XP卡片（绿色边框）
                VStack(alignment: .leading, spacing: 8) {
                    // Echo行
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(appGreen)
                        
                        Text("\(userEcho - frozenEcho)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(appGreen)
                        
                        Text("Echo")
                            .font(.system(size: 11))
                            .foregroundColor(appGreen)
                        
                        // 冻结Echo提示（如果有）
                        if frozenEcho > 0 {
                            Spacer()
                            
                            HStack(spacing: 2) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 7))
                                    .foregroundColor(.orange)
                                
                                Text("\(frozenEcho)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    // XP行
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.purple)
                            
                            Text("Lv.\(userLevel)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.purple)
                            
                            Text("XP")
                                .font(.system(size: 11))
                                .foregroundColor(.purple)
                        }
                        
                        // XP进度条（缩短）
                        ZStack(alignment: .leading) {
                            // 背景
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 5)
                            
                            // 进度
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.7)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, CGFloat(xpProgress) * 90), height: 5)
                                .animation(.easeInOut(duration: 0.3), value: xpProgress)
                        }
                        .frame(width: 90)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(appGreen.opacity(0.3), lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(appGreen.opacity(0.05))
                        )
                )
                
                // 右侧：Tab按钮区域（横向排列，与左侧等高）
                HStack(spacing: 8) {
                    ForEach(MarketTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 4) {
                                // Tab图标
                                Image(systemName: tab.icon)
                                    .font(.system(size: 16, weight: selectedTab == tab ? .semibold : .regular))
                                    .foregroundColor(selectedTab == tab ? .white : appGreen)
                                
                                // Tab名称
                                Text(tab.rawValue)
                                    .font(.system(size: 9, weight: selectedTab == tab ? .semibold : .medium))
                                    .foregroundColor(selectedTab == tab ? .white : .primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 6)
                            .background(
                                ZStack {
                                    if selectedTab == tab {
                                        // 选中状态：实色渐变背景
                                        LinearGradient(
                                            gradient: Gradient(colors: [appGreen, appGreen.opacity(0.85)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    } else {
                                        // 未选中状态：白色背景
                                        Color.white
                                    }
                                }
                            )
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        selectedTab == tab ? appGreen : Color.gray.opacity(0.3),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(
                                color: selectedTab == tab ? appGreen.opacity(0.4) : .clear,
                                radius: selectedTab == tab ? 6 : 0,
                                x: 0,
                                y: selectedTab == tab ? 3 : 0
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(appGreen.opacity(0.3), lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                        )
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
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
                                selectedTradedRecord = record
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
                await loadUserEcho() // 在loadMarketData后调用，确保topUsers已加载
                await loadUserXP() // 加载XP数据
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
        // Traded Record Detail overlay
        .overlay {
            if let record = selectedTradedRecord {
                TradedRecordDetailView(
                    record: record,
                    appGreen: appGreen,
                    currentUsername: currentUsername,
                    onClose: { selectedTradedRecord = nil }
                )
                .transition(.opacity)
            }
        }
        // Bid Management overlay
        .fullScreenCover(isPresented: $showBidList) {
            if let username = currentUsername {
                BidManagementView(
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
    
    // MARK: - 加载用户Echo
    private func loadUserEcho() async {
        guard let username = currentUsername else {
            await MainActor.run {
                self.userEcho = 0
            }
            return
        }
        
        // Echo应该与Top Users的activity_score保持一致
        // 优先从topUsers中获取，如果找不到则从EchoManager
        if let userStats = topUsers.first(where: { $0.username == username }) {
            let frozen = EchoManager.shared.getFrozenEcho(for: username)
            
            await MainActor.run {
                self.userEcho = userStats.activityScore
                self.frozenEcho = frozen
                // 同步到EchoManager
                EchoManager.shared.setEcho(userStats.activityScore, for: username)
            }
            Logger.debug("💰 User credits synced from activity_score: \(userStats.activityScore) for @\(username)")
            Logger.debug("🧊 Frozen credits: \(frozen), Available: \(userStats.activityScore - frozen)")
        } else {
            // Fallback: 从EchoManager获取
            let credits = EchoManager.shared.getEcho(for: username)
            let frozen = EchoManager.shared.getFrozenEcho(for: username)
            
            await MainActor.run {
                self.userEcho = credits
                self.frozenEcho = frozen
            }
            Logger.debug("💰 User credits loaded from EchoManager: \(credits) for @\(username)")
            Logger.debug("🧊 Frozen credits: \(frozen), Available: \(credits - frozen)")
        }
    }
    
    // MARK: - 加载用户XP
    private func loadUserXP() async {
        guard let username = currentUsername else {
            await MainActor.run {
                self.userXP = 0
                self.userLevel = 1
                self.xpProgress = 0.0
                self.currentLevelXP = 0
                self.xpForNextLevel = 1000
            }
            return
        }
        
        // 从XPManager获取XP和等级信息
        let xp = XPManager.shared.getXP(for: username)
        let levelProgress = XPManager.shared.getLevelProgress(for: username)
        
        await MainActor.run {
            self.userXP = xp
            self.userLevel = levelProgress.currentLevel
            self.currentLevelXP = levelProgress.currentXP
            self.xpForNextLevel = levelProgress.xpForNextLevel
            self.xpProgress = levelProgress.progressPercentage
        }
        
        Logger.debug("⭐ User XP loaded: \(xp) XP, Level \(levelProgress.currentLevel) (\(levelProgress.currentXP)/\(levelProgress.xpForNextLevel)) for @\(username)")
    }
    
    // MARK: - 加载未读Bid数量
    private func loadUnreadBidCount() async {
        guard let username = currentUsername else {
            await MainActor.run {
                self.unreadBidCount = 0
                onBidCountUpdate?(0)
            }
            return
        }
        
        do {
            // 计算卖家收到的pending Bid
            let receivedCount = try await BidManager.shared.getUnreadBidCount(ownerUsername: username)
            
            // 计算买家收到的accepted/countered Bid
            let sentBids = try await BidManager.shared.getSentBids(bidderUsername: username)
            let sentUnreadCount = sentBids.filter { $0.status == .countered || $0.status == .accepted }.count
            
            // 总未读数 = 收到的pending + 发出的countered/accepted
            let totalCount = receivedCount + sentUnreadCount
            
            await MainActor.run {
                self.unreadBidCount = totalCount
                onBidCountUpdate?(totalCount)
            }
            Logger.debug("🔔 Total unread bid count: \(totalCount) (received: \(receivedCount), sent: \(sentUnreadCount))")
        } catch {
            Logger.error("❌ Failed to load unread bid count: \(error.localizedDescription)")
            await MainActor.run {
                self.unreadBidCount = 0
                onBidCountUpdate?(0)
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
    var compact: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if compact {
                // 紧凑模式：只显示图标
                VStack(spacing: 2) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? appGreen : .gray)
                    
                    Text(tab.rawValue)
                        .font(.system(size: 9))
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? appGreen : .gray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    isSelected ? appGreen.opacity(0.15) : Color.clear
                )
                .cornerRadius(8)
            } else {
                // 正常模式
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
}

#Preview {
    MarketView(
        appGreen: .green,
        treasures: [],
        onClose: {},
        onNavigateToBuilding: nil,
        currentUsername: "testuser",
        onBidCountUpdate: nil
    )
}

