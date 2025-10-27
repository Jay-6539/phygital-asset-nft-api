//
//  NFTTransferHistoryView.swift
//  Phygital Asset
//
//  NFT转移历史记录界面 - 显示用户的NFT转移历史
//

import SwiftUI

struct NFTTransferHistoryView: View {
    @State private var transferHistory: [TransferRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var username: String = "testuser" // 临时测试用户名
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading transfer history...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Failed to load history")
                            .font(.headline)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            loadTransferHistory()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if transferHistory.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.right.arrow.left")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Transfer History")
                            .font(.headline)
                        
                        Text("Your NFT transfers will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List(transferHistory) { record in
                        TransferRecordRow(record: record)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Transfer History")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadTransferHistory()
            }
            .refreshable {
                loadTransferHistory()
            }
        }
    }
    
    private func loadTransferHistory() {
        isLoading = true
        errorMessage = nil
        
        Task {
            // 模拟加载转移历史
            await MainActor.run {
                self.transferHistory = [
                    TransferRecord(
                        id: UUID(),
                        tokenId: "NFT-123456",
                        fromUsername: "user1",
                        toUsername: "user2",
                        timestamp: "2025-10-27T15:00:00.000Z",
                        status: .completed,
                        message: "Thanks for the NFT!"
                    ),
                    TransferRecord(
                        id: UUID(),
                        tokenId: "NFT-789012",
                        fromUsername: "user3",
                        toUsername: "testuser",
                        timestamp: "2025-10-26T14:30:00.000Z",
                        status: .completed,
                        message: nil
                    )
                ]
                self.isLoading = false
            }
        }
    }
}

struct TransferRecord: Identifiable {
    let id: UUID
    let tokenId: String
    let fromUsername: String
    let toUsername: String
    let timestamp: String
    let status: TransferStatus
    let message: String?
    
    enum TransferStatus {
        case pending
        case completed
        case failed
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .completed: return .green
            case .failed: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "clock"
            case .completed: return "checkmark.circle"
            case .failed: return "xmark.circle"
            }
        }
    }
}

struct TransferRecordRow: View {
    let record: TransferRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Token ID: \(record.tokenId)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(record.fromUsername) → \(record.toUsername)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Image(systemName: record.status.icon)
                            .foregroundColor(record.status.color)
                        Text(record.status == .completed ? "Completed" : 
                             record.status == .pending ? "Pending" : "Failed")
                            .font(.caption)
                            .foregroundColor(record.status.color)
                    }
                    
                    Text(formatDate(record.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if let message = record.message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ timestamp: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: timestamp) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return timestamp
    }
}

#Preview {
    NFTTransferHistoryView()
}
