//
//  NFTDetailView.swift
//  Phygital Asset
//
//  NFT详情页面 - 显示特定NFT的详细信息
//

import SwiftUI

struct NFTDetailView: View {
    let tokenId: String
    @State private var nftDetail: NFTDetail?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading NFT details...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Failed to load NFT")
                            .font(.headline)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            loadNFTDetail()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let nft = nftDetail {
                    VStack(spacing: 20) {
                        // NFT图片
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("NFT Image")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                }
                            )
                            .padding(.horizontal)
                        
                        // NFT信息
                        VStack(alignment: .leading, spacing: 16) {
                            // 基本信息
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Basic Information")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                InfoRow(label: "Token ID", value: nft.tokenId)
                                InfoRow(label: "Thread ID", value: nft.threadId)
                                InfoRow(label: "Building ID", value: nft.buildingId)
                                InfoRow(label: "Owner", value: nft.owner)
                                InfoRow(label: "Created", value: formatDate(nft.timestamp))
                            }
                            
                            Divider()
                            
                            // 合约信息
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Contract Information")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                InfoRow(label: "Contract Address", value: nft.contractAddress)
                                InfoRow(label: "Network", value: "Amoy Testnet")
                                InfoRow(label: "Chain ID", value: "80002")
                            }
                            
                            Divider()
                            
                            // 元数据
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Metadata")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                InfoRow(label: "Name", value: nft.metadata.name)
                                InfoRow(label: "Description", value: nft.metadata.description)
                                InfoRow(label: "Image URL", value: nft.metadata.image)
                            }
                            
                            Divider()
                            
                            // 区块链链接
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Blockchain Links")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                VStack(spacing: 8) {
                                    BlockchainLinkButton(
                                        title: "View on Polygonscan",
                                        icon: "link",
                                        url: URL(string: "https://amoy.polygonscan.com/token/\(nft.contractAddress)?a=\(nft.tokenId)")
                                    )
                                    
                                    BlockchainLinkButton(
                                        title: "View on OpenSea",
                                        icon: "globe",
                                        url: URL(string: "https://testnets.opensea.io/assets/amoy/\(nft.contractAddress)/\(nft.tokenId)")
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("NFT Details")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadNFTDetail()
        }
    }
    
    private func loadNFTDetail() {
        isLoading = true
        errorMessage = nil
        
        Task {
            if let detail = await NFTManager.shared.getNFTDetail(tokenId: tokenId) {
                await MainActor.run {
                    self.nftDetail = detail
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Unable to load NFT details. Please check your connection."
                    self.isLoading = false
                }
            }
        }
    }
    
    private func formatDate(_ timestamp: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: timestamp) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .full
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return timestamp
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            Spacer()
        }
    }
}

struct BlockchainLinkButton: View {
    let title: String
    let icon: String
    let url: URL?
    
    var body: some View {
        if let url = url {
            Link(destination: url) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        } else {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Unavailable")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .opacity(0.6)
        }
    }
}

#Preview {
    NavigationView {
        NFTDetailView(tokenId: "NFT-123456")
    }
}
