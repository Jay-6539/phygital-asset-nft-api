//
//  MyNFTsView.swift
//  Phygital Asset
//
//  NFT展示界面 - 显示用户拥有的所有NFT
//

import SwiftUI

struct MyNFTsView: View {
    @State private var userNFTs: [NFTInfo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var username: String = "testuser" // 临时测试用户名
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading NFTs...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Failed to load NFTs")
                            .font(.headline)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            loadUserNFTs()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if userNFTs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No NFTs Found")
                            .font(.headline)
                        
                        Text("Create some Threads to mint NFTs!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(userNFTs, id: \.tokenId) { nft in
                                NFTCardView(nft: nft)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My NFTs")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadUserNFTs()
            }
            .refreshable {
                loadUserNFTs()
            }
        }
    }
    
    private func loadUserNFTs() {
        isLoading = true
        errorMessage = nil
        
        Task {
            if let nfts = await NFTManager.shared.getUserNFTs(username: username) {
                await MainActor.run {
                    self.userNFTs = nfts
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Unable to load NFTs. Please check your connection."
                    self.isLoading = false
                }
            }
        }
    }
}

struct NFTCardView: View {
    let nft: NFTInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // NFT图片占位符
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                        Text("NFT Image")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Token ID")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(nft.tokenId)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let buildingId = nft.buildingId {
                    Text("Building: \(buildingId)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let timestamp = nft.timestamp {
                    Text(formatDate(timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                // Polygonscan链接
                if let polygonscanURL = nft.polygonscanURL {
                    Link(destination: polygonscanURL) {
                        Image(systemName: "link")
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                // OpenSea链接
                if let openseaURL = nft.openseaURL {
                    Link(destination: openseaURL) {
                        Image(systemName: "globe")
                            .font(.caption)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
    MyNFTsView()
}
