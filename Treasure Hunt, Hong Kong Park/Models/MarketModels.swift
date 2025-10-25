//
//  MarketModels.swift
//  Treasure Hunt, Hong Kong Park
//
//  Market功能的数据模型
//

import Foundation
import CoreLocation

// MARK: - Market Tab类型
enum MarketTab: String, CaseIterable {
    case trending = "Trending"
    case mostTraded = "Most Traded"
    case topUsers = "Top Users"
    
    var icon: String {
        switch self {
        case .trending: return "flame.fill"
        case .mostTraded: return "arrow.left.arrow.right.circle.fill"
        case .topUsers: return "crown.fill"
        }
    }
}

// MARK: - 带统计信息的建筑
struct BuildingWithStats: Identifiable {
    let id: String
    let name: String
    let district: String
    let coordinate: CLLocationCoordinate2D
    let recordCount: Int
    let lastActivityTime: Date
    var rank: Int = 0
    
    // 手动初始化
    init(id: String, name: String, district: String, coordinate: CLLocationCoordinate2D, recordCount: Int, lastActivityTime: Date, rank: Int = 0) {
        self.id = id
        self.name = name
        self.district = district
        self.coordinate = coordinate
        self.recordCount = recordCount
        self.lastActivityTime = lastActivityTime
        self.rank = rank
    }
}

// MARK: - 带转账统计的记录
struct CheckInWithTransferStats: Identifiable, Codable {
    let id: String
    let buildingId: String
    let buildingName: String
    let imageUrl: String?
    let ownerUsername: String
    let transferCount: Int
    let createdAt: Date
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case buildingId = "building_id"
        case buildingName = "building_name"
        case imageUrl = "image_url"
        case ownerUsername = "username"
        case transferCount = "transfer_count"
        case createdAt = "created_at"
        case notes
    }
}

// MARK: - 用户统计
struct UserStats: Identifiable, Codable {
    let id: String
    let username: String
    let totalRecords: Int
    let uniqueBuildings: Int
    let transferCount: Int
    let activityScore: Int
    var rank: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case username
        case totalRecords = "total_records"
        case uniqueBuildings = "unique_buildings"
        case transferCount = "transfer_count"
        case activityScore = "activity_score"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decode(String.self, forKey: .username)
        id = username
        totalRecords = try container.decode(Int.self, forKey: .totalRecords)
        uniqueBuildings = try container.decode(Int.self, forKey: .uniqueBuildings)
        transferCount = try container.decodeIfPresent(Int.self, forKey: .transferCount) ?? 0
        activityScore = try container.decode(Int.self, forKey: .activityScore)
    }
    
    init(username: String, totalRecords: Int, uniqueBuildings: Int, transferCount: Int, activityScore: Int, rank: Int = 0) {
        self.id = username
        self.username = username
        self.totalRecords = totalRecords
        self.uniqueBuildings = uniqueBuildings
        self.transferCount = transferCount
        self.activityScore = activityScore
        self.rank = rank
    }
}

// MARK: - Market统计总览
struct MarketStats {
    var totalBuildings: Int = 0
    var totalRecords: Int = 0
    var activeUsers: Int = 0
}

