//
//  NFTModels.swift
//  Phygital Asset
//
//  NFT相关数据模型
//

import Foundation

// MARK: - NFT所有权记录（存储在Supabase）
struct NFTOwnershipRecord: Codable {
    let id: UUID
    let threadId: UUID          // 关联的Thread ID
    let tokenId: String         // ERC-1155 Token ID
    let contractAddress: String // 智能合约地址
    let currentOwnerUserId: UUID
    let originalMinterUserId: UUID
    let mintedAt: Date
    let lastTransferredAt: Date?
    let transactionHash: String?
    let metadata: NFTMetadata?
    
    enum CodingKeys: String, CodingKey {
        case id
        case threadId = "thread_id"
        case tokenId = "token_id"
        case contractAddress = "contract_address"
        case currentOwnerUserId = "current_owner_user_id"
        case originalMinterUserId = "original_minter_user_id"
        case mintedAt = "minted_at"
        case lastTransferredAt = "last_transferred_at"
        case transactionHash = "transaction_hash"
        case metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        threadId = try container.decode(UUID.self, forKey: .threadId)
        tokenId = try container.decode(String.self, forKey: .tokenId)
        contractAddress = try container.decode(String.self, forKey: .contractAddress)
        currentOwnerUserId = try container.decode(UUID.self, forKey: .currentOwnerUserId)
        originalMinterUserId = try container.decode(UUID.self, forKey: .originalMinterUserId)
        mintedAt = try container.decode(Date.self, forKey: .mintedAt)
        lastTransferredAt = try container.decodeIfPresent(Date.self, forKey: .lastTransferredAt)
        transactionHash = try container.decodeIfPresent(String.self, forKey: .transactionHash)
        metadata = try container.decodeIfPresent(NFTMetadata.self, forKey: .metadata)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(threadId, forKey: .threadId)
        try container.encode(tokenId, forKey: .tokenId)
        try container.encode(contractAddress, forKey: .contractAddress)
        try container.encode(currentOwnerUserId, forKey: .currentOwnerUserId)
        try container.encode(originalMinterUserId, forKey: .originalMinterUserId)
        try container.encode(mintedAt, forKey: .mintedAt)
        try container.encodeIfPresent(lastTransferredAt, forKey: .lastTransferredAt)
        try container.encodeIfPresent(transactionHash, forKey: .transactionHash)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
}

// MARK: - NFT元数据
struct NFTMetadata: Codable {
    let name: String
    let description: String
    let image: String           // IPFS URL或HTTP URL
    let buildingId: String?
    let buildingName: String?
    let location: NFTLocation?
    let attributes: [NFTAttribute]?
}

struct NFTLocation: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?
}

struct NFTAttribute: Codable {
    let traitType: String
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case traitType = "trait_type"
        case value
    }
}

// MARK: - NFT转移历史
struct NFTTransferHistory: Codable {
    let id: UUID
    let nftRecordId: UUID
    let fromUserId: UUID
    let toUserId: UUID
    let transferredAt: Date
    let transactionHash: String?
    let transferType: NFTTransferType
    let bidId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id
        case nftRecordId = "nft_record_id"
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case transferredAt = "transferred_at"
        case transactionHash = "transaction_hash"
        case transferType = "transfer_type"
        case bidId = "bid_id"
    }
}

enum NFTTransferType: String, Codable {
    case mint = "mint"
    case bid = "bid"
    case gift = "gift"
    case burn = "burn"
}

// MARK: - 用户的NFT摘要
struct UserNFTSummary {
    let userId: UUID
    let totalNFTs: Int
    let mintedNFTs: Int         // 作为原创者铸造的
    let acquiredNFTs: Int       // 通过Bid获得的
    let nfts: [NFTOwnershipRecord]
}

// MARK: - NFT显示用视图模型
struct NFTDisplayData: Identifiable {
    let id: UUID
    let threadId: UUID
    let tokenId: String
    let name: String
    let description: String
    let imageURL: URL?
    let buildingName: String
    let mintedAt: Date
    let isOriginalMinter: Bool
    let contractAddress: String
    
    var shortTokenId: String {
        String(tokenId.prefix(8))
    }
    
    var polygonscanURL: URL? {
        // Amoy测试网浏览器链接
        URL(string: "https://amoy.polygonscan.com/token/\(contractAddress)?a=\(tokenId)")
    }
    
    var openseaURL: URL? {
        // OpenSea测试网链接
        URL(string: "https://testnets.opensea.io/assets/amoy/\(contractAddress)/\(tokenId)")
    }
    
    var formattedMintDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: mintedAt)
    }
}

