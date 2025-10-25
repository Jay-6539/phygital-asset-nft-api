//
//  MyBidsView.swift
//  Treasure Hunt, Hong Kong Park
//
//  我发出的Bid列表（买家视角）
//

import SwiftUI

struct MyBidsView: View {
    let appGreen: Color
    let currentUsername: String
    let onClose: () -> Void
    
    @State private var sentBids: [Bid] = []
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
                                .foregroundColor(appGreen)
                        }
                        .frame(width: 32, height: 32)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("My Bids")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        if !sentBids.isEmpty {
                            Text("\(sentBids.count) active")
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
                    // 空状态
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
    
    // MARK: - Load Bids
    private func loadBids() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let bids = try await BidManager.shared.getSentBids(bidderUsername: currentUsername)
            
            await MainActor.run {
                self.sentBids = bids
                self.isLoading = false
            }
            
            Logger.success("✅ Loaded \(bids.count) sent bids")
        } catch {
            Logger.error("❌ Failed to load sent bids: \(error.localizedDescription)")
            
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - My Bid行组件（买家视角）
struct MyBidRow: View {
    let bid: Bid
    let appGreen: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // 卖家头像
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundColor(statusColor)
                
                // 通知指示器（卖家有回应时）
                if hasUpdate {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                        .offset(x: 15, y: -15)
                }
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("@\(bid.ownerUsername)")
                        .font(.subheadline)
                        .fontWeight(hasUpdate ? .bold : .semibold)
                    
                    // 状态徽章
                    if bid.status == .countered {
                        Text("Counter \(bid.counterAmount ?? 0)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    } else if bid.status == .accepted {
                        Text("Accepted!")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(appGreen)
                            .cornerRadius(4)
                    } else if bid.status == .completed {
                        Text("Completed")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray)
                            .cornerRadius(4)
                    } else if bid.status == .rejected {
                        Text("Rejected")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }
                
                if let message = bid.ownerMessage, !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(timeAgo(bid.updatedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 出价金额
            VStack(alignment: .trailing, spacing: 2) {
                Text("Your Bid")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text("\(bid.bidAmount)")
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
                .strokeBorder(statusColor.opacity(hasUpdate ? 0.4 : 0.1), lineWidth: hasUpdate ? 1.5 : 0)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // 是否有更新（卖家有回应）
    var hasUpdate: Bool {
        bid.status == .countered || bid.status == .accepted || bid.status == .completed
    }
    
    var statusColor: Color {
        switch bid.status {
        case .pending:
            return appGreen
        case .countered:
            return .blue
        case .accepted:
            return appGreen
        case .completed:
            return .gray
        case .rejected:
            return .red
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

// MARK: - My Bid详情（买家视角）
struct MyBidDetailView: View {
    let bid: Bid
    let appGreen: Color
    let currentUsername: String
    let onClose: () -> Void
    let onActionCompleted: () -> Void
    
    @State private var showAcceptCounter = false
    @State private var contactInfo: String = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCongratulations = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isProcessing {
                        onClose()
                    }
                }
            
            VStack(spacing: 0) {
                // 顶部
                VStack(spacing: 16) {
                    HStack {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color(.systemGray6)))
                        }
                        
                        Spacer()
                        
                        Text("Bid Status")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Circle().fill(Color.clear).frame(width: 32, height: 32)
                    }
                    
                    // 卖家信息
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(statusColor.opacity(0.2))
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                                .foregroundColor(statusColor)
                        }
                        .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("@\(bid.ownerUsername)")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(statusText)
                                .font(.caption)
                                .foregroundColor(statusColor)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                
                Divider()
                
                // 内容区域
                ScrollView {
                    VStack(spacing: 20) {
                        // 你的出价
                        VStack(spacing: 12) {
                            Text("Your Offer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(appGreen)
                                
                                Text("\(bid.bidAmount)")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(appGreen)
                                
                                Text("Credits")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(appGreen.opacity(0.1))
                        .cornerRadius(12)
                        
                        // 卖家反价（如果有）
                        if let counterAmount = bid.counterAmount {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Seller's Counter Offer")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                    
                                    Spacer()
                                    
                                    if bid.status == .countered {
                                        Text("⚡ Action Required")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                            .fontWeight(.bold)
                                    }
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                    
                                    Text("\(counterAmount)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    
                                    Text("Credits")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // 你的留言
                        if let message = bid.bidderMessage, !message.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Message")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Text(message)
                                    .font(.body)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // 卖家回复
                        if let message = bid.ownerMessage, !message.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Seller's Reply")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Text(message)
                                    .font(.body)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // 联系方式（accepted状态）
                        if bid.status == .accepted {
                            VStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(appGreen)
                                    
                                    Text("Trade Accepted!")
                                        .font(.headline)
                                        .foregroundColor(appGreen)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(appGreen.opacity(0.1))
                                .cornerRadius(12)
                                
                                if let ownerContact = bid.ownerContact {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Seller's Contact")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)
                                        
                                        HStack {
                                            Text(ownerContact)
                                                .font(.body)
                                                .fontWeight(.semibold)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                UIPasteboard.general.string = ownerContact
                                            }) {
                                                Image(systemName: "doc.on.doc")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(appGreen)
                                            }
                                        }
                                        .padding(12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                if let bidderContact = bid.bidderContact {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Your Contact")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)
                                        
                                        Text(bidderContact)
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .padding(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(appGreen.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // 状态信息
                        if bid.status != .accepted && bid.status != .rejected {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                
                                Text("Expires \(timeUntil(bid.expiresAt))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                    .padding(20)
                }
                
                Divider()
                
                // 底部按钮
                if bid.status == .countered {
                    VStack(spacing: 12) {
                        // 接受反价按钮
                        Button(action: {
                            showAcceptCounter = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                
                                Text("Accept \(bid.counterAmount ?? 0) Credits")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(isProcessing)
                        
                        // 取消按钮
                        Button("Decline") {
                            onClose()
                        }
                        .font(.subheadline)
                        .foregroundColor(appGreen)
                        .padding(.vertical, 8)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                } else if bid.status == .accepted {
                    // 卖家已接受，等待买家确认
                    VStack(spacing: 12) {
                        // 提示信息
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(appGreen)
                            
                            Text("Seller Accepted!")
                                .font(.headline)
                                .foregroundColor(appGreen)
                            
                            Text("The seller has accepted your bid. Confirm to complete the trade.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                        
                        // 确认按钮
                        Button(action: {
                            showAcceptCounter = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                
                                Text("Confirm & Share Contact")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(appGreen)
                            .cornerRadius(12)
                        }
                        .disabled(isProcessing)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                } else if bid.status == .completed {
                    // 交易完成
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.gray)
                            
                            Text("Trade Completed")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        Text("This asset has been transferred to you.\nCheck \"My Assets\" to view it.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                }
            }
            .frame(maxWidth: 500)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(40)
            
            // Accept Counter界面
            if showAcceptCounter {
                AcceptCounterOfferView(
                    bid: bid,
                    appGreen: appGreen,
                    onClose: { showAcceptCounter = false },
                    onSubmit: { contact in
                        acceptCounter(contact: contact)
                    }
                )
            }
            
            // Congratulations动画
            if showCongratulations {
                CongratulationsView(
                    appGreen: appGreen,
                    onDismiss: {
                        showCongratulations = false
                        onActionCompleted() // 刷新列表
                        onClose() // 关闭详情页
                    }
                )
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage)
        }
    }
    
    var statusText: String {
        switch bid.status {
        case .pending:
            return "Waiting for response..."
        case .countered:
            return "Counter offer received"
        case .accepted:
            return "Trade accepted!"
        case .rejected:
            return "Bid rejected"
        default:
            return bid.status.displayName
        }
    }
    
    var statusColor: Color {
        switch bid.status {
        case .pending:
            return .orange
        case .countered:
            return .blue
        case .accepted:
            return appGreen
        case .completed:
            return .gray
        case .rejected:
            return .red
        default:
            return .gray
        }
    }
    
    var hasUpdate: Bool {
        bid.status == .countered || bid.status == .accepted
    }
    
    private func acceptCounter(contact: String) {
        isProcessing = true
        showAcceptCounter = false
        
        Task {
            do {
                try await BidManager.shared.acceptBid(
                    bidId: bid.id,
                    contactInfo: contact,
                    isBidder: true  // 我是买家
                )
                
                await MainActor.run {
                    isProcessing = false
                    // 显示Congratulations动画
                    showCongratulations = true
                    // onActionCompleted会在动画关闭时调用
                }
            } catch {
                Logger.error("Failed to accept counter: \(error)")
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Failed to accept counter offer"
                    showError = true
                }
            }
        }
    }
    
    private func timeUntil(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Accept Counter Offer界面
struct AcceptCounterOfferView: View {
    let bid: Bid
    let appGreen: Color
    let onClose: () -> Void
    let onSubmit: (String) -> Void
    
    @State private var contactInfo: String = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }
                
                Text(bid.status == .accepted ? "Confirm Trade?" : "Accept Counter Offer?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 4) {
                    Text("You will pay:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(bid.status == .accepted ? appGreen : .blue)
                        
                        Text("\(bid.counterAmount ?? bid.bidAmount)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(bid.status == .accepted ? appGreen : .blue)
                        
                        Text("Credits")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background((bid.status == .accepted ? appGreen : Color.blue).opacity(0.1))
                .cornerRadius(12)
                
                // 联系方式输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Contact Info")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text("Share your contact to arrange the trade")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g. +852 1234 5678", text: $contactInfo)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // 说明
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("You'll receive @\(bid.ownerUsername)'s contact info to arrange offline trade.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                // 按钮
                HStack(spacing: 12) {
                    Button("Cancel") {
                        onClose()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    
                    Button("Accept & Share") {
                        onSubmit(contactInfo)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(contactInfo.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(contactInfo.isEmpty)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(40)
        }
    }
}

#Preview {
    MyBidsView(
        appGreen: .green,
        currentUsername: "testuser",
        onClose: {}
    )
}

