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
        Logger.debug("📝 Bidder: '\(bidderUsername)' -> Owner: '\(request.ownerUsername)'")
        
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
        
        Logger.debug("📤 Bid data: bidder='\(bidderUsername)', owner='\(request.ownerUsername)', amount=\(request.bidAmount)")
        
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
            Logger.error("❌ No bid returned from database")
            throw NSError(domain: "BidManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create bid"])
        }
        
        Logger.success("✅ Bid created successfully!")
        Logger.debug("📋 Bid ID: \(bid.id)")
        Logger.debug("📋 Bidder: '\(bid.bidderUsername)' | Owner: '\(bid.ownerUsername)'")
        Logger.debug("📋 Amount: \(bid.bidAmount) | Status: \(bid.status.rawValue)")
        
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
        Logger.debug("📤 Fetching sent bids for bidder: '\(bidderUsername)'")
        
        // 尝试使用RPC函数
        do {
            let data = try await NetworkManager.shared.request(
                url: URL(string: "\(SupabaseConfig.url)/rest/v1/rpc/get_my_sent_bids")!,
                method: "POST",
                headers: [
                    "apikey": SupabaseConfig.anonKey,
                    "Authorization": "Bearer \(SupabaseConfig.anonKey)",
                    "Content-Type": "application/json"
                ],
                body: try JSONSerialization.data(withJSONObject: ["username_param": bidderUsername]),
                timeout: 30,
                retries: 2
            )
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let bids = try decoder.decode([Bid].self, from: data)
            
            Logger.success("✅ Fetched \(bids.count) sent bids via RPC for '\(bidderUsername)'")
            return bids
        } catch {
            Logger.warning("⚠️ RPC function failed: \(error.localizedDescription), using fallback")
        }
        
        // Fallback: 直接查询所有状态
        Logger.debug("📤 Using fallback query for bidder: '\(bidderUsername)'")
        let endpoint = "bids?bidder_username=eq.\(bidderUsername)&order=updated_at.desc"
        Logger.debug("🔍 Query endpoint: \(endpoint)")
        
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
        
        Logger.success("✅ Fetched \(bids.count) sent bids via fallback for '\(bidderUsername)'")
        
        // 打印详细信息
        if bids.isEmpty {
            Logger.warning("⚠️ No bids found. Check if bidder_username in database matches: '\(bidderUsername)'")
        } else {
            for bid in bids {
                Logger.debug("📋 Bid: \(bid.id) | Status: \(bid.status.rawValue) | Owner: \(bid.ownerUsername)")
            }
        }
        
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
        Logger.debug("✅ Accepting bid: \(bidId), isBidder: \(isBidder)")
        
        // 先查询bid详情以获取record信息
        let bidData = try await getBidDetail(bidId: bidId)
        
        Logger.debug("📋 Current bid status:")
        Logger.debug("   - Owner contact: \(bidData.ownerContact ?? "nil")")
        Logger.debug("   - Bidder contact: \(bidData.bidderContact ?? "nil")")
        
        // 1. 检查对方是否已经提供联系方式
        let otherPartyHasContact = isBidder ? (bidData.ownerContact != nil && !bidData.ownerContact!.isEmpty) : (bidData.bidderContact != nil && !bidData.bidderContact!.isEmpty)
        let shouldComplete = otherPartyHasContact
        let newStatus = shouldComplete ? "completed" : "accepted"
        
        Logger.debug("🔍 Should complete: \(shouldComplete) (other party has contact: \(otherPartyHasContact))")
        
        let updateData: [String: Any] = [
            isBidder ? "bidder_contact" : "owner_contact": contactInfo,
            "status": newStatus,
            "updated_at": ISO8601DateFormatter().string(from: Date()),
            "completed_at": shouldComplete ? ISO8601DateFormatter().string(from: Date()) : NSNull()
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
        
        Logger.success("✅ Bid updated to \(newStatus), contact info exchanged")
        
        // 2. 如果双方都接受了（completed），转移资产所有权
        if shouldComplete {
            Logger.debug("🔄 Both parties accepted, transferring asset...")
            try await transferAssetOwnership(bid: bidData)
            Logger.success("✅ Asset transfer completed!")
        } else {
            Logger.debug("⏳ Waiting for other party to accept")
        }
    }
    
    // MARK: - 获取Bid详情
    private func getBidDetail(bidId: UUID) async throws -> Bid {
        let endpoint = "bids?id=eq.\(bidId.uuidString)"
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
        
        guard let bid = bids.first else {
            throw NSError(domain: "BidManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bid not found"])
        }
        
        return bid
    }
    
    // MARK: - 转移资产所有权
    private func transferAssetOwnership(bid: Bid) async throws {
        Logger.debug("🔄 Starting asset ownership transfer...")
        Logger.debug("   - Record ID: \(bid.recordId)")
        Logger.debug("   - Record Type: \(bid.recordType)")
        Logger.debug("   - From: '\(bid.ownerUsername)'")
        Logger.debug("   - To: '\(bid.bidderUsername)'")
        
        let updateData: [String: Any] = [
            "username": bid.bidderUsername,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        
        // 根据record_type更新对应的表
        let tableName = bid.recordType == "building" ? "asset_checkins" : "oval_office_checkins"
        let endpoint = "\(tableName)?id=eq.\(bid.recordId.uuidString)"
        
        Logger.debug("📤 Updating table: \(tableName)")
        Logger.debug("📤 Endpoint: \(endpoint)")
        
        let responseData = try await NetworkManager.shared.request(
            url: URL(string: "\(SupabaseConfig.url)/rest/v1/\(endpoint)")!,
            method: "PATCH",
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
        
        // 解析响应以确认更新
        if let responseString = String(data: responseData, encoding: .utf8) {
            Logger.debug("📥 Update response: \(responseString)")
        }
        
        Logger.success("✅ Asset ownership transferred to '\(bid.bidderUsername)'")
        Logger.success("✅ Record \(bid.recordId) now belongs to '\(bid.bidderUsername)'")
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

