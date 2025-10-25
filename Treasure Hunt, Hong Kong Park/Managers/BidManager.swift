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
        
        // 检查是否已有active Bid（防止重复出价）
        Logger.debug("🔍 Checking for existing bids...")
        let checkEndpoint = "bids?record_id=eq.\(request.recordId.uuidString)&bidder_username=eq.\(bidderUsername)&status=in.(pending,countered)"
        
        let checkData = try await NetworkManager.shared.request(
            url: URL(string: "\(SupabaseConfig.url)/rest/v1/\(checkEndpoint)")!,
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
        let existingBids = try decoder.decode([Bid].self, from: checkData)
        
        if !existingBids.isEmpty {
            Logger.warning("⚠️ User already has an active bid for this asset")
            throw NSError(domain: "BidManager", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "You already have an active bid for this asset. Please wait for the seller's response or cancel your existing bid."
            ])
        }
        
        Logger.debug("✅ No existing bids found, proceeding to create new bid")
        
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
        
        // 复用已创建的decoder
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
        
        // Counter后重置过期时间为7天，给买家足够时间回应
        let newExpiresAt = Date().addingTimeInterval(7 * 24 * 60 * 60)
        
        let updateData: [String: Any] = [
            "counter_amount": counterAmount,
            "owner_message": message as Any,
            "status": "countered",
            "updated_at": ISO8601DateFormatter().string(from: Date()),
            "expires_at": ISO8601DateFormatter().string(from: newExpiresAt)
        ]
        
        Logger.debug("⏰ Expires at reset to: \(newExpiresAt)")
        
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
        
        // 2. 如果是卖家Accept，自动拒绝同一资产的其他pending Bid
        if !isBidder && newStatus == "accepted" {
            Logger.debug("🚫 Seller accepted, rejecting other pending bids for this asset...")
            try await rejectOtherBidsForAsset(
                acceptedBidId: bidId,
                recordId: bidData.recordId,
                recordType: bidData.recordType
            )
        }
        
        // 3. 如果双方都接受了（completed），转移资产所有权
        if shouldComplete {
            Logger.debug("🔄 Both parties accepted, transferring asset...")
            try await transferAssetOwnership(bid: bidData)
            
            // 转移完成后，也拒绝其他所有pending的Bid
            Logger.debug("🚫 Asset transferred, rejecting all other bids for this asset...")
            try await rejectOtherBidsForAsset(
                acceptedBidId: bidId,
                recordId: bidData.recordId,
                recordType: bidData.recordType
            )
            
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
        
        // 首先查询记录是否存在
        let tableName = bid.recordType == "building" ? "asset_checkins" : "oval_office_checkins"
        let queryUrl = URL(string: "\(SupabaseConfig.url)/rest/v1/\(tableName)?id=eq.\(bid.recordId.uuidString.lowercased())&select=id,username,asset_name")!
        
        Logger.debug("🔍 Verifying record exists...")
        Logger.debug("   Query: \(queryUrl.absoluteString)")
        
        let queryData = try await NetworkManager.shared.request(
            url: queryUrl,
            method: "GET",
            headers: [
                "apikey": SupabaseConfig.anonKey,
                "Authorization": "Bearer \(SupabaseConfig.anonKey)"
            ],
            timeout: 30,
            retries: 3
        )
        
        if let queryString = String(data: queryData, encoding: .utf8) {
            Logger.debug("   Query result: \(queryString)")
            
            if queryString == "[]" {
                Logger.error("❌ Record not found in database!")
                throw NSError(domain: "BidManager", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: "Asset record not found. It may have been deleted."
                ])
            }
        }
        
        let updateData: [String: Any] = [
            "username": bid.bidderUsername,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        
        // 尝试不同的查询格式
        let recordIdString = bid.recordId.uuidString.uppercased()
        
        Logger.debug("📤 Updating table: \(tableName)")
        Logger.debug("📤 Record ID (UUID): \(recordIdString)")
        
        // 首先尝试直接使用UUID字符串查询
        var endpoint = "\(tableName)?id=eq.\(recordIdString)"
        Logger.debug("📤 Endpoint attempt 1: \(endpoint)")
        
        var responseData = try await NetworkManager.shared.request(
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
        
        // 检查返回是否为空
        if let responseString = String(data: responseData, encoding: .utf8), responseString == "[]" {
            Logger.warning("⚠️ First attempt returned empty, trying lowercase UUID...")
            
            // 尝试小写UUID
            endpoint = "\(tableName)?id=eq.\(bid.recordId.uuidString.lowercased())"
            Logger.debug("📤 Endpoint attempt 2: \(endpoint)")
            
            responseData = try await NetworkManager.shared.request(
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
        }
        
        // 解析响应以确认更新
        if let responseString = String(data: responseData, encoding: .utf8) {
            Logger.debug("📥 Final update response: \(responseString)")
            
            // 检查是否成功更新
            if responseString == "[]" {
                Logger.error("❌ Asset update failed - record not found!")
                Logger.error("   Tried record_id: \(bid.recordId)")
                Logger.error("   Table: \(tableName)")
                
                // 尝试查询记录是否存在
                Logger.debug("🔍 Attempting to query record directly...")
                let queryEndpoint = "\(tableName)?select=id,username&id=eq.\(bid.recordId.uuidString.lowercased())"
                Logger.debug("🔍 Query: \(queryEndpoint)")
                
                throw NSError(domain: "BidManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Asset record not found. The record may have been deleted."
                ])
            } else {
                Logger.success("✅ Asset ownership transferred to '\(bid.bidderUsername)'")
                Logger.success("✅ Record \(bid.recordId) now belongs to '\(bid.bidderUsername)'")
            }
        }
    }
    
    // MARK: - 拒绝同一资产的其他Bid
    private func rejectOtherBidsForAsset(
        acceptedBidId: UUID,
        recordId: UUID,
        recordType: String
    ) async throws {
        Logger.debug("🔍 Finding other bids for record: \(recordId)")
        
        // 查询同一资产的所有pending和countered状态的Bid（排除当前接受的Bid）
        let endpoint = "bids?record_id=eq.\(recordId.uuidString)&record_type=eq.\(recordType)&status=in.(pending,countered)&id=neq.\(acceptedBidId.uuidString)"
        
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
        let otherBids = try decoder.decode([Bid].self, from: data)
        
        Logger.debug("📋 Found \(otherBids.count) other bids to reject")
        
        guard !otherBids.isEmpty else {
            Logger.debug("✅ No other bids to reject")
            return
        }
        
        // 批量拒绝这些Bid
        let rejectData: [String: Any] = [
            "status": "rejected",
            "owner_message": "This asset has been sold to another buyer.",
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: rejectData)
        
        // 使用in操作符批量更新
        let bidIds = otherBids.map { $0.id.uuidString }.joined(separator: ",")
        let updateEndpoint = "bids?id=in.(\(bidIds))"
        
        _ = try await NetworkManager.shared.request(
            url: URL(string: "\(SupabaseConfig.url)/rest/v1/\(updateEndpoint)")!,
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
        
        Logger.success("✅ Rejected \(otherBids.count) other bids for this asset")
        
        // 记录被拒绝的Bid
        for bid in otherBids {
            Logger.debug("   ❌ Rejected bid from @\(bid.bidderUsername) (\(bid.bidAmount) credits)")
        }
    }
    
    // MARK: - 撤回Bid（买家）
    func cancelBid(bidId: UUID) async throws {
        Logger.debug("🔙 Cancelling bid: \(bidId)")
        
        // 先查询bid状态，确保只有pending可以撤回
        let bidData = try await getBidDetail(bidId: bidId)
        
        guard bidData.status == .pending else {
            Logger.warning("⚠️ Cannot cancel bid with status: \(bidData.status.rawValue)")
            throw NSError(domain: "BidManager", code: -3, userInfo: [
                NSLocalizedDescriptionKey: "Only pending bids can be cancelled. This bid is already \(bidData.status.displayName.lowercased())."
            ])
        }
        
        let updateData: [String: Any] = [
            "status": "cancelled",
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
        
        Logger.success("✅ Bid cancelled successfully")
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

