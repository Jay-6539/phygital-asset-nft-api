//
//  TransferRequest.swift
//  Treasure Hunt, Hong Kong Park
//
//  转让请求数据模型
//

import Foundation

// 转让请求模型
struct TransferRequest: Codable, Identifiable {
    let id: String
    let transferCode: String
    let recordId: String
    let recordType: RecordType  // building 或 ovalOffice
    let nfcUuid: String
    let buildingId: String?
    let buildingName: String
    let assetName: String
    let description: String
    let imageUrl: String?
    let fromUser: String
    let toUser: String?
    let status: TransferStatus
    let createdAt: Date
    let expiresAt: Date
    let completedAt: Date?
    
    enum RecordType: String, Codable {
        case building = "building"
        case ovalOffice = "oval_office"
    }
    
    enum TransferStatus: String, Codable {
        case pending = "pending"
        case completed = "completed"
        case expired = "expired"
        case cancelled = "cancelled"
    }
    
    // 编码键映射
    enum CodingKeys: String, CodingKey {
        case id
        case transferCode = "transfer_code"
        case recordId = "record_id"
        case recordType = "record_type"
        case nfcUuid = "nfc_uuid"
        case buildingId = "building_id"
        case buildingName = "building_name"
        case assetName = "asset_name"
        case description
        case imageUrl = "image_url"
        case fromUser = "from_user"
        case toUser = "to_user"
        case status
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case completedAt = "completed_at"
    }
    
    // 检查是否过期
    var isExpired: Bool {
        return Date() > expiresAt
    }
    
    // 检查是否可以接收
    var canReceive: Bool {
        return status == .pending && !isExpired
    }
}

// 用于QR码的简化数据
struct TransferQRData: Codable {
    let transferCode: String
    let nfcUuid: String
    let buildingName: String
    let assetName: String
    let fromUser: String
    let expiresAt: Date
    
    // 转换为JSON字符串
    func toJSONString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return data.base64EncodedString()
    }
    
    // 从JSON字符串解析
    static func fromJSONString(_ string: String) -> TransferQRData? {
        guard let data = Data(base64Encoded: string),
              let decoded = try? JSONDecoder().decode(TransferQRData.self, from: data) else {
            return nil
        }
        return decoded
    }
}

// 转让结果
struct TransferResult: Codable {
    let success: Bool
    let error: String?
    let transferredRecord: BuildingCheckIn?
}

