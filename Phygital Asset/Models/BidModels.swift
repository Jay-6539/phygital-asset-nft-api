//
//  BidModels.swift
//  Phygital Asset
//
//  Bid竞价功能的数据模型
//

import Foundation

// MARK: - Bid记录
struct Bid: Codable, Identifiable {
    let id: UUID
    let recordId: UUID
    let recordType: String
    let buildingId: String?
    
    let bidderUsername: String
    let ownerUsername: String
    
    let bidAmount: Int
    let counterAmount: Int?
    
    let bidderContact: String?
    let ownerContact: String?
    
    let status: BidStatus
    
    let createdAt: Date
    let updatedAt: Date
    let expiresAt: Date
    let completedAt: Date?
    
    let bidderMessage: String?
    let ownerMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case recordId = "record_id"
        case recordType = "record_type"
        case buildingId = "building_id"
        case bidderUsername = "bidder_username"
        case ownerUsername = "owner_username"
        case bidAmount = "bid_amount"
        case counterAmount = "counter_amount"
        case bidderContact = "bidder_contact"
        case ownerContact = "owner_contact"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case expiresAt = "expires_at"
        case completedAt = "completed_at"
        case bidderMessage = "bidder_message"
        case ownerMessage = "owner_message"
    }
}

// MARK: - Bid状态
enum BidStatus: String, Codable {
    case pending = "pending"        // 等待卖家回应
    case countered = "countered"    // 卖家已反价
    case accepted = "accepted"      // 双方接受
    case completed = "completed"    // 已完成交易
    case rejected = "rejected"      // 已拒绝
    case cancelled = "cancelled"    // 买家撤回
    case expired = "expired"        // 已过期
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .countered: return "Counter Offer"
        case .accepted: return "Accepted"
        case .completed: return "Completed"
        case .rejected: return "Rejected"
        case .cancelled: return "Cancelled"
        case .expired: return "Expired"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .countered: return "blue"
        case .accepted: return "green"
        case .completed: return "gray"
        case .rejected: return "red"
        case .cancelled: return "gray"
        case .expired: return "gray"
        }
    }
}

// MARK: - 创建Bid的请求
struct CreateBidRequest {
    let recordId: UUID
    let recordType: String
    let buildingId: String?
    let ownerUsername: String
    let bidAmount: Int
    let message: String?
}

// MARK: - 带记录信息的Bid（用于显示列表）
struct BidWithRecord: Identifiable {
    let bid: Bid
    let recordImageUrl: String?
    let recordDescription: String
    let buildingName: String
    
    var id: UUID { bid.id }
}

