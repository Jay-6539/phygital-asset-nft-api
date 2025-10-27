//
//  SupabaseManager.swift
//  Phygital Asset
//
//  Supabase云端数据库管理器
//

import Foundation
import UIKit

// MARK: - Supabase配置

struct SupabaseConfig {
    static let url: String = {
        if let configUrl = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
           !configUrl.isEmpty,
           !configUrl.contains("$") {  // 检查是否是未替换的变量
            return configUrl
        }
        // Fallback到硬编码值（在xcconfig未配置时使用）
        return "https://zcaznpjulvmaxjnhvqaw.supabase.co"
    }()
    
    static let anonKey: String = {
        if let configKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
           !configKey.isEmpty,
           !configKey.contains("$") {
            return configKey
        }
        // Fallback到硬编码值（在xcconfig未配置时使用）
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpjYXpucGp1bHZtYXhqbmh2cWF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzMzI2MjEsImV4cCI6MjA3NTkwODYyMX0.W6NzDWwkrq5tBDA929XXY6AOGgg6DVxM0GcRDq5WTL4"
    }()
}

// MARK: - 云端数据模型

struct CloudAsset: Codable {
    let id: String
    let gridX: Int
    let gridY: Int
    var name: String
    var imageData: String?  // Base64编码的图片数据
    var description: String
    var nfcUUID: String
    let createdAt: String
    let updatedAt: String?
    var latitude: Double?   // GPS纬度
    var longitude: Double?  // GPS经度
    
    enum CodingKeys: String, CodingKey {
        case id
        case gridX = "grid_x"
        case gridY = "grid_y"
        case name
        case imageData = "image_data"
        case description
        case nfcUUID = "nfc_uuid"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case latitude
        case longitude
    }
}

struct CloudInteraction: Codable {
    let id: String
    let assetId: String
    let username: String
    let interactionTime: String
    var imageData: String?  // Base64编码的图片数据
    let assetName: String
    let description: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case assetId = "asset_id"
        case username
        case interactionTime = "interaction_time"
        case imageData = "image_data"
        case assetName = "asset_name"
        case description
        case createdAt = "created_at"
    }
}

struct CloudUser: Codable {
    let id: String?
    let username: String
    let email: String?
    let password: String?
    let provider: String?  // "username", "apple", "facebook", "google"
    let providerId: String?
    let createdAt: String?
    let lastLogin: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case password
        case provider
        case providerId = "provider_id"
        case createdAt = "created_at"
        case lastLogin = "last_login"
    }
}

// MARK: - Supabase管理器

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    private let baseURL = SupabaseConfig.url
    private let apiKey = SupabaseConfig.anonKey
    
    init() {
        Logger.database("Supabase Manager initialized")
        Logger.network("Connected to: \(baseURL)")
    }
    
    // MARK: - 公开查询方法
    
    /// 公开的通用查询方法 - 用于Market等需要自定义查询的场景
    func query(endpoint: String) async throws -> Data {
        return try await makeRequest(endpoint: endpoint, method: "GET")
    }
    
    // MARK: - 网络请求辅助方法
    
    private func makeRequest(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/rest/v1/\(endpoint)") else {
            throw SupabaseError.invalidURL
        }
        
        let headers: [String: String] = [
            "apikey": apiKey,
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        ]
        
        do {
            // 使用统一网络管理器，自动支持重试、超时和错误处理
            return try await NetworkManager.shared.request(
                url: url,
                method: method,
                headers: headers,
                body: body,
                timeout: 30,
                retries: 3  // 用户数据写入重要，允许3次重试
            )
        } catch let error as NetworkError {
            // 转换为SupabaseError
            switch error {
            case .httpError(let code, let data):
                // 记录详细错误信息
                if let data = data, let errorString = String(data: data, encoding: .utf8) {
                    Logger.error("Supabase Error details: \(errorString)")
                }
                throw SupabaseError.httpError(code)
            case .invalidURL:
                throw SupabaseError.invalidURL
            case .timeout:
                throw SupabaseError.networkError("Request timeout")
            case .cancelled:
                throw SupabaseError.networkError("Request cancelled")
            default:
                throw SupabaseError.invalidResponse
            }
        }
    }
    
    // MARK: - Asset操作
    
    /// 保存Asset到云端
    func saveAsset(_ asset: AssetInfo, coordinate: GridCoordinate) async throws {
        // 先检查该位置是否已有Asset
        let existingAsset = try await findAsset(at: coordinate)
        
        // 如果已存在，使用现有的ID；否则使用新的ID
        let assetId = existingAsset?.id ?? asset.id.uuidString
        
        let cloudAsset = CloudAsset(
            id: assetId,  // 使用现有ID或新ID
            gridX: coordinate.x,
            gridY: coordinate.y,
            name: asset.name,
            imageData: asset.image?.jpegData(compressionQuality: 0.7)?.base64EncodedString(),
            description: asset.description,
            nfcUUID: asset.nfcUUID,
            createdAt: existingAsset?.createdAt ?? ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            latitude: asset.latitude,
            longitude: asset.longitude
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(cloudAsset)
        
        if existingAsset != nil {
            // 更新现有Asset
            Logger.info("Updating existing asset at (\(coordinate.x), \(coordinate.y))")
            guard let url = URL(string: "\(baseURL)/rest/v1/assets?id=eq.\(assetId)") else {
                throw SupabaseError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue(apiKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("return=representation", forHTTPHeaderField: "Prefer")
            request.httpBody = data
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                Logger.error("HTTP Error: \(httpResponse.statusCode)")
                if let errorString = String(data: responseData, encoding: .utf8) {
                    Logger.error("Error details: \(errorString)")
                }
                throw SupabaseError.httpError(httpResponse.statusCode)
            }
            
            Logger.success("Asset updated in cloud")
        } else {
            // 插入新Asset
            Logger.info("Inserting new asset at (\(coordinate.x), \(coordinate.y))")
            guard let url = URL(string: "\(baseURL)/rest/v1/assets") else {
                throw SupabaseError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(apiKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("return=representation", forHTTPHeaderField: "Prefer")
            request.httpBody = data
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                Logger.error("HTTP Error: \(httpResponse.statusCode)")
                if let errorString = String(data: responseData, encoding: .utf8) {
                    Logger.error("Error details: \(errorString)")
                }
                throw SupabaseError.httpError(httpResponse.statusCode)
            }
            
            Logger.success("Asset inserted to cloud")
        }
        
        // 保存所有interactions（使用正确的assetId）
        for interaction in asset.userInteractions {
            try await saveInteraction(interaction, assetId: assetId)
        }
        
        Logger.success("Asset saved to cloud: \(asset.name)")
    }
    
    /// 从云端加载所有Assets
    func loadAssets() async throws -> [AssetInfo] {
        let data = try await makeRequest(endpoint: "assets?select=*")
        
        let decoder = JSONDecoder()
        let cloudAssets = try decoder.decode([CloudAsset].self, from: data)
        
        var assets: [AssetInfo] = []
        
        for cloudAsset in cloudAssets {
            let coordinate = GridCoordinate(x: cloudAsset.gridX, y: cloudAsset.gridY)
            var assetInfo = AssetInfo(coordinate: coordinate, nfcUUID: cloudAsset.nfcUUID)
            assetInfo.name = cloudAsset.name
            assetInfo.description = cloudAsset.description
            assetInfo.latitude = cloudAsset.latitude
            assetInfo.longitude = cloudAsset.longitude
            
            // 解码图片
            if let imageDataString = cloudAsset.imageData,
               let imageData = Data(base64Encoded: imageDataString) {
                assetInfo.image = UIImage(data: imageData)
            }
            
            // 加载这个Asset的所有interactions
            let interactions = try await loadInteractions(assetId: cloudAsset.id)
            assetInfo.userInteractions = interactions
            
            assets.append(assetInfo)
        }
        
        Logger.success("Loaded \(assets.count) assets from cloud")
        return assets
    }
    
    /// 删除云端Asset
    func deleteAsset(assetId: String) async throws {
        // 先删除所有相关的interactions
        _ = try await makeRequest(
            endpoint: "interactions?asset_id=eq.\(assetId)",
            method: "DELETE"
        )
        
        // 再删除asset
        _ = try await makeRequest(
            endpoint: "assets?id=eq.\(assetId)",
            method: "DELETE"
        )
        
        Logger.success("Asset deleted from cloud: \(assetId)")
    }
    
    /// 根据坐标查找Asset
    func findAsset(at coordinate: GridCoordinate) async throws -> CloudAsset? {
        let data = try await makeRequest(
            endpoint: "assets?grid_x=eq.\(coordinate.x)&grid_y=eq.\(coordinate.y)&select=*"
        )
        
        let decoder = JSONDecoder()
        let cloudAssets = try decoder.decode([CloudAsset].self, from: data)
        
        return cloudAssets.first
    }
    
    // MARK: - Interaction操作
    
    /// 保存Interaction到云端
    func saveInteraction(_ interaction: UserInteraction, assetId: String) async throws {
        let cloudInteraction = CloudInteraction(
            id: interaction.id.uuidString,
            assetId: assetId,
            username: interaction.username,
            interactionTime: ISO8601DateFormatter().string(from: interaction.interactionTime),
            imageData: interaction.image?.jpegData(compressionQuality: 0.7)?.base64EncodedString(),
            assetName: interaction.assetName,
            description: interaction.description,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(cloudInteraction)
        
        _ = try await makeRequest(
            endpoint: "interactions",
            method: "POST",
            body: data
        )
        
        Logger.success("Interaction saved to cloud")
    }
    
    /// 加载Asset的所有Interactions
    func loadInteractions(assetId: String) async throws -> [UserInteraction] {
        let data = try await makeRequest(
            endpoint: "interactions?asset_id=eq.\(assetId)&select=*"
        )
        
        let decoder = JSONDecoder()
        let cloudInteractions = try decoder.decode([CloudInteraction].self, from: data)
        
        let dateFormatter = ISO8601DateFormatter()
        
        return cloudInteractions.map { cloudInteraction in
            var image: UIImage? = nil
            if let imageDataString = cloudInteraction.imageData,
               let imageData = Data(base64Encoded: imageDataString) {
                image = UIImage(data: imageData)
            }
            
            let interactionTime = dateFormatter.date(from: cloudInteraction.interactionTime) ?? Date()
            
            return UserInteraction(
                username: cloudInteraction.username,
                interactionTime: interactionTime,
                image: image,
                assetName: cloudInteraction.assetName,
                description: cloudInteraction.description
            )
        }
    }
    
    // MARK: - 批量操作
    
    /// 同步所有本地数据到云端
    func syncLocalToCloud(_ assets: [AssetInfo], coordinates: [GridCoordinate]) async throws {
        Logger.database("Starting sync to cloud...")
        
        for (asset, coordinate) in zip(assets, coordinates) {
            try await saveAsset(asset, coordinate: coordinate)
        }
        
        Logger.success("Sync completed: \(assets.count) assets uploaded")
    }
    
    /// 清空云端所有数据（慎用！）
    func clearAllCloudData() async throws {
        Logger.warning("Clearing all cloud data...")
        
        // 先删除所有interactions
        _ = try await makeRequest(endpoint: "interactions", method: "DELETE")
        
        // 再删除所有assets
        _ = try await makeRequest(endpoint: "assets", method: "DELETE")
        
        Logger.success("All cloud data cleared")
    }
    
    // MARK: - User Authentication
    
    /// 检查用户名是否存在
    func checkUserExists(username: String) async throws -> Bool {
        Logger.debug("Checking if user exists: \(username)")
        
        let data = try await makeRequest(
            endpoint: "users?username=eq.\(username)&select=id"
        )
        
        // 打印原始响应
        if let jsonString = String(data: data, encoding: .utf8) {
            Logger.network("Response: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        let users = try decoder.decode([CloudUser].self, from: data)
        
        let exists = !users.isEmpty
        Logger.success(exists ? "✅ User exists" : "✅ User does not exist")
        return exists
    }
    
    /// 用户名密码注册
    func registerUser(username: String, password: String, email: String? = nil) async throws -> CloudUser {
        Logger.auth("Registering user: \(username)")
        
        // 先检查用户是否存在
        if try await checkUserExists(username: username) {
            Logger.error("User already exists: \(username)")
            throw SupabaseError.userAlreadyExists
        }
        
        let user = CloudUser(
            id: nil,
            username: username,
            email: email,
            password: password,  // 注意：实际生产环境应该加密密码
            provider: "username",
            providerId: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            lastLogin: ISO8601DateFormatter().string(from: Date())
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(user)
        
        // 打印请求数据
        if let jsonString = String(data: data, encoding: .utf8) {
            Logger.network("Sending registration data:\n\(jsonString)")
        }
        
        let responseData = try await makeRequest(
            endpoint: "users",
            method: "POST",
            body: data
        )
        
        // 打印响应数据
        if let jsonString = String(data: responseData, encoding: .utf8) {
            Logger.network("Registration response:\n\(jsonString)")
        }
        
        let decoder = JSONDecoder()
        let createdUsers = try decoder.decode([CloudUser].self, from: responseData)
        
        guard let createdUser = createdUsers.first else {
            Logger.error("Failed to decode created user")
            throw SupabaseError.userCreationFailed
        }
        
        Logger.success("User registered successfully: \(username)")
        return createdUser
    }
    
    /// 用户名密码登录
    func loginUser(username: String, password: String) async throws -> CloudUser {
        Logger.auth("Attempting login for user: \(username)")
        
        let data = try await makeRequest(
            endpoint: "users?username=eq.\(username)&password=eq.\(password)&select=*"
        )
        
        // 打印响应
        if let jsonString = String(data: data, encoding: .utf8) {
            Logger.network("Login response: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        let users = try decoder.decode([CloudUser].self, from: data)
        
        guard let user = users.first else {
            Logger.error("Invalid credentials for user: \(username)")
            throw SupabaseError.invalidCredentials
        }
        
        // 更新最后登录时间
        try await updateLastLogin(username: username)
        
        Logger.success("User logged in successfully: \(username)")
        return user
    }
    
    /// 社交媒体登录/注册
    func socialLogin(username: String, email: String?, provider: String, providerId: String) async throws -> CloudUser {
        // 先尝试通过 providerId 查找用户
        let data = try await makeRequest(
            endpoint: "users?provider_id=eq.\(providerId)&select=*"
        )
        
        let decoder = JSONDecoder()
        let users = try decoder.decode([CloudUser].self, from: data)
        
        if let existingUser = users.first {
            // 用户存在，更新最后登录时间
            try await updateLastLogin(username: existingUser.username)
            Logger.success("Social user logged in: \(existingUser.username)")
            return existingUser
        } else {
            // 用户不存在，创建新用户
            let user = CloudUser(
                id: nil,
                username: username,
                email: email,
                password: nil,
                provider: provider,
                providerId: providerId,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                lastLogin: ISO8601DateFormatter().string(from: Date())
            )
            
            let encoder = JSONEncoder()
            let userData = try encoder.encode(user)
            
            let responseData = try await makeRequest(
                endpoint: "users",
                method: "POST",
                body: userData
            )
            
            let createdUsers = try decoder.decode([CloudUser].self, from: responseData)
            
            guard let createdUser = createdUsers.first else {
                throw SupabaseError.userCreationFailed
            }
            
            Logger.success("Social user registered: \(username)")
            return createdUser
        }
    }
    
    /// 更新最后登录时间
    private func updateLastLogin(username: String) async throws {
        let updateData: [String: Any] = [
            "last_login": ISO8601DateFormatter().string(from: Date())
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: updateData) else {
            throw SupabaseError.encodingError
        }
        
        _ = try await makeRequest(
            endpoint: "users?username=eq.\(username)",
            method: "PATCH",
            body: jsonData
        )
    }
    
    /// 更新用户email和社交账户信息
    func updateUserEmailAndSocial(username: String, email: String, provider: String? = nil, providerId: String? = nil) async throws {
        Logger.debug("Updating user email and social info for: \(username)")
        
        var updateData: [String: Any] = [
            "email": email
        ]
        
        // 如果有社交账户信息，也一起更新
        if let provider = provider {
            updateData["provider"] = provider
        }
        if let providerId = providerId {
            updateData["provider_id"] = providerId
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: updateData) else {
            throw SupabaseError.encodingError
        }
        
        _ = try await makeRequest(
            endpoint: "users?username=eq.\(username)",
            method: "PATCH",
            body: jsonData
        )
        
        Logger.success("User email and social info updated successfully")
    }
}

// MARK: - 错误类型

enum SupabaseError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case encodingError
    case userAlreadyExists
    case invalidCredentials
    case userCreationFailed
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .decodingError:
            return "Failed to decode data"
        case .encodingError:
            return "Failed to encode data"
        case .userAlreadyExists:
            return "Username already exists"
        case .invalidCredentials:
            return "Invalid username or password"
        case .networkError(let message):
            return "Network error: \(message)"
        case .userCreationFailed:
            return "Failed to create user"
        }
    }
}

