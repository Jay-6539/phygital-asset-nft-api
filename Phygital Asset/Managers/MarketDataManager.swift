//
//  MarketDataManager.swift
//  Phygital Asset
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
        // 尝试使用RPC函数（更快）
        do {
            let data = try await SupabaseManager.shared.query(endpoint: "rpc/get_market_stats")
            
            struct StatsResult: Codable {
                let total_buildings: Int
                let total_records: Int
                let active_users: Int
            }
            
            // RPC返回的是数组，取第一个元素
            let results = try JSONDecoder().decode([StatsResult].self, from: data)
            
            if let result = results.first {
                return MarketStats(
                    totalBuildings: result.total_buildings,
                    totalRecords: result.total_records,
                    activeUsers: result.active_users
                )
            }
        } catch {
            Logger.warning("⚠️ RPC function not available, using fallback method")
        }
        
        // Fallback: 客户端统计
        let data = try await SupabaseManager.shared.query(
            endpoint: "threads?select=building_id,username"
        )
        
        struct CheckInRecord: Codable {
            let building_id: String
            let username: String
        }
        
        let records = try JSONDecoder().decode([CheckInRecord].self, from: data)
        
        let uniqueBuildings = Set(records.map { $0.building_id }).count
        let totalRecords = records.count
        let activeUsers = Set(records.map { $0.username }).count
        
        return MarketStats(
            totalBuildings: uniqueBuildings,
            totalRecords: totalRecords,
            activeUsers: activeUsers
        )
    }
    
    // MARK: - 获取热门建筑（记录最多）
    func fetchTrendingBuildings(limit: Int = 20) async throws -> [BuildingWithStats] {
        // 尝试使用RPC函数
        do {
            let data = try await SupabaseManager.shared.query(
                endpoint: "rpc/get_trending_buildings?record_limit=\(limit)"
            )
            
            struct TrendingResult: Codable {
                let building_id: String
                let thread_count: Int
                let latest_thread: String
            }
            
            let results = try JSONDecoder().decode([TrendingResult].self, from: data)
            let dateFormatter = ISO8601DateFormatter()
            
            let buildings = results.enumerated().map { (index, result) -> BuildingWithStats in
                BuildingWithStats(
                    id: result.building_id,
                    name: "Building \(result.building_id)",
                    district: "Unknown",
                    coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                    recordCount: result.thread_count,
                    lastActivityTime: dateFormatter.date(from: result.latest_thread) ?? Date(),
                    rank: index + 1
                )
            }
            
            return buildings
            
        } catch {
            Logger.warning("⚠️ RPC function not available, using fallback")
            return try await fetchTrendingBuildingsFallback(limit: limit)
        }
    }
    
    // MARK: - 获取交易最多的记录
    func fetchMostTradedRecords(limit: Int = 20) async throws -> [CheckInWithTransferStats] {
        // 尝试使用RPC函数
        do {
            let data = try await SupabaseManager.shared.query(
                endpoint: "rpc/get_most_traded_records?record_limit=\(limit)"
            )
            
            struct TradedResult: Codable {
                let record_id: String
                let record_type: String
                let trade_count: Int
                let latest_trade: String
            }
            
            let results = try JSONDecoder().decode([TradedResult].self, from: data)
            let dateFormatter = ISO8601DateFormatter()
            
            let records = results.map { result -> CheckInWithTransferStats in
                CheckInWithTransferStats(
                    id: result.record_id,
                    buildingId: result.record_id, // 使用record_id作为buildingId
                    buildingName: "Building \(result.record_id)", // 临时名称
                    assetName: nil,
                    imageUrl: nil,
                    ownerUsername: "Unknown", // 需要额外查询获取
                    transferCount: result.trade_count,
                    createdAt: dateFormatter.date(from: result.latest_trade) ?? Date(),
                    notes: nil
                )
            }
            
            return records
            
        } catch {
            Logger.warning("⚠️ RPC function not available or no traded records")
            // Fallback: 返回空数组
            return []
        }
    }
    
    // MARK: - 获取最活跃用户
    func fetchTopUsers(limit: Int = 20) async throws -> [UserStats] {
        // 直接使用fallback方法，因为RPC函数有问题
        Logger.debug("👑 Fetching top users (using fallback method)...")
        return try await fetchTopUsersFallback(limit: limit)
    }
    
    // MARK: - 临时方法：从threads直接查询并统计
    func fetchTrendingBuildingsFallback(limit: Int = 20) async throws -> [BuildingWithStats] {
        Logger.debug("🔥 Fetching trending buildings (fallback method)...")
        
        // 获取所有记录
        let data = try await SupabaseManager.shared.query(
            endpoint: "threads?select=building_id,created_at"
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
            endpoint: "threads?select=username,building_id"
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

