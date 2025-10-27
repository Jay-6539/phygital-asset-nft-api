//
//  NFTTransferView.swift
//  Phygital Asset
//
//  NFT转移界面 - 允许用户转移NFT给其他用户
//

import SwiftUI

struct NFTTransferView: View {
    let nft: NFTInfo
    @State private var recipientUsername = ""
    @State private var transferMessage = ""
    @State private var isTransferring = false
    @State private var showConfirmation = false
    @State private var transferResult: NFTTransferResult?
    @State private var errorMessage: String?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // NFT信息卡片
                NFTCardView(nft: nft)
                    .padding(.horizontal)
                
                // 转移表单
                VStack(alignment: .leading, spacing: 16) {
                    Text("Transfer Details")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recipient Username")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter username", text: $recipientUsername)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transfer Message (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Add a message...", text: $transferMessage, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 转移按钮
                Button(action: {
                    showConfirmation = true
                }) {
                    HStack {
                        if isTransferring {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.right.arrow.left")
                        }
                        
                        Text(isTransferring ? "Transferring..." : "Transfer NFT")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(recipientUsername.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(recipientUsername.isEmpty || isTransferring)
                .padding(.horizontal)
            }
            .navigationTitle("Transfer NFT")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Confirm Transfer", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Transfer", role: .destructive) {
                    performTransfer()
                }
            } message: {
                Text("Are you sure you want to transfer this NFT to @\(recipientUsername)?")
            }
            .alert("Transfer Result", isPresented: .constant(transferResult != nil)) {
                Button("OK") {
                    transferResult = nil
                    if transferResult?.success == true {
                        dismiss()
                    }
                }
            } message: {
                if let result = transferResult {
                    Text(result.success ? "NFT transferred successfully!" : "Transfer failed: \(result.message)")
                }
            }
        }
    }
    
    private func performTransfer() {
        isTransferring = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await NFTManager.shared.transferNFT(
                    threadId: nft.threadId,
                    from: "current-user", // 这里应该从用户会话获取
                    to: recipientUsername
                )
                
                await MainActor.run {
                    self.transferResult = NFTTransferResult(
                        success: result.success,
                        message: result.message ?? "Transfer completed"
                    )
                    self.isTransferring = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isTransferring = false
                }
            }
        }
    }
}

struct NFTTransferResult {
    let success: Bool
    let message: String
}

struct NFTTransferConfirmationView: View {
    let nft: NFTInfo
    let recipientUsername: String
    let transferMessage: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // NFT预览
            NFTCardView(nft: nft)
                .scaleEffect(0.8)
            
            VStack(spacing: 12) {
                Text("Transfer Confirmation")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("From:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("You")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("To:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("@\(recipientUsername)")
                            .fontWeight(.medium)
                    }
                    
                    if !transferMessage.isEmpty {
                        HStack {
                            Text("Message:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(transferMessage)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            VStack(spacing: 12) {
                Button(action: onConfirm) {
                    Text("Confirm Transfer")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: onCancel) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }
}

#Preview {
    NFTTransferView(nft: NFTInfo(
        threadId: UUID(),
        tokenId: "NFT-123456",
        contractAddress: "0xA0fA27fC547D544528e9BE0cb6569E9B925e533E",
        buildingId: "test-building",
        timestamp: "2025-10-27T15:00:00.000Z"
    ))
}
