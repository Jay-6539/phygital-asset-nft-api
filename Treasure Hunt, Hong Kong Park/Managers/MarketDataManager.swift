//
//  MarketDataManager.swift
//  Treasure Hunt, Hong Kong Park
//
//  管理Market数据的获取和处理
//

import Foundation
import CoreLocation

class MarketDataManager {
    static let shared = MarketDataManager()
    
    private init() {}
    
    // MARK: - 获取Market统计数据
    func fetchMarketStats() async throws -> MarketStats {
        Logger.debug("📊 Fetching market stats...")
        
        // 从asset_checkins获取所有记录进行统计
        let data = try await SupabaseManager.shared.query(
            endpoint: "asset_checkins?select=building_id,username"
        )
        
        struct CheckInRecord: Codable {
            let building_id: String
            let username: String
        }
        
        let decoder = JSONDecoder()
        // 不使用convertFromSnakeCase，因为struct字段名已经是snake_case
        let records = try decoder.decode([CheckInRecord].self, from: data)
        
        // 统计
        let uniqueBuildings = Set(records.map { $0.building_id }).count
        let totalRecords = records.count
        let activeUsers = Set(records.map { $0.username }).count
        
        Logger.success("✅ Market stats: \(uniqueBuildings) buildings, \(totalRecords) records, \(activeUsers) users")
        
        return MarketStats(
            totalBuildings: uniqueBuildings,
            totalRecords: totalRecords,
            activeUsers: activeUsers
        )
    }
    
    // MARK: - 获取热门建筑（记录最多）
    // 注意：此方法需要Supabase RPC函数支持，暂时使用fallback方法
    func fetchTrendingBuildings(limit: Int = 20) async throws -> [BuildingWithStats] {
        // 暂时使用fallback方法
        return try await fetchTrendingBuildingsFallback(limit: limit)
    }
    
    // MARK: - 获取交易最多的记录
    // 注意：此方法需要Supabase RPC函数支持，暂时返回空数组
    func fetchMostTradedRecords(limit: Int = 20) async throws -> [CheckInWithTransferStats] {
        Logger.debug("💎 Fetching most traded records...")
        // TODO: 实现RPC函数后启用
        Logger.info("⚠️ Most traded records feature not yet implemented")
        return []
    }
    
    // MARK: - 获取最活跃用户
    // 注意：此方法需要Supabase RPC函数支持，暂时使用fallback方法
    func fetchTopUsers(limit: Int = 20) async throws -> [UserStats] {
        // 暂时使用fallback方法
        return try await fetchTopUsersFallback(limit: limit)
    }
    
    // MARK: - 临时方法：从asset_checkins直接查询并统计
    func fetchTrendingBuildingsFallback(limit: Int = 20) async throws -> [BuildingWithStats] {
        Logger.debug("🔥 Fetching trending buildings (fallback method)...")
        
        // 获取所有记录
        let data = try await SupabaseManager.shared.query(
            endpoint: "asset_checkins?select=building_id,created_at"
        )
        
        struct CheckInRecord: Codable {
            let building_id: String
            let created_at: String
        }
        
        let decoder = JSONDecoder()
        // 不使用convertFromSnakeCase，因为struct字段名已经是snake_case
        let records = try decoder.decode([CheckInRecord].self, from: data)
        
        // 按building_id分组并统计
        var buildingCounts: [String: Int] = [:]
        var lastActivity: [String: Date] = [:]
        
        let dateFormatter = ISO8601DateFormatter()
        
        for record in records {
            buildingCounts[record.building_id, default: 0] += 1
            
            // 解析日期
            if let date = dateFormatter.date(from: record.created_at) {
                if let existing = lastActivity[record.building_id] {
                    if date > existing {
                        lastActivity[record.building_id] = date
                    }
                } else {
                    lastActivity[record.building_id] = date
                }
            }
        }
        
        // 转换为BuildingWithStats并排序
        var buildings: [BuildingWithStats] = buildingCounts.map { (buildingId, count) in
            BuildingWithStats(
                id: buildingId,
                name: "Building \(buildingId)", // 临时名称，稍后会被真实名称替换
                district: "Unknown",
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                recordCount: count,
                lastActivityTime: lastActivity[buildingId] ?? Date(),
                rank: 0
            )
        }
        
        buildings.sort { $0.recordCount > $1.recordCount }
        
        // 添加排名并限制数量
        let topBuildings = Array(buildings.prefix(limit))
        var rankedBuildings = topBuildings
        for (index, _) in rankedBuildings.enumerated() {
            rankedBuildings[index].rank = index + 1
        }
        
        Logger.success("✅ Fetched \(rankedBuildings.count) trending buildings (fallback)")
        return rankedBuildings
    }
    
    // MARK: - 临时方法：获取最活跃用户（fallback）
    func fetchTopUsersFallback(limit: Int = 20) async throws -> [UserStats] {
        Logger.debug("👑 Fetching top users (fallback method)...")
        
        // 获取所有记录
        let data = try await SupabaseManager.shared.query(
            endpoint: "asset_checkins?select=username,building_id"
        )
        
        struct CheckInRecord: Codable {
            let username: String
            let building_id: String
        }
        
        let decoder = JSONDecoder()
        // 不使用convertFromSnakeCase，因为struct字段名已经是snake_case
        let records = try decoder.decode([CheckInRecord].self, from: data)
        
        // 按用户统计
        var userRecords: [String: Int] = [:]
        var userBuildings: [String: Set<String>] = [:]
        
        for record in records {
            userRecords[record.username, default: 0] += 1
            userBuildings[record.username, default: []].insert(record.building_id)
        }
        
        // 转换为UserStats
        var users: [UserStats] = userRecords.map { (username, recordCount) in
            let uniqueBuildings = userBuildings[username]?.count ?? 0
            // 活跃度评分：每条记录10分 + 每个独特建筑50分
            let activityScore = recordCount * 10 + uniqueBuildings * 50
            
            return UserStats(
                username: username,
                totalRecords: recordCount,
                uniqueBuildings: uniqueBuildings,
                transferCount: 0, // TODO: 需要查询transfer_requests表
                activityScore: activityScore,
                rank: 0
            )
        }
        
        users.sort { $0.activityScore > $1.activityScore }
        
        // 添加排名并限制数量
        let topUsers = Array(users.prefix(limit))
        var rankedUsers = topUsers
        for (index, _) in rankedUsers.enumerated() {
            rankedUsers[index].rank = index + 1
        }
        
        Logger.success("✅ Fetched \(rankedUsers.count) top users (fallback)")
        return rankedUsers
    }
}

