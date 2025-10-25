//
//  TransferManager.swift
//  Treasure Hunt, Hong Kong Park
//
//  转让管理器
//

import Foundation
import UIKit

class TransferManager {
    static let shared = TransferManager()
    
    private let baseURL = SupabaseConfig.url
    private let apiKey = SupabaseConfig.anonKey
    private let tableName = "transfer_requests"
    
    private init() {}
    
    // MARK: - Helper Methods
    
    /// 创建 URLRequest
    private func createRequest(url: URL, method: String = "GET", body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    // MARK: - 创建转让请求
    
    /// 创建Building记录转让
    func createBuildingTransfer(checkIn: BuildingCheckIn, fromUser: String) async throws -> TransferRequest {
        Logger.debug("📤 创建Building转让请求")
        Logger.debug("   Record ID: \(checkIn.id)")
        Logger.debug("   From User: \(fromUser)")
        
        let transferData: [String: Any] = [
            "record_id": checkIn.id.uuidString,
            "record_type": "building",
            "nfc_uuid": checkIn.nfcUuid ?? "",
            "building_id": checkIn.buildingId,
            "building_name": "Building",
            "asset_name": checkIn.assetName ?? "Unknown Asset",
            "description": checkIn.description,
            "image_url": checkIn.imageUrl ?? "",
            "from_user": fromUser
        ]
        
        guard let url = URL(string: "\(baseURL)/rest/v1/\(tableName)") else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: transferData)
        let request = createRequest(url: url, method: "POST", body: jsonData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "TransferManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let transfers = try decoder.decode([TransferRequest].self, from: data)
        guard let transfer = transfers.first else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No transfer returned"])
        }
        
        Logger.success("✅ 转让请求已创建: \(transfer.transferCode)")
        return transfer
    }
    
    /// 创建Oval Office记录转让
    func createOvalOfficeTransfer(checkIn: OvalOfficeCheckIn, fromUser: String) async throws -> TransferRequest {
        Logger.debug("📤 创建Oval Office转让请求")
        
        let transferData: [String: Any] = [
            "record_id": checkIn.id.uuidString,
            "record_type": "oval_office",
            "nfc_uuid": checkIn.nfcUuid ?? "",
            "building_id": "900",
            "building_name": "Oval Office",
            "asset_name": checkIn.assetName ?? "Unknown Asset",
            "description": checkIn.description,
            "image_url": checkIn.imageUrl ?? "",
            "from_user": fromUser
        ]
        
        guard let url = URL(string: "\(baseURL)/rest/v1/\(tableName)") else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: transferData)
        let request = createRequest(url: url, method: "POST", body: jsonData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "TransferManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let transfers = try decoder.decode([TransferRequest].self, from: data)
        guard let transfer = transfers.first else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No transfer returned"])
        }
        
        Logger.success("✅ 转让请求已创建: \(transfer.transferCode)")
        return transfer
    }
    
    // MARK: - 接收转让
    
    /// 完成转让（原子性操作）
    func completeTransfer(
        transferCode: String,
        scannedNfcUuid: String,
        toUser: String
    ) async throws -> TransferResult {
        Logger.debug("📥 尝试完成转让")
        Logger.debug("   Transfer Code: \(transferCode)")
        Logger.debug("   NFC UUID: \(scannedNfcUuid)")
        Logger.debug("   To User: \(toUser)")
        
        // 调用后端RPC函数执行原子性转让
        let params: [String: Any] = [
            "p_transfer_code": transferCode,
            "p_nfc_uuid": scannedNfcUuid,
            "p_to_user": toUser
        ]
        
        guard let url = URL(string: "\(baseURL)/rest/v1/rpc/complete_transfer") else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: params)
        let request = createRequest(url: url, method: "POST", body: jsonData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorStr = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.error("❌ RPC调用失败: \(errorStr)")
            throw NSError(domain: "TransferManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
        }
        
        let result = try JSONDecoder().decode(TransferResult.self, from: data)
        
        if result.success {
            Logger.success("✅ 转让完成成功")
        } else {
            Logger.error("❌ 转让失败: \(result.error ?? "Unknown error")")
        }
        
        return result
    }
    
    // MARK: - 查询转让
    
    /// 获取转让请求详情
    func getTransferRequest(transferCode: String) async throws -> TransferRequest {
        guard let url = URL(string: "\(baseURL)/rest/v1/\(tableName)?transfer_code=eq.\(transferCode)&select=*") else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let request = createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "TransferManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let transfers = try decoder.decode([TransferRequest].self, from: data)
        guard let transfer = transfers.first else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transfer not found"])
        }
        
        return transfer
    }
    
    /// 取消转让
    func cancelTransfer(transferCode: String) async throws {
        Logger.debug("🚫 取消转让: \(transferCode)")
        
        guard let url = URL(string: "\(baseURL)/rest/v1/\(tableName)?transfer_code=eq.\(transferCode)") else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let updateData: [String: Any] = ["status": "cancelled"]
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        let request = createRequest(url: url, method: "PATCH", body: jsonData)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "TransferManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
        }
        
        Logger.success("✅ 转让已取消")
    }
    
    /// 获取用户的待处理转让
    func getPendingTransfers(forUser: String) async throws -> [TransferRequest] {
        guard let url = URL(string: "\(baseURL)/rest/v1/\(tableName)?from_user=eq.\(forUser)&status=eq.pending&select=*&order=created_at.desc") else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let request = createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "TransferManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "TransferManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([TransferRequest].self, from: data)
    }
}

