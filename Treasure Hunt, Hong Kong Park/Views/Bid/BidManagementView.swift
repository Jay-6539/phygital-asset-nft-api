//
//  BidManagementView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Bid管理主界面（包含Received和Sent两个Tab）
//

import SwiftUI

enum BidTab: String, CaseIterable {
    case received = "Bids Received"
    case offers = "My Offers"
    
    var icon: String {
        switch self {
        case .received: return "tray.fill"
        case .offers: return "paperplane.fill"
        }
    }
}

struct BidManagementView: View {
    let appGreen: Color
    let currentUsername: String
    let onClose: () -> Void
    
    @State private var selectedTab: BidTab = .received
    @State private var unreadReceivedCount: Int = 0
    @State private var unreadOffersCount: Int = 0
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - 顶部导航
                HStack {
                    Button(action: onClose) {
                        ZStack {
                            Circle().fill(Color(.systemGray6))
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 32, height: 32)
                    }
                    
                    Spacer()
                    
                    Text("Bids")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Circle().fill(Color.clear).frame(width: 32, height: 32)
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // MARK: - Tab切换
                HStack(spacing: 0) {
                    ForEach(BidTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 14))
                                    
                                    Text(tab.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    // 未读/未处理数量徽章
                                    if tab == .received && unreadReceivedCount > 0 {
                                        ZStack {
                                            Circle()
                                                .fill(appGreen.opacity(0.5))
                                                .frame(width: 18, height: 18)
                                            
                                            Text("\(unreadReceivedCount)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    } else if tab == .offers && unreadOffersCount > 0 {
                                        ZStack {
                                            Circle()
                                                .fill(appGreen.opacity(0.5))
                                                .frame(width: 18, height: 18)
                                            
                                            Text("\(unreadOffersCount)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .foregroundColor(selectedTab == tab ? appGreen : .secondary)
                                
                                Rectangle()
                                    .fill(selectedTab == tab ? appGreen : Color.clear)
                                    .frame(height: 3)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                    }
                }
                .background(Color(.systemBackground))
                
                Divider()
                
                // MARK: - 内容区域
                Group {
                    switch selectedTab {
                    case .received:
                        BidListViewContent(
                            appGreen: appGreen,
                            currentUsername: currentUsername,
                            onCountUpdate: { count in
                                unreadReceivedCount = count
                            }
                        )
                        
                    case .offers:
                        MyBidsViewContent(
                            appGreen: appGreen,
                            currentUsername: currentUsername,
                            onCountUpdate: { count in
                                unreadOffersCount = count
                            }
                        )
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Bids Received内容（从BidListView提取）
struct BidListViewContent: View {
    let appGreen: Color
    let currentUsername: String
    let onCountUpdate: ((Int) -> Void)?
    
    @State private var receivedBids: [Bid] = []
    @State private var isLoading = false
    @State private var selectedBid: Bid?
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            if isLoading && receivedBids.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading bids...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red.opacity(0.6))
                    
                    Text("Failed to load")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Retry") {
                        Task {
                            await loadBids()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(appGreen)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxHeight: .infinity)
            } else if receivedBids.isEmpty {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(appGreen.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(appGreen.opacity(0.6))
                    }
                    
                    VStack(spacing: 8) {
                        Text("No Bids Yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("When someone makes an offer\non your assets, it will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(receivedBids) { bid in
                            BidRow(bid: bid, appGreen: appGreen)
                                .onTapGesture {
                                    selectedBid = bid
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            Task {
                await loadBids()
            }
        }
        .overlay {
            if let bid = selectedBid {
                BidDetailView(
                    bid: bid,
                    appGreen: appGreen,
                    currentUsername: currentUsername,
                    onClose: {
                        selectedBid = nil
                    },
                    onActionCompleted: {
                        selectedBid = nil
                        Task {
                            await loadBids()
                        }
                    }
                )
            }
        }
    }
    
    private func loadBids() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let bids = try await BidManager.shared.getReceivedBids(ownerUsername: currentUsername)
            
            // 计算未读数量（pending状态）
            let unreadCount = bids.filter { $0.status == .pending }.count
            
            await MainActor.run {
                self.receivedBids = bids
                self.isLoading = false
                onCountUpdate?(unreadCount)
            }
            
            Logger.success("✅ Loaded \(bids.count) received bids, \(unreadCount) unread")
        } catch {
            Logger.error("❌ Failed to load bids: \(error.localizedDescription)")
            
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                onCountUpdate?(0)
            }
        }
    }
}

// MARK: - My Offers内容（从MyBidsView提取）
struct MyBidsViewContent: View {
    let appGreen: Color
    let currentUsername: String
    let onCountUpdate: ((Int) -> Void)?
    
    @State private var sentBids: [Bid] = []
    @State private var isLoading = false
    @State private var selectedBid: Bid?
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            if isLoading && sentBids.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading your bids...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red.opacity(0.6))
                    
                    Text("Failed to load")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Retry") {
                        Task {
                            await loadBids()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(appGreen)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxHeight: .infinity)
            } else if sentBids.isEmpty {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(appGreen.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 48))
                            .foregroundColor(appGreen.opacity(0.6))
                    }
                    
                    VStack(spacing: 8) {
                        Text("No Bids Sent")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("When you make an offer\non assets, it will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sentBids) { bid in
                            MyBidRow(bid: bid, appGreen: appGreen)
                                .onTapGesture {
                                    selectedBid = bid
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            Task {
                await loadBids()
            }
        }
        .overlay {
            if let bid = selectedBid {
                MyBidDetailView(
                    bid: bid,
                    appGreen: appGreen,
                    currentUsername: currentUsername,
                    onClose: {
                        selectedBid = nil
                    },
                    onActionCompleted: {
                        selectedBid = nil
                        Task {
                            await loadBids()
                        }
                    }
                )
            }
        }
    }
    
    private func loadBids() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let bids = try await BidManager.shared.getSentBids(bidderUsername: currentUsername)
            
            // 计算未处理counter数量（countered状态）
            let unreadCount = bids.filter { $0.status == .countered }.count
            
            await MainActor.run {
                self.sentBids = bids
                self.isLoading = false
                onCountUpdate?(unreadCount)
            }
            
            Logger.success("✅ Loaded \(bids.count) sent bids, \(unreadCount) need response")
        } catch {
            Logger.error("❌ Failed to load sent bids: \(error.localizedDescription)")
            
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                onCountUpdate?(0)
            }
        }
    }
}

#Preview {
    BidManagementView(
        appGreen: .green,
        currentUsername: "testuser",
        onClose: {}
    )
}

