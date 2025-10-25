//
//  BidDetailView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Bid详情界面（卖家处理Bid）
//

import SwiftUI

struct BidDetailView: View {
    let bid: Bid
    let appGreen: Color
    let currentUsername: String
    let onClose: () -> Void
    let onActionCompleted: () -> Void
    
    @State private var showCounter = false
    @State private var counterAmount: String = ""
    @State private var counterMessage: String = ""
    @State private var showAccept = false
    @State private var contactInfo: String = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
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
                        
                        Text("Bid Details")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Circle().fill(Color.clear).frame(width: 32, height: 32)
                    }
                    
                    // 买家信息
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(appGreen.opacity(0.2))
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                                .foregroundColor(appGreen)
                        }
                        .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("@\(bid.bidderUsername)")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(timeAgo(bid.createdAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                        // 出价金额
                        VStack(spacing: 12) {
                            Text("Offer Amount")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(appGreen)
                                
                                Text("\(bid.bidAmount)")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(appGreen)
                                
                                Text("Credits")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(appGreen.opacity(0.1))
                        .cornerRadius(16)
                        
                        // 反价金额（如果有）
                        if let counterAmount = bid.counterAmount {
                            VStack(spacing: 8) {
                                Text("Your Counter Offer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
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
                        
                        // 买家留言
                        if let message = bid.bidderMessage, !message.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Bidder's Message")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Text(message)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // 卖家回复（如果有）
                        if let message = bid.ownerMessage, !message.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Reply")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Text(message)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(appGreen.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // 状态信息
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
                    .padding(20)
                }
                
                Divider()
                
                // 底部按钮
                if bid.status == .pending || bid.status == .countered {
                    VStack(spacing: 12) {
                        // 接受按钮
                        Button(action: {
                            showAccept = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                
                                Text("Accept \(bid.counterAmount != nil ? "Counter" : "Bid")")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(appGreen)
                            .cornerRadius(12)
                        }
                        .disabled(isProcessing)
                        
                        HStack(spacing: 12) {
                            // 反价按钮（pending和countered都可以继续反价）
                            Button(action: {
                                showCounter = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(size: 14))
                                    
                                    Text(bid.status == .countered ? "Change Price" : "Counter")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(bid.status == .countered ? Color.blue : appGreen)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background {
                                    ZStack {
                                        Color.clear.background(.ultraThinMaterial)
                                        (bid.status == .countered ? Color.blue : appGreen).opacity(0.1)
                                    }
                                }
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder((bid.status == .countered ? Color.blue : appGreen).opacity(0.3), lineWidth: 1)
                                )
                            }
                            .disabled(isProcessing)
                            
                            // 拒绝按钮
                            Button(action: {
                                rejectBid()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                    
                                    Text("Reject")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing)
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                } else if bid.status == .accepted {
                    // Accepted状态显示联系信息
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(appGreen)
                            
                            Text("Bid Accepted!")
                                .font(.headline)
                                .foregroundColor(appGreen)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(appGreen.opacity(0.1))
                        .cornerRadius(12)
                        
                        // 显示双方联系方式
                        if let bidderContact = bid.bidderContact {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Buyer's Contact")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(bidderContact)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        
                        if let ownerContact = bid.ownerContact {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Your Contact")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(ownerContact)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(appGreen.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
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
            
            // Counter Offer界面
            if showCounter {
                CounterOfferView(
                    originalBid: bid.bidAmount,
                    appGreen: appGreen,
                    onClose: { showCounter = false },
                    onSubmit: { amount, message in
                        submitCounter(amount: amount, message: message)
                    }
                )
            }
            
            // Accept确认界面
            if showAccept {
                AcceptBidView(
                    bid: bid,
                    appGreen: appGreen,
                    onClose: { showAccept = false },
                    onSubmit: { contact in
                        acceptBid(contact: contact)
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
    
    // MARK: - Actions
    private func submitCounter(amount: Int, message: String?) {
        isProcessing = true
        showCounter = false
        
        Task {
            do {
                try await BidManager.shared.counterOffer(
                    bidId: bid.id,
                    counterAmount: amount,
                    message: message
                )
                
                await MainActor.run {
                    isProcessing = false
                    onActionCompleted()
                }
            } catch {
                Logger.error("Failed to send counter offer: \(error)")
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Failed to send counter offer"
                    showError = true
                }
            }
        }
    }
    
    private func acceptBid(contact: String) {
        isProcessing = true
        showAccept = false
        
        Task {
            do {
                try await BidManager.shared.acceptBid(
                    bidId: bid.id,
                    contactInfo: contact,
                    isBidder: false  // 我是卖家
                )
                
                await MainActor.run {
                    isProcessing = false
                    onActionCompleted()
                }
            } catch {
                Logger.error("Failed to accept bid: \(error)")
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Failed to accept bid"
                    showError = true
                }
            }
        }
    }
    
    private func rejectBid() {
        isProcessing = true
        
        Task {
            do {
                try await BidManager.shared.rejectBid(bidId: bid.id, message: nil)
                
                await MainActor.run {
                    isProcessing = false
                    onActionCompleted()
                }
            } catch {
                Logger.error("Failed to reject bid: \(error)")
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Failed to reject bid"
                    showError = true
                }
            }
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func timeUntil(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Counter Offer界面
struct CounterOfferView: View {
    let originalBid: Int
    let appGreen: Color
    let onClose: () -> Void
    let onSubmit: (Int, String?) -> Void
    
    @State private var counterAmount: String = ""
    @State private var message: String = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Counter Offer")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Original bid: \(originalBid) Credits")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // 反价输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Counter Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        TextField("\(originalBid)", text: $counterAmount)
                            .keyboardType(.numberPad)
                            .font(.system(size: 36, weight: .bold))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        VStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundColor(appGreen)
                            
                            Text("Credits")
                                .font(.caption2)
                                .foregroundColor(appGreen)
                        }
                    }
                }
                
                // 留言
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $message)
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
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
                    
                    Button("Send") {
                        if let amount = Int(counterAmount), amount > 0 {
                            onSubmit(amount, message.isEmpty ? nil : message)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(counterAmount.isEmpty ? Color.gray : appGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(counterAmount.isEmpty)
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

// MARK: - Accept Bid界面
struct AcceptBidView: View {
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
                // 图标
                ZStack {
                    Circle()
                        .fill(appGreen.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(appGreen)
                }
                
                Text("Accept This Bid?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // 金额确认
                VStack(spacing: 4) {
                    Text("You will receive:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(appGreen)
                        
                        Text("\(bid.counterAmount ?? bid.bidAmount)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(appGreen)
                        
                        Text("Credits")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(appGreen.opacity(0.1))
                .cornerRadius(12)
                
                // 联系方式输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Contact Info")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text("Enter your phone/WeChat/email to arrange the trade")
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
                        .foregroundColor(.orange)
                    
                    Text("Your contact info will be shared with @\(bid.bidderUsername) for offline trade arrangement.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
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
                    
                    Button("Accept & Share Contact") {
                        onSubmit(contactInfo)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(contactInfo.isEmpty ? Color.gray : appGreen)
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
    BidDetailView(
        bid: Bid(
            id: UUID(),
            recordId: UUID(),
            recordType: "building",
            buildingId: "1",
            bidderUsername: "buyer123",
            ownerUsername: "seller456",
            bidAmount: 500,
            counterAmount: nil,
            bidderContact: nil,
            ownerContact: nil,
            status: .pending,
            createdAt: Date(),
            updatedAt: Date(),
            expiresAt: Date().addingTimeInterval(86400 * 7),
            completedAt: nil,
            bidderMessage: "I really want this piece!",
            ownerMessage: nil
        ),
        appGreen: .green,
        currentUsername: "seller456",
        onClose: {},
        onActionCompleted: {}
    )
}

