//
//  BidListView.swift
//  Treasure Hunt, Hong Kong Park
//
//  显示收到的Bid列表（卖家视角）
//

import SwiftUI

struct BidListView: View {
    let appGreen: Color
    let currentUsername: String
    let onClose: () -> Void
    
    @State private var receivedBids: [Bid] = []
    @State private var isLoading = false
    @State private var selectedBid: Bid?
    @State private var errorMessage: String?
    
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
                    
                    VStack(spacing: 2) {
                        Text("Bids Received")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        if !receivedBids.isEmpty {
                            Text("\(receivedBids.count) active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 刷新按钮
                    Button(action: {
                        Task {
                            await loadBids()
                        }
                    }) {
                        ZStack {
                            Circle().fill(Color.white)
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                                .foregroundStyle(isLoading ? .gray : appGreen)
                        }
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                    }
                    .disabled(isLoading)
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // MARK: - 内容区域
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
                    // 空状态
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
    
    // MARK: - Load Bids
    private func loadBids() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let bids = try await BidManager.shared.getReceivedBids(ownerUsername: currentUsername)
            
            await MainActor.run {
                self.receivedBids = bids
                self.isLoading = false
            }
            
            Logger.success("✅ Loaded \(bids.count) received bids")
        } catch {
            Logger.error("❌ Failed to load bids: \(error.localizedDescription)")
            
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Bid行组件
struct BidRow: View {
    let bid: Bid
    let appGreen: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // 买家头像
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundColor(statusColor)
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("@\(bid.bidderUsername)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    // 状态徽章
                    if bid.status == .countered {
                        Text("Countered")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    } else if bid.status == .accepted {
                        Text("Accepted")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(appGreen)
                            .cornerRadius(4)
                    }
                }
                
                if let message = bid.bidderMessage, !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 4) {
                    Text(timeAgo(bid.updatedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    // Counter offer提示
                    if let counterAmount = bid.counterAmount {
                        Text("• You: \(counterAmount)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            Spacer()
            
            // 出价金额
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(bid.counterAmount ?? bid.bidAmount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(statusColor)
                }
                
                Text("Credits")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(statusColor.opacity(0.2), lineWidth: bid.status == .pending ? 0 : 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    var statusColor: Color {
        switch bid.status {
        case .pending:
            return appGreen
        case .countered:
            return .blue
        case .accepted:
            return appGreen
        default:
            return .gray
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
            let minutes = max(1, Int(interval / 60))
            return "\(minutes)m ago"
        }
    }
}

#Preview {
    BidListView(
        appGreen: .green,
        currentUsername: "testuser",
        onClose: {}
    )
}

