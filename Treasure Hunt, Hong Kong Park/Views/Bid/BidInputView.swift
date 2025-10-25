//
//  BidInputView.swift
//  Treasure Hunt, Hong Kong Park
//
//  出价输入界面
//

import SwiftUI

struct BidInputView: View {
    let recordId: UUID
    let recordType: String
    let buildingId: String?
    let ownerUsername: String
    let recordDescription: String
    let currentUsername: String
    let appGreen: Color
    let onClose: () -> Void
    let onSuccess: () -> Void
    
    @State private var bidAmount: String = ""
    @State private var message: String = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var availableCredits = 0
    
    var canSubmit: Bool {
        guard let amount = Int(bidAmount), amount > 0 else { return false }
        return amount <= availableCredits && !message.isEmpty
    }
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isSubmitting {
                        onClose()
                    }
                }
            
            VStack(spacing: 0) {
                // 顶部标题
                VStack(spacing: 12) {
                    Text("Make an Offer")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(recordDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
                
                Divider()
                    .padding(.top, 16)
                
                // 表单内容
                ScrollView {
                    VStack(spacing: 20) {
                        // 出价输入
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Your Bid")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Spacer()
                                
                                // 可用余额显示
                                HStack(spacing: 4) {
                                    Text("Available:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(availableCredits)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(appGreen)
                                }
                            }
                            
                            HStack(spacing: 8) {
                                TextField("0", text: $bidAmount)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 40, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                
                                VStack {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(appGreen)
                                    
                                    Text("Credits")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(appGreen)
                                }
                                .padding(.horizontal, 8)
                            }
                            
                            // 余额不足提示
                            if let amount = Int(bidAmount), amount > availableCredits {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.caption)
                                    Text("Insufficient credits. You need \(amount - availableCredits) more credits.")
                                        .font(.caption)
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 4)
                            }
                        }
                        
                        // 留言
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message (Optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            ZStack(alignment: .topLeading) {
                                if message.isEmpty {
                                    Text("Add a message to the seller...")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .padding(12)
                                }
                                
                                TextEditor(text: $message)
                                    .font(.body)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .opacity(message.isEmpty ? 0.5 : 1)
                            }
                        }
                        
                        // 提示信息
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundColor(appGreen)
                            
                            Text("The seller will be notified of your offer. They can accept, reject, or counter your bid.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(appGreen.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(20)
                }
                
                Divider()
                
                // 底部按钮
                HStack(spacing: 12) {
                    Button(action: {
                        onClose()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                    }
                    .disabled(isSubmitting)
                    
                    Button(action: submitBid) {
                            HStack(spacing: 6) {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Submit")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(canSubmit ? appGreen : Color.gray)
                        .cornerRadius(10)
                    }
                    .disabled(!canSubmit || isSubmitting)
                }
                .padding(20)
            }
            .frame(maxWidth: 500)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(40)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // 加载用户可用Credits余额（总额 - 冻结）
            availableCredits = CreditsManager.shared.getAvailableCredits(for: currentUsername)
            Logger.debug("💰 Available credits for bid: \(availableCredits)")
        }
    }
    
    // MARK: - Actions
    private func submitBid() {
        guard let amount = Int(bidAmount), amount > 0 else {
            errorMessage = "Please enter a valid bid amount"
            showError = true
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                let request = CreateBidRequest(
                    recordId: recordId,
                    recordType: recordType,
                    buildingId: buildingId,
                    ownerUsername: ownerUsername,
                    bidAmount: amount,
                    message: message.isEmpty ? nil : message
                )
                
                _ = try await BidManager.shared.createBid(
                    request: request,
                    bidderUsername: currentUsername
                )
                
                await MainActor.run {
                    isSubmitting = false
                    onSuccess()
                    onClose()
                }
                
            } catch {
                Logger.error("Failed to create bid: \(error.localizedDescription)")
                
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to submit bid. Please try again."
                    showError = true
                }
            }
        }
    }
}

#Preview {
    BidInputView(
        recordId: UUID(),
        recordType: "building",
        buildingId: "1",
        ownerUsername: "seller123",
        recordDescription: "Beautiful historic building check-in with amazing photos",
        currentUsername: "buyer123",
        appGreen: .green,
        onClose: {},
        onSuccess: {}
    )
}

