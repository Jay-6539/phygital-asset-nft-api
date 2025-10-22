//
//  OvalOfficeCheckInManager.swift
//  Treasure Hunt, Hong Kong Park
//
//  管理 Oval Office 的 Check-in 记录（使用 Supabase）
//

import Foundation
import UIKit

/// Oval Office 的 Check-in 记录
struct OvalOfficeCheckIn: Codable, Identifiable {
    let id: UUID
    let assetId: String
    let gridX: Int
    let gridY: Int
    let username: String
    let assetName: String?
    let description: String
    let imageUrl: String?
    let nfcUuid: String?
    let gpsLatitude: Double?
    let gpsLongitude: Double?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case assetId = "asset_id"
        case gridX = "grid_x"
        case gridY = "grid_y"
        case username
        case assetName = "asset_name"
        case description
        case imageUrl = "image_url"
        case nfcUuid = "nfc_uuid"
        case gpsLatitude = "gps_latitude"
        case gpsLongitude = "gps_longitude"
        case createdAt = "created_at"
    }
}

/// Oval Office Check-in 管理器
class OvalOfficeCheckInManager: ObservableObject {
    static let shared = OvalOfficeCheckInManager()
    
    private let baseURL = SupabaseConfig.url
    private let apiKey = SupabaseConfig.anonKey
    private let tableName = "oval_office_checkins"
    private let bucketName = "oval_office_images"
    
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
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    // MARK: - 保存 Check-in
    
    /// 保存 Oval Office 的 check-in 记录
    func saveCheckIn(
        assetId: String,
        gridX: Int,
        gridY: Int,
        username: String,
        assetName: String?,
        description: String,
        image: UIImage?,
        nfcUuid: String?,
        latitude: Double?,
        longitude: Double?
    ) async throws -> OvalOfficeCheckIn {
        Logger.database("💾 Saving Oval Office check-in for asset: \(assetId)")
        
        // 1. 上传图片（如果有）
        var imageUrl: String? = nil
        if let image = image {
            do {
                imageUrl = try await uploadImage(image, assetId: assetId)
                Logger.success("📸 Image uploaded: \(imageUrl ?? "")")
            } catch {
                Logger.warning("⚠️ Image upload failed, continuing without image: \(error.localizedDescription)")
                imageUrl = nil
            }
        }
        
        // 2. 创建 check-in 记录
        let checkIn: [String: Any] = [
            "asset_id": assetId,
            "grid_x": gridX,
            "grid_y": gridY,
            "username": username,
            "asset_name": assetName ?? "",
            "description": description,
            "image_url": imageUrl ?? "",
            "nfc_uuid": nfcUuid ?? "",
            "gps_latitude": latitude ?? NSNull(),
            "gps_longitude": longitude ?? NSNull()
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: checkIn)
        
        Logger.debug("📤 Request body: \(String(data: jsonData, encoding: .utf8) ?? "")")
        
        // 3. 发送到 Supabase
        guard let url = URL(string: "\(baseURL)/rest/v1/\(tableName)") else {
            throw NSError(domain: "InvalidURL", code: -1)
        }
        
        let request = createRequest(url: url, method: "POST", body: jsonData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: -1)
        }
        
        Logger.debug("📥 Response status code: \(httpResponse.statusCode)")
        Logger.debug("📥 Response body: \(String(data: data, encoding: .utf8) ?? "")")
        
        guard httpResponse.statusCode == 201 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.error("❌ Save failed: \(errorMessage)")
            throw NSError(domain: "SaveFailed", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: errorMessage
            ])
        }
        
        Logger.success("✅ Check-in saved successfully")
        
        // 解析返回的数据
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let checkIns = try decoder.decode([OvalOfficeCheckIn].self, from: data)
        
        guard let savedCheckIn = checkIns.first else {
            throw NSError(domain: "NoDataReturned", code: -1)
        }
        
        return savedCheckIn
    }
    
    // MARK: - 获取 Check-ins
    
    /// 获取特定 Asset 的所有 check-ins
    func getCheckIns(forAssetId assetId: String) async throws -> [OvalOfficeCheckIn] {
        Logger.database("📖 Fetching check-ins for asset: \(assetId)")
        
        guard let url = URL(string: "\(baseURL)/rest/v1/\(tableName)?asset_id=eq.\(assetId)&order=created_at.desc") else {
            throw NSError(domain: "InvalidURL", code: -1)
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: -1)
        }
        
        Logger.debug("📥 Response status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.error("❌ Fetch failed: \(errorMessage)")
            throw NSError(domain: "FetchFailed", code: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let checkIns = try decoder.decode([OvalOfficeCheckIn].self, from: data)
        
        Logger.success("✅ Fetched \(checkIns.count) check-ins")
        return checkIns
    }
    
    /// 获取特定 Grid 坐标的所有 check-ins
    func getCheckIns(forGridX gridX: Int, gridY: Int) async throws -> [OvalOfficeCheckIn] {
        Logger.database("📖 Fetching check-ins for grid: (\(gridX), \(gridY))")
        
        guard let url = URL(string: "\(baseURL)/rest/v1/\(tableName)?grid_x=eq.\(gridX)&grid_y=eq.\(gridY)&order=created_at.desc") else {
            throw NSError(domain: "InvalidURL", code: -1)
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: -1)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.error("❌ Fetch failed: \(errorMessage)")
            throw NSError(domain: "FetchFailed", code: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let checkIns = try decoder.decode([OvalOfficeCheckIn].self, from: data)
        
        Logger.success("✅ Fetched \(checkIns.count) check-ins for grid")
        return checkIns
    }
    
    /// 获取最近的 check-ins
    func getRecentCheckIns(limit: Int = 20) async throws -> [OvalOfficeCheckIn] {
        Logger.database("📖 Fetching recent check-ins (limit: \(limit))")
        
        guard let url = URL(string: "\(baseURL)/rest/v1/\(tableName)?order=created_at.desc&limit=\(limit)") else {
            throw NSError(domain: "InvalidURL", code: -1)
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: -1)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.error("❌ Fetch failed: \(errorMessage)")
            throw NSError(domain: "FetchFailed", code: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let checkIns = try decoder.decode([OvalOfficeCheckIn].self, from: data)
        
        Logger.success("✅ Fetched \(checkIns.count) recent check-ins")
        return checkIns
    }
    
    /// 根据NFC UUID获取历史记录
    func getCheckInsByNFC(nfcUuid: String) async throws -> [OvalOfficeCheckIn] {
        Logger.database("📡 开始从 oval_office_checkins 获取NFC历史记录")
        Logger.debug("   NFC UUID: \(nfcUuid)")
        
        let urlString = "\(baseURL)/rest/v1/\(tableName)?nfc_uuid=eq.\(nfcUuid)&order=created_at.desc&select=*"
        Logger.debug("   Request URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            Logger.error("❌ 无效的URL: \(urlString)")
            throw NSError(domain: "OvalOfficeCheckInManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let request = createRequest(url: url)
        Logger.debug("   发送请求到Supabase...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 打印响应状态
        if let httpResponse = response as? HTTPURLResponse {
            Logger.debug("   响应状态码: \(httpResponse.statusCode)")
        }
        
        // 打印响应数据
        if let responseString = String(data: data, encoding: .utf8) {
            Logger.debug("   响应数据: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            Logger.error("❌ 请求失败，状态码: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw NSError(domain: "OvalOfficeCheckInManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to fetch check-ins by NFC"])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let checkIns = try decoder.decode([OvalOfficeCheckIn].self, from: data)
        Logger.success("✅ 成功获取 \(checkIns.count) 条Oval Office NFC历史记录")
        
        // 打印每条记录的摘要
        for (index, checkIn) in checkIns.enumerated() {
            Logger.debug("   记录 \(index + 1): \(checkIn.username) - \(checkIn.assetName ?? "无名称") - \(checkIn.description)")
        }
        
        return checkIns
    }
    
    /// 获取某个用户的所有 check-in 记录
    func fetchUserCheckIns(username: String) async throws -> [OvalOfficeCheckIn] {
        Logger.database("📖 Fetching check-ins for user: \(username)")
        
        guard let url = URL(string: "\(baseURL)/rest/v1/\(tableName)?username=eq.\(username)&order=created_at.desc") else {
            throw NSError(domain: "InvalidURL", code: -1)
        }
        
        let request = createRequest(url: url)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "InvalidResponse", code: -1)
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                Logger.error("❌ Fetch failed: \(errorMessage)")
                throw NSError(domain: "FetchFailed", code: httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let checkIns = try decoder.decode([OvalOfficeCheckIn].self, from: data)
            
            Logger.success("✅ Fetched \(checkIns.count) check-ins for user: \(username)")
            return checkIns
        } catch {
            Logger.error("❌ Failed to fetch user check-ins: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - 图片管理
    
    /// 上传图片到 Supabase Storage
    private func uploadImage(_ image: UIImage, assetId: String) async throws -> String {
        Logger.database("📸 Uploading image for asset: \(assetId)")
        
        // 压缩图片
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImageCompressionFailed", code: -1)
        }
        
        Logger.debug("   Image size: \(imageData.count / 1024) KB")
        
        // 生成唯一文件名
        let fileName = "\(assetId)_\(UUID().uuidString).jpg"
        let filePath = "\(assetId)/\(fileName)"
        
        // 创建上传 URL
        guard let url = URL(string: "\(baseURL)/storage/v1/object/\(bucketName)/\(filePath)") else {
            throw NSError(domain: "InvalidURL", code: -1)
        }
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        Logger.debug("📤 Uploading to: \(url.absoluteString)")
        
        // 上传
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: -1)
        }
        
        Logger.debug("📥 Upload response status: \(httpResponse.statusCode)")
        Logger.debug("📥 Upload response body: \(String(data: responseData, encoding: .utf8) ?? "")")
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            Logger.error("❌ Upload failed: \(errorMessage)")
            throw NSError(domain: "UploadFailed", code: httpResponse.statusCode)
        }
        
        // 构造公开访问 URL
        let publicURL = "\(baseURL)/storage/v1/object/public/\(bucketName)/\(filePath)"
        Logger.success("✅ Image uploaded: \(publicURL)")
        
        return publicURL
    }
    
    /// 从 Supabase Storage 下载图片
    func downloadImage(from urlString: String?) async throws -> UIImage? {
        guard let urlString = urlString, !urlString.isEmpty else {
            Logger.debug("⚠️ No image URL provided")
            return nil
        }
        
        Logger.debug("📥 Downloading image from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            Logger.error("❌ Invalid image URL: \(urlString)")
            return nil
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: -1)
        }
        
        Logger.debug("📥 Download response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            Logger.error("❌ Download failed with status: \(httpResponse.statusCode)")
            return nil
        }
        
        guard let image = UIImage(data: data) else {
            Logger.error("❌ Failed to create image from data")
            return nil
        }
        
        Logger.success("✅ Image downloaded successfully")
        return image
    }
}

