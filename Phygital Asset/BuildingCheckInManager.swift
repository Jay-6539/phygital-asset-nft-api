//
//  BuildingCheckInManager.swift
//  Phygital Asset
//
//  管理历史建筑的 Check-in 记录（使用 Supabase）
//

import Foundation
import UIKit

/// 历史建筑的 Check-in 记录
struct BuildingCheckIn: Codable, Identifiable {
    let id: UUID
    let buildingId: String
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
        case buildingId = "building_id"
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

/// 历史建筑 Check-in 管理器
class BuildingCheckInManager: ObservableObject {
    static let shared = BuildingCheckInManager()
    
    private let baseURL = SupabaseConfig.url
    private let apiKey = SupabaseConfig.anonKey
    private let tableName = "threads"
    private let bucketName = "asset_checkin_images"
    
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
    
    /// 保存历史建筑的 check-in 记录
    func saveCheckIn(
        buildingId: String,
        username: String,
        assetName: String?,
        description: String,
        image: UIImage?,
        nfcUuid: String?,
        latitude: Double?,
        longitude: Double?
    ) async throws -> BuildingCheckIn {
        Logger.database("Saving building check-in for: \(buildingId)")
        
        // 1. 上传图片（如果有）
        var imageUrl: String? = nil
        if let image = image {
            do {
                imageUrl = try await uploadImage(image, buildingId: buildingId)
            } catch {
                // 图片上传失败，继续保存文字数据
                Logger.warning("⚠️ Image upload failed, continuing without image: \(error.localizedDescription)")
                imageUrl = nil
            }
        }
        
        // 2. 创建 check-in 记录
        var checkIn: [String: Any] = [
            "building_id": buildingId,
            "username": username,
            "asset_name": assetName ?? "",
            "description": description,
            "image_url": imageUrl ?? "",
            "gps_latitude": latitude ?? 0,
            "gps_longitude": longitude ?? 0
        ]
        
        // 只有当 nfcUuid 不为 nil 且不为空时才添加
        if let uuid = nfcUuid, !uuid.isEmpty {
            checkIn["nfc_uuid"] = uuid
            Logger.debug("✅ NFC UUID will be saved: \(uuid)")
        } else {
            Logger.warning("⚠️ NFC UUID is nil or empty, will not be saved")
        }
        
        // 3. 插入到 Supabase
        let urlString = "\(baseURL)/rest/v1/\(tableName)?select=*"
        Logger.debug("Save URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            Logger.error("Invalid save URL: \(urlString)")
            throw NSError(domain: "BuildingCheckInManager", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: checkIn)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            Logger.debug("Request body: \(jsonString)")
        }
        
        var request = createRequest(url: url, method: "POST", body: jsonData)
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                Logger.debug("Save response status: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    Logger.debug("Save response body: \(responseString)")
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorMessage = "HTTP \(httpResponse.statusCode): Failed to save check-in"
                    Logger.error(errorMessage)
                    throw NSError(domain: "BuildingCheckInManager", code: httpResponse.statusCode,
                                 userInfo: [NSLocalizedDescriptionKey: errorMessage])
                }
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let savedCheckIns = try decoder.decode([BuildingCheckIn].self, from: data)
            
            guard let savedCheckIn = savedCheckIns.first else {
                Logger.error("No data returned from save operation")
                throw NSError(domain: "BuildingCheckInManager", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "No data returned"])
            }
            
            Logger.success("Check-in saved successfully with ID: \(savedCheckIn.id)")
            
            // 🎨 自动铸造NFT（后台异步，用户无感）
            await NFTManager.shared.mintNFTForThread(
                threadId: savedCheckIn.id,
                username: savedCheckIn.username,
                buildingId: savedCheckIn.buildingId,
                description: savedCheckIn.description,
                imageUrl: savedCheckIn.imageUrl
            )
            
            // ⭐ 奖励XP和Echo
            await awardThreadCreationRewards(username: savedCheckIn.username, buildingId: savedCheckIn.buildingId)
            
            return savedCheckIn
        } catch let decodingError as DecodingError {
            Logger.error("Save decoding error: \(decodingError)")
            throw decodingError
        } catch {
            Logger.error("Save network error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - 读取 Check-in
    
    /// 获取某个建筑的所有 check-in 记录
    func getCheckIns(for buildingId: String) async throws -> [BuildingCheckIn] {
        Logger.database("Fetching check-ins for building: \(buildingId)")
        
        let urlString = "\(baseURL)/rest/v1/\(tableName)?building_id=eq.\(buildingId)&order=created_at.desc&select=*"
        Logger.debug("Request URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            Logger.error("Invalid URL: \(urlString)")
            throw NSError(domain: "BuildingCheckInManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let request = createRequest(url: url, method: "GET")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                Logger.debug("Response status code: \(httpResponse.statusCode)")
                
                // 打印响应内容用于调试
                if let responseString = String(data: data, encoding: .utf8) {
                    Logger.debug("Response body: \(responseString)")
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorMessage = "HTTP \(httpResponse.statusCode): Failed to fetch check-ins"
                    Logger.error(errorMessage)
                    throw NSError(domain: "BuildingCheckInManager", code: httpResponse.statusCode,
                                 userInfo: [NSLocalizedDescriptionKey: errorMessage])
                }
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let checkIns = try decoder.decode([BuildingCheckIn].self, from: data)
            Logger.success("Fetched \(checkIns.count) check-ins for building: \(buildingId)")
            
            return checkIns
        } catch let decodingError as DecodingError {
            Logger.error("Decoding error: \(decodingError)")
            throw decodingError
        } catch {
            Logger.error("Network error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 获取最近的 check-in 记录
    func getRecentCheckIns(limit: Int = 20) async throws -> [BuildingCheckIn] {
        Logger.database("Fetching recent check-ins (limit: \(limit))")
        
        guard let url = URL(string: "\(baseURL)/rest/v1/\(tableName)?order=created_at.desc&limit=\(limit)&select=*") else {
            throw NSError(domain: "BuildingCheckInManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let request = createRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BuildingCheckInManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to fetch check-ins"])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let checkIns = try decoder.decode([BuildingCheckIn].self, from: data)
        Logger.success("Fetched \(checkIns.count) recent check-ins")
        
        return checkIns
    }
    
    /// 检查NFC UUID是否已有历史记录
    func checkNFCExists(nfcUuid: String) async throws -> Bool {
        Logger.database("Checking if NFC UUID exists: \(nfcUuid)")
        
        let urlString = "\(baseURL)/rest/v1/\(tableName)?nfc_uuid=eq.\(nfcUuid)&select=id&limit=1"
        Logger.debug("Request URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            Logger.error("Invalid URL: \(urlString)")
            throw NSError(domain: "BuildingCheckInManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let request = createRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BuildingCheckInManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to check NFC existence"])
        }
        
        let decoder = JSONDecoder()
        let checkIns = try decoder.decode([BuildingCheckIn].self, from: data)
        let exists = !checkIns.isEmpty
        
        Logger.debug("NFC UUID \(nfcUuid) exists: \(exists)")
        return exists
    }
    
    /// 根据NFC UUID获取历史记录
    func getCheckInsByNFC(nfcUuid: String) async throws -> [BuildingCheckIn] {
        Logger.database("📡 开始获取NFC历史记录")
        Logger.debug("   NFC UUID: \(nfcUuid)")
        
        let urlString = "\(baseURL)/rest/v1/\(tableName)?nfc_uuid=eq.\(nfcUuid)&order=created_at.desc&select=*"
        Logger.debug("   Request URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            Logger.error("❌ 无效的URL: \(urlString)")
            throw NSError(domain: "BuildingCheckInManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let request = createRequest(url: url, method: "GET")
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
            throw NSError(domain: "BuildingCheckInManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to fetch check-ins by NFC"])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let checkIns = try decoder.decode([BuildingCheckIn].self, from: data)
        Logger.success("✅ 成功获取 \(checkIns.count) 条NFC历史记录")
        
        // 打印每条记录的摘要
        for (index, checkIn) in checkIns.enumerated() {
            Logger.debug("   记录 \(index + 1): \(checkIn.username) - \(checkIn.assetName ?? "无名称") - \(checkIn.description)")
        }
        
        return checkIns
    }
    
    /// 获取NFC的第一条记录（最早的注册记录，包含GPS信息）
    func getFirstCheckInByNFC(nfcUuid: String) async throws -> BuildingCheckIn? {
        Logger.database("📡 获取NFC的第一条注册记录")
        Logger.debug("   NFC UUID: \(nfcUuid)")
        
        // 按创建时间升序排列，获取第一条（最早的记录）
        let urlString = "\(baseURL)/rest/v1/\(tableName)?nfc_uuid=eq.\(nfcUuid)&order=created_at.asc&limit=1&select=*"
        Logger.debug("   Request URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            Logger.error("❌ 无效的URL: \(urlString)")
            throw NSError(domain: "BuildingCheckInManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let request = createRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            Logger.error("❌ 请求失败，状态码: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw NSError(domain: "BuildingCheckInManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to fetch first check-in by NFC"])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let checkIns = try decoder.decode([BuildingCheckIn].self, from: data)
        
        if let firstCheckIn = checkIns.first {
            Logger.success("✅ 找到NFC的第一条记录")
            Logger.debug("   GPS: (\(firstCheckIn.gpsLatitude ?? 0), \(firstCheckIn.gpsLongitude ?? 0))")
            return firstCheckIn
        } else {
            Logger.warning("⚠️ 未找到NFC的第一条记录")
            return nil
        }
    }
    
    /// 获取某个用户的所有 check-in 记录
    func fetchUserCheckIns(username: String) async throws -> [BuildingCheckIn] {
        Logger.database("Fetching check-ins for user: \(username)")
        
        let urlString = "\(baseURL)/rest/v1/\(tableName)?username=eq.\(username)&order=created_at.desc&select=*"
        Logger.debug("Request URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            Logger.error("Invalid URL: \(urlString)")
            throw NSError(domain: "BuildingCheckInManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let request = createRequest(url: url, method: "GET")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                Logger.debug("Response status code: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorMessage = "HTTP \(httpResponse.statusCode): Failed to fetch user check-ins"
                    Logger.error(errorMessage)
                    throw NSError(domain: "BuildingCheckInManager", code: httpResponse.statusCode,
                                 userInfo: [NSLocalizedDescriptionKey: errorMessage])
                }
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let checkIns = try decoder.decode([BuildingCheckIn].self, from: data)
            Logger.success("Fetched \(checkIns.count) check-ins for user: \(username)")
            
            return checkIns
        } catch let decodingError as DecodingError {
            Logger.error("Decoding error: \(decodingError)")
            throw decodingError
        } catch {
            Logger.error("Network error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - 图片上传
    
    /// 上传图片到 Supabase Storage
    private func uploadImage(_ image: UIImage, buildingId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            Logger.error("Failed to convert image to JPEG data")
            throw NSError(domain: "BuildingCheckInManager", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        Logger.debug("Image data size: \(imageData.count) bytes")
        
        // 生成唯一文件名
        let fileName = "\(buildingId)_\(UUID().uuidString).jpg"
        let filePath = "\(buildingId)/\(fileName)"
        
        Logger.database("Uploading image: \(filePath)")
        
        // 上传到 Supabase Storage
        let urlString = "\(baseURL)/storage/v1/object/\(bucketName)/\(filePath)"
        Logger.debug("Upload URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            Logger.error("Invalid upload URL: \(urlString)")
            throw NSError(domain: "BuildingCheckInManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                Logger.debug("Upload response status: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    Logger.debug("Upload response body: \(responseString)")
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorMessage = "HTTP \(httpResponse.statusCode): Failed to upload image"
                    Logger.error(errorMessage)
                    throw NSError(domain: "BuildingCheckInManager", code: httpResponse.statusCode,
                                 userInfo: [NSLocalizedDescriptionKey: errorMessage])
                }
            }
            
            // 构建公开 URL
            let publicURL = "\(baseURL)/storage/v1/object/public/\(bucketName)/\(filePath)"
            
            Logger.success("Image uploaded: \(publicURL)")
            return publicURL
        } catch {
            Logger.error("Upload error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - 奖励系统
    
    /// 奖励Thread创建
    private func awardThreadCreationRewards(username: String, buildingId: String) async {
        // ⭐ 奖励XP
        XPManager.shared.awardXP(.threadCreated, for: username)
        
        // 💰 奖励Echo（每次创建Thread获得5 Echo）
        EchoManager.shared.addEcho(5, for: username, reason: "Thread created")
        
        // 🏢 检查是否是新建筑发现
        await checkForNewBuildingDiscovery(username: username, buildingId: buildingId)
        
        Logger.success("🎁 Rewards awarded to @\(username): +10 XP, +5 Echo")
    }
    
    /// 检查是否是新建筑发现
    private func checkForNewBuildingDiscovery(username: String, buildingId: String) async {
        do {
            // 检查这个用户是否之前在这个建筑创建过Thread
            let existingCheckIns = try await getCheckIns(for: buildingId)
            let userCheckIns = existingCheckIns.filter { $0.username == username }
            
            // 如果这是用户在这个建筑的第一个Thread，奖励发现新建筑
            if userCheckIns.count == 1 {
                XPManager.shared.awardXP(.buildingDiscovered, for: username)
                Logger.success("🏢 @\(username) discovered new building: \(buildingId) (+50 XP)")
            }
        } catch {
            Logger.debug("⚠️ Could not check building discovery: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 下载图片
    
    /// 从 URL 下载图片
    func downloadImage(from urlString: String) async throws -> UIImage? {
        Logger.debug("🖼️ Downloading image from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            Logger.error("Invalid image URL: \(urlString)")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                Logger.debug("Image download response status: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    Logger.error("Failed to download image, status: \(httpResponse.statusCode)")
                    return nil
                }
            }
            
            Logger.debug("Image data size: \(data.count) bytes")
            
            guard let image = UIImage(data: data) else {
                Logger.error("Failed to create UIImage from data")
                return nil
            }
            
            Logger.success("✅ Image downloaded successfully")
            return image
        } catch {
            Logger.error("Download error: \(error.localizedDescription)")
            throw error
        }
    }
}

