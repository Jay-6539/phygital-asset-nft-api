//
//  PersistenceManager.swift
//  Treasure Hunt, Hong Kong Park
//
//  数据持久化存储管理器（使用Codable + FileManager）
//

import Foundation
import UIKit

// MARK: - 可持久化的数据模型

struct PersistableAsset: Codable {
    let id: UUID
    let gridX: Int
    let gridY: Int
    var name: String
    var imageData: Data?
    var description: String
    var nfcUUID: String
    let createdAt: Date
    var interactions: [PersistableInteraction]
    var latitude: Double?  // GPS纬度
    var longitude: Double? // GPS经度
    
    // 便捷方法：从AssetInfo转换
    init(from assetInfo: AssetInfo, coordinate: GridCoordinate, createdAt: Date = Date()) {
        self.id = assetInfo.id
        self.gridX = coordinate.x
        self.gridY = coordinate.y
        self.name = assetInfo.name
        self.imageData = assetInfo.image?.jpegData(compressionQuality: 0.8)
        self.description = assetInfo.description
        self.nfcUUID = assetInfo.nfcUUID
        self.createdAt = createdAt
        self.interactions = assetInfo.userInteractions.map { PersistableInteraction(from: $0) }
        self.latitude = assetInfo.latitude
        self.longitude = assetInfo.longitude
    }
    
    // 转换回AssetInfo
    func toAssetInfo() -> AssetInfo {
        let gridCoord = GridCoordinate(x: gridX, y: gridY)
        var assetInfo = AssetInfo(coordinate: gridCoord, nfcUUID: nfcUUID)
        assetInfo.name = name
        assetInfo.image = imageData.flatMap { UIImage(data: $0) }
        assetInfo.description = description
        assetInfo.userInteractions = interactions.map { $0.toUserInteraction() }
        assetInfo.latitude = latitude
        assetInfo.longitude = longitude
        return assetInfo
    }
}

struct PersistableInteraction: Codable {
    let id: UUID
    let username: String
    let interactionTime: Date
    var imageData: Data?
    let assetName: String
    let description: String
    
    // 从UserInteraction转换
    init(from interaction: UserInteraction) {
        self.id = interaction.id
        self.username = interaction.username
        self.interactionTime = interaction.interactionTime
        self.imageData = interaction.image?.jpegData(compressionQuality: 0.8)
        self.assetName = interaction.assetName
        self.description = interaction.description
    }
    
    // 转换回UserInteraction
    func toUserInteraction() -> UserInteraction {
        let image = imageData.flatMap { UIImage(data: $0) }
        return UserInteraction(
            username: username,
            interactionTime: interactionTime,
            image: image,
            assetName: assetName,
            description: description
        )
    }
}

// MARK: - 持久化管理器

class PersistenceManager: ObservableObject {
    static let shared = PersistenceManager()
    
    private let fileManager = FileManager.default
    private let fileName = "TreasureHuntAssets.json"
    private let supabaseManager = SupabaseManager.shared
    
    // 是否启用云端同步
    @Published var cloudSyncEnabled: Bool = true
    
    private var fileURL: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    init() {
        Logger.database("Persistence Manager initialized")
        Logger.database("Data file location: \(fileURL.path)")
        Logger.database("Cloud sync: \(cloudSyncEnabled ? "Enabled" : "Disabled")")
    }
    
    // MARK: - 保存数据
    
    /// 保存所有Asset到磁盘和云端
    func saveAssets(_ assets: [AssetInfo], coordinates: [GridCoordinate]) {
        // 1. 本地保存
        saveAssetsLocally(assets, coordinates: coordinates)
        
        // 2. 云端同步（异步）
        if cloudSyncEnabled {
            Task {
                await saveAssetsToCloud(assets, coordinates: coordinates)
            }
        }
    }
    
    /// 保存到本地磁盘
    private func saveAssetsLocally(_ assets: [AssetInfo], coordinates: [GridCoordinate]) {
        // 转换为可持久化格式
        let persistableAssets = zip(assets, coordinates).map { asset, coordinate in
            PersistableAsset(from: asset, coordinate: coordinate)
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(persistableAssets)
            try data.write(to: fileURL, options: .atomic)
            Logger.success("Saved \(persistableAssets.count) assets to local disk")
            Logger.debug("   File size: \(data.count / 1024) KB")
        } catch {
            Logger.error("Failed to save assets locally: \(error.localizedDescription)")
        }
    }
    
    /// 保存到云端
    private func saveAssetsToCloud(_ assets: [AssetInfo], coordinates: [GridCoordinate]) async {
        do {
            try await supabaseManager.syncLocalToCloud(assets, coordinates: coordinates)
            Logger.success("Assets synced to cloud")
        } catch {
            Logger.error("Failed to sync to cloud: \(error.localizedDescription)")
        }
    }
    
    /// 快速保存单个Asset
    func quickSaveAsset(_ asset: AssetInfo, coordinate: GridCoordinate) {
        var allAssets = loadAssetsLocally()
        
        // 查找是否已存在（根据坐标）
        if let index = allAssets.firstIndex(where: { 
            $0.coordinate.x == coordinate.x && $0.coordinate.y == coordinate.y 
        }) {
            // 更新现有Asset
            allAssets[index] = asset
            Logger.database("Updating existing asset at (\(coordinate.x), \(coordinate.y))")
        } else {
            // 添加新Asset
            allAssets.append(asset)
            Logger.database("Adding new asset at (\(coordinate.x), \(coordinate.y))")
        }
        
        // 保存到本地和云端
        saveAssets(allAssets, coordinates: allAssets.map { getCoordinate(from: $0) })
    }
    
    // MARK: - 加载数据
    
    /// 从云端或本地磁盘加载所有Asset（优先云端）
    func loadAssets() -> [AssetInfo] {
        // 如果启用云端同步，优先从云端加载
        if cloudSyncEnabled {
            // 注意：这是同步方法，但我们需要异步加载云端数据
            // 建议使用异步版本 loadAssetsAsync()
            return loadAssetsLocally()
        } else {
            return loadAssetsLocally()
        }
    }
    
    /// 异步加载Assets（推荐使用）
    func loadAssetsAsync() async -> [AssetInfo] {
        if cloudSyncEnabled {
            do {
                // 1. 从云端加载
                let cloudAssets = try await supabaseManager.loadAssets()
                Logger.success("Loaded \(cloudAssets.count) assets from cloud")
                
                // 2. 同时更新本地缓存
                let coordinates = cloudAssets.map { $0.coordinate }
                saveAssetsLocally(cloudAssets, coordinates: coordinates)
                
                return cloudAssets
            } catch {
                Logger.error("Failed to load from cloud: \(error.localizedDescription)")
                Logger.database("Falling back to local storage...")
                return loadAssetsLocally()
            }
        } else {
            return loadAssetsLocally()
        }
    }
    
    /// 从本地磁盘加载所有Asset
    private func loadAssetsLocally() -> [AssetInfo] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            Logger.database("No saved data found locally, starting fresh")
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let persistableAssets = try decoder.decode([PersistableAsset].self, from: data)
            
            let assets = persistableAssets.map { $0.toAssetInfo() }
            Logger.success("Loaded \(assets.count) assets from local disk")
            Logger.debug("   File size: \(data.count / 1024) KB")
            
            // 打印每个Asset的详情
            for (index, asset) in assets.enumerated() {
                Logger.debug("   Asset \(index + 1): \(asset.name) - \(asset.userInteractions.count) interactions")
            }
            
            return assets
        } catch {
            Logger.error("Failed to load assets from local: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - 删除数据
    
    /// 删除Asset（本地和云端）
    func deleteAsset(at coordinate: GridCoordinate) {
        var allAssets = loadAssetsLocally()
        
        // 找到要删除的Asset ID
        if let assetToDelete = allAssets.first(where: { 
            $0.coordinate.x == coordinate.x && $0.coordinate.y == coordinate.y 
        }) {
            // 从云端删除
            if cloudSyncEnabled {
                Task {
                    do {
                        try await supabaseManager.deleteAsset(assetId: assetToDelete.id.uuidString)
                        Logger.success("Asset deleted from cloud")
                    } catch {
                        Logger.error("Failed to delete from cloud: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // 从本地删除
        allAssets.removeAll { 
            $0.coordinate.x == coordinate.x && $0.coordinate.y == coordinate.y 
        }
        saveAssetsLocally(allAssets, coordinates: allAssets.map { getCoordinate(from: $0) })
        Logger.database("Deleted asset at (\(coordinate.x), \(coordinate.y))")
    }
    
    /// 清空所有数据（本地和云端）
    func clearAllData() {
        // 清空本地数据
        do {
            try fileManager.removeItem(at: fileURL)
            Logger.database("All local data cleared")
        } catch {
            Logger.error("Failed to clear local data: \(error.localizedDescription)")
        }
        
        // 清空云端数据
        if cloudSyncEnabled {
            Task {
                do {
                    try await supabaseManager.clearAllCloudData()
                    Logger.database("All cloud data cleared")
                } catch {
                    Logger.error("Failed to clear cloud data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func getCoordinate(from asset: AssetInfo) -> GridCoordinate {
        return asset.coordinate
    }
    
    /// 获取数据文件信息
    func getFileInfo() -> String {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return "No data file exists"
        }
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            let modificationDate = attributes[.modificationDate] as? Date ?? Date()
            
            return """
            📁 File: \(fileName)
            📍 Location: \(fileURL.path)
            💾 Size: \(fileSize / 1024) KB
            🕐 Modified: \(modificationDate)
            ☁️ Cloud sync: \(cloudSyncEnabled ? "Enabled" : "Disabled")
            """
        } catch {
            return "Error getting file info: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 云端同步控制
    
    /// 手动触发云端同步
    func manualSync() async throws {
        guard cloudSyncEnabled else {
            Logger.warning("Cloud sync is disabled")
            return
        }
        
        let localAssets = loadAssetsLocally()
        let coordinates = localAssets.map { $0.coordinate }
        
        Logger.info("Starting manual sync...")
        await saveAssetsToCloud(localAssets, coordinates: coordinates)
        Logger.success("Manual sync completed")
    }
    
    /// 从云端强制刷新数据
    func forceRefreshFromCloud() async throws -> [AssetInfo] {
        guard cloudSyncEnabled else {
            throw SupabaseError.invalidResponse
        }
        
        Logger.info("Force refreshing from cloud...")
        let cloudAssets = try await supabaseManager.loadAssets()
        
        // 更新本地缓存
        let coordinates = cloudAssets.map { $0.coordinate }
        saveAssetsLocally(cloudAssets, coordinates: coordinates)
        
        Logger.success("Refreshed \(cloudAssets.count) assets from cloud")
        return cloudAssets
    }
    
    /// 检查云端连接状态
    func checkCloudConnection() async -> Bool {
        do {
            _ = try await supabaseManager.loadAssets()
            Logger.success("Cloud connection is OK")
            return true
        } catch {
            Logger.error("Cloud connection failed: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - 辅助方法
// AssetInfo已经包含coordinate属性，无需扩展

