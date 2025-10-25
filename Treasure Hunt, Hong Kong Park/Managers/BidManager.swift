//
//  BidManager.swift
//  Treasure Hunt, Hong Kong Park
//
//  管理Bid竞价功能的业务逻辑
//

import Foundation

class BidManager {
    static let shared = BidManager()
    private init() {}
    
    // MARK: - 创建Bid
    func createBid(request: CreateBidRequest, bidderUsername: String) async throws -> Bid {
        Logger.debug("💰 Creating bid: \(request.bidAmount) credits for record \(request.recordId)")
        
        let bidData: [String: Any] = [
            "record_id": request.recordId.uuidString,
            "record_type": request.recordType,
            "building_id": request.buildingId as Any,
            "bidder_username": bidderUsername,
            "owner_username": request.ownerUsername,
            "bid_amount": request.bidAmount,
            "bidder_message": request.message as Any,
            "status": "pending"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: bidData)
        
        let data = try await NetworkManager.shared.request(
            url: URL(string: "\(SupabaseConfig.url)/rest/v1/bids")!,
            method: "POST",
            headers: [
                "apikey": SupabaseConfig.anonKey,
                "Authorization": "Bearer \(SupabaseConfig.anonKey)",
                "Content-Type": "application/json",
                "Prefer": "return=representation"
            ],
            body: jsonData,
            timeout: 30,
            retries: 3
        )
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bids = try decoder.decode([Bid].self, from: data)
        
        guard let bid = bids.first else {
            throw NSError(domain: "BidManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create bid"])
        }
        
        Logger.success("✅ Bid created: \(bid.id)")
        return bid
    }
    
    // MARK: - 获取我收到的Bid（作为卖家）
    func getReceivedBids(ownerUsername: String) async throws -> [Bid] {
        Logger.debug("📥 Fetching received bids for: \(ownerUsername)")
        
        let data = try await NetworkManager.shared.request(
            url: URL(string: "\(SupabaseConfig.url)/rest/v1/rpc/get_my_received_bids")!,
            method: "POST",
            headers: [
                "apikey": SupabaseConfig.anonKey,
                "Authorization": "Bearer \(SupabaseConfig.anonKey)",
                "Content-Type": "application/json"
            ],
            body: try JSONSerialization.data(withJSONObject: ["username_param": ownerUsername]),
            timeout: 30,
            retries: 2
        )
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bids = try decoder.decode([Bid].self, from: data)
        
        Logger.success("✅ Fetched \(bids.count) received bids")
        return bids
    }
    
    // MARK: - 获取我发出的Bid（作为买家）
    func getSentBids(bidderUsername: String) async throws -> [Bid] {
        Logger.debug("📤 Fetching sent bids for: \(bidderUsername)")
        
        let endpoint = "bids?bidder_username=eq.\(bidderUsername)&order=created_at.desc"
        let data = try await NetworkManager.shared.request(
            url: URL(string: "\(SupabaseConfig.url)/rest/v1/\(endpoint)")!,
            method: "GET",
            headers: [
                "apikey": SupabaseConfig.anonKey,
                "Authorization": "Bearer \(SupabaseConfig.anonKey)"
            ],
            timeout: 30,
            retries: 2
        )
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bids = try decoder.decode([Bid].self, from: data)
        
        Logger.success("✅ Fetched \(bids.count) sent bids")
        return bids
    }
    
    // MARK: - 卖家反价
    func counterOffer(bidId: UUID, counterAmount: Int, message: String?) async throws {
        Logger.debug("🔄 Counter offer: \(counterAmount) credits for bid \(bidId)")
        
        let updateData: [String: Any] = [
            "counter_amount": counterAmount,
            "owner_message": message as Any,
            "status": "countered",
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        
        _ = try await NetworkManager.shared.request(
            url: URL(string: "\(SupabaseConfig.url)/rest/v1/bids?id=eq.\(bidId.uuidString)")!,
            method: "PATCH",
            headers: [
                "apikey": SupabaseConfig.anonKey,
                "Authorization": "Bearer \(SupabaseConfig.anonKey)",
                "Content-Type": "application/json"
            ],
            body: jsonData,
            timeout: 30,
            retries: 3
        )
        
        Logger.success("✅ Counter offer sent: \(counterAmount) credits")
    }
    
    // MARK: - 接受Bid（买家或卖家）
    func acceptBid(bidId: UUID, contactInfo: String, isBidder: Bool) async throws {
        Logger.debug("✅ Accepting bid: \(bidId)")
        
        let updateData: [String: Any] = [
            isBidder ? "bidder_contact" : "owner_contact": contactInfo,
            "status": "accepted",
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        
        _ = try await NetworkManager.shared.request(
            url: URL(string: "\(SupabaseConfig.url)/rest/v1/bids?id=eq.\(bidId.uuidString)")!,
            method: "PATCH",
            headers: [
                "apikey": SupabaseConfig.anonKey,
                "Authorization": "Bearer \(SupabaseConfig.anonKey)",
                "Content-Type": "application/json"
            ],
            body: jsonData,
            timeout: 30,
            retries: 3
        )
        
        Logger.success("✅ Bid accepted, contact info exchanged")
    }
    
    // MARK: - 拒绝Bid
    func rejectBid(bidId: UUID, message: String?) async throws {
        Logger.debug("❌ Rejecting bid: \(bidId)")
        
        let updateData: [String: Any] = [
            "status": "rejected",
            "owner_message": message as Any,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        
        _ = try await NetworkManager.shared.request(
            url: URL(string: "\(SupabaseConfig.url)/rest/v1/bids?id=eq.\(bidId.uuidString)")!,
            method: "PATCH",
            headers: [
                "apikey": SupabaseConfig.anonKey,
                "Authorization": "Bearer \(SupabaseConfig.anonKey)",
                "Content-Type": "application/json"
            ],
            body: jsonData,
            timeout: 30,
            retries: 3
        )
        
        Logger.success("✅ Bid rejected")
    }
    
    // MARK: - 获取未读Bid数量
    func getUnreadBidCount(ownerUsername: String) async throws -> Int {
        Logger.debug("🔔 Fetching unread bid count for: \(ownerUsername)")
        
        let data = try await NetworkManager.shared.request(
            url: URL(string: "\(SupabaseConfig.url)/rest/v1/rpc/get_unread_bid_count")!,
            method: "POST",
            headers: [
                "apikey": SupabaseConfig.anonKey,
                "Authorization": "Bearer \(SupabaseConfig.anonKey)",
                "Content-Type": "application/json"
            ],
            body: try JSONSerialization.data(withJSONObject: ["username_param": ownerUsername]),
            timeout: 15,
            retries: 2
        )
        
        let count = try JSONDecoder().decode(Int.self, from: data)
        
        Logger.debug("🔔 Unread bid count: \(count)")
        return count
    }
}

