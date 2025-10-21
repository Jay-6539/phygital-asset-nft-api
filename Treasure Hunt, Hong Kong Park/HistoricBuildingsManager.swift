//
//  HistoricBuildingsManager.swift
//  Treasure Hunt, Hong Kong Park
//
//  历史建筑数据管理器 - 访问6676条香港历史建筑数据
//

import Foundation
import CoreLocation

// MARK: - Supabase配置（历史建筑数据库）

struct HistoricBuildingsConfig {
    static let url: String = {
        if let configUrl = Bundle.main.infoDictionary?["HISTORIC_BUILDINGS_URL"] as? String,
           !configUrl.isEmpty,
           !configUrl.contains("$") {
            return configUrl
        }
        // Fallback到硬编码值（在xcconfig未配置时使用）
        return "https://spplmgbpsavuibjtszkl.supabase.co"
    }()
    
    static let anonKey: String = {
        if let configKey = Bundle.main.infoDictionary?["HISTORIC_BUILDINGS_KEY"] as? String,
           !configKey.isEmpty,
           !configKey.contains("$") {
            return configKey
        }
        // Fallback到硬编码值（在xcconfig未配置时使用）
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwcGxtZ2Jwc2F2dWlianRzemtsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzNDk0NDQsImV4cCI6MjA3NTkyNTQ0NH0._KVA9tLaeHkNj1ZN2_FRAgMkpozpndHVxKr4P5EO95M"
    }()
}

// MARK: - 历史建筑数据模型

struct HistoricBuilding: Codable, Identifiable {
    let name: Int   // 序号
    let district: String
    let address: String
    let coordinates: String  // 原始坐标字符串 "longitude,latitude,altitude"
    
    // Identifiable协议要求的id属性（使用Name作为ID）
    var id: String {
        return String(name)
    }
    
    // 计算属性
    var latitude: Double {
        let parts = coordinates.split(separator: ",")
        if parts.count >= 2, let lat = Double(parts[1]) {
            return lat
        }
        return 0.0
    }
    
    var longitude: Double {
        let parts = coordinates.split(separator: ",")
        if parts.count >= 1, let lon = Double(parts[0]) {
            return lon
        }
        return 0.0
    }
    
    var location: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var displayName: String {
        // 从地址中提取建筑名称
        return address.components(separatedBy: ",").first ?? address
    }
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case district = "District"
        case address = "Address"
        case coordinates = "Coordinates"
    }
}

// MARK: - 历史建筑管理器

class HistoricBuildingsManager: ObservableObject {
    static let shared = HistoricBuildingsManager()
    
    private let baseURL = HistoricBuildingsConfig.url
    private let apiKey = HistoricBuildingsConfig.anonKey
    
    @Published var buildings: [HistoricBuilding] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init() {
        Logger.database("Historic Buildings Manager initialized")
        Logger.database("Connected to: \(baseURL)")
    }
    
    // MARK: - 基础查询
    
    /// 加载历史建筑（限制200条以保证性能，支持未来8000+数据）
    func loadAllBuildings() async throws -> [HistoricBuilding] {
        Logger.database("Loading historic buildings (limited to 200 for optimal performance)...")
        
        // 限制为200条，保证流畅性能
        // 按Name降序排序，确保900（Oval Office）在前200条中
        let endpoint = "Hong%20Kong%20Heritage%20Buildings_duplicate?select=*&order=Name.desc&limit=200"
        let data = try await makeRequest(endpoint: endpoint)
        
        let decoder = JSONDecoder()
        let buildings = try decoder.decode([HistoricBuilding].self, from: data)
        
        Logger.success("Loaded \(buildings.count) historic buildings")
        
        // 验证900是否在结果中
        if buildings.contains(where: { $0.name == 900 }) {
            Logger.success("Oval Office (900) included in dataset")
        } else {
            Logger.warning("Oval Office (900) not in top 200 by descending Name")
        }
        
        return buildings
    }
    
    /// 分页加载历史建筑
    func loadBuildings(offset: Int = 0, limit: Int = 100) async throws -> [HistoricBuilding] {
        Logger.database("Loading buildings (offset: \(offset), limit: \(limit))")
        
        let endpoint = "Hong%20Kong%20Heritage%20Buildings_duplicate?select=*&offset=\(offset)&limit=\(limit)"
        let data = try await makeRequest(endpoint: endpoint)
        
        let decoder = JSONDecoder()
        let buildings = try decoder.decode([HistoricBuilding].self, from: data)
        
        Logger.success("Loaded \(buildings.count) buildings")
        return buildings
    }
    
    /// 根据ID查询单个建筑
    func getBuilding(id: Int) async throws -> HistoricBuilding? {
        let endpoint = "Hong%20Kong%20Heritage%20Buildings_duplicate?Name=eq.\(id)&select=*"
        let data = try await makeRequest(endpoint: endpoint)
        
        let decoder = JSONDecoder()
        let buildings = try decoder.decode([HistoricBuilding].self, from: data)
        
        return buildings.first
    }
    
    // MARK: - 地理位置查询
    
    /// 按地图区域加载建筑（性能优化）
    func loadBuildingsInMapRegion(
        centerLat: Double,
        centerLon: Double,
        latSpan: Double,
        lonSpan: Double,
        limit: Int = 2000
    ) async throws -> [HistoricBuilding] {
        Logger.database("Loading buildings in region: center=(\(centerLat), \(centerLon)), span=(\(latSpan), \(lonSpan))")
        
        // 计算边界（扩大30%以预加载周边）
        let expandFactor = 1.3
        let latDelta = latSpan * expandFactor / 2
        let lonDelta = lonSpan * expandFactor / 2
        
        let minLat = centerLat - latDelta
        let maxLat = centerLat + latDelta
        let minLon = centerLon - lonDelta
        let maxLon = centerLon + lonDelta
        
        // 加载所有数据并过滤（因为Coordinates是文本字段，无法直接SQL查询）
        // 注意：这里仍需要优化，理想情况应在Supabase添加独立的lat/lon列
        let allBuildings = try await loadAllBuildings()
        
        let filtered = allBuildings.filter { building in
            let lat = building.latitude
            let lon = building.longitude
            return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
        }
        
        Logger.success("Found \(filtered.count) buildings in region (from \(allBuildings.count) total)")
        
        // 限制返回数量
        let limited = Array(filtered.prefix(limit))
        return limited
    }
    
    /// 查询附近的历史建筑
    func findNearbyBuildings(
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 1.0
    ) async throws -> [HistoricBuilding] {
        // 计算经纬度范围（粗略计算）
        // 1度纬度约111km，1度经度在香港约85km
        let latRange = radiusKm / 111.0
        let lonRange = radiusKm / 85.0
        
        let minLat = latitude - latRange
        let maxLat = latitude + latRange
        let minLon = longitude - lonRange
        let maxLon = longitude + lonRange
        
        Logger.database("Searching buildings near (\(latitude), \(longitude)) within \(radiusKm)km")
        
        // 加载所有数据并过滤（因为Coordinates是文本字段）
        let allBuildings = try await loadAllBuildings()
        
        let nearbyBuildings = allBuildings.filter { building in
            let lat = building.latitude
            let lon = building.longitude
            return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
        }
        
        // 按距离排序
        let sortedBuildings = nearbyBuildings.sorted { building1, building2 in
            let dist1 = distance(from: (latitude, longitude), to: (building1.latitude, building1.longitude))
            let dist2 = distance(from: (latitude, longitude), to: (building2.latitude, building2.longitude))
            return dist1 < dist2
        }
        
        Logger.success("Found \(sortedBuildings.count) nearby buildings")
        return sortedBuildings
    }
    
    /// 按地区查询建筑
    func findBuildingsByDistrict(district: String) async throws -> [HistoricBuilding] {
        // 由于District字段可能包含多个区域，需要使用模糊匹配
        let allBuildings = try await loadAllBuildings()
        
        let filtered = allBuildings.filter { building in
            building.district.contains(district)
        }
        
        Logger.success("Found \(filtered.count) buildings in district: \(district)")
        return filtered
    }
    
    /// 搜索建筑（根据地址）
    func searchBuildings(keyword: String) async throws -> [HistoricBuilding] {
        let allBuildings = try await loadAllBuildings()
        
        let results = allBuildings.filter { building in
            building.address.localizedCaseInsensitiveContains(keyword)
        }
        
        Logger.success("Found \(results.count) buildings matching: \(keyword)")
        return results
    }
    
    // MARK: - 辅助方法
    
    private func makeRequest(endpoint: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/rest/v1/\(endpoint)") else {
            throw BuildingsError.invalidURL
        }
        
        let headers: [String: String] = [
            "apikey": apiKey,
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json",
            "Range": "0-9999",  // 允许返回超过1000条记录
            "Prefer": "return=representation"  // 确保不截断结果
        ]
        
        do {
            // 使用统一网络管理器，自动支持重试和错误处理
            return try await NetworkManager.shared.get(
                url: url,
                headers: headers,
                timeout: 30,
                retries: 2  // 历史建筑数据较稳定，2次重试足够
            )
        } catch let error as NetworkError {
            // 转换为BuildingsError
            switch error {
            case .httpError(let code, _):
                throw BuildingsError.httpError(code)
            case .invalidURL:
                throw BuildingsError.invalidURL
            case .invalidResponse, .noData:
                throw BuildingsError.invalidResponse
            default:
                throw BuildingsError.invalidResponse
            }
        }
    }
    
    /// 计算两点之间的距离（公里）
    private func distance(from point1: (Double, Double), to point2: (Double, Double)) -> Double {
        let lat1 = point1.0 * .pi / 180
        let lon1 = point1.1 * .pi / 180
        let lat2 = point2.0 * .pi / 180
        let lon2 = point2.1 * .pi / 180
        
        let dLat = lat2 - lat1
        let dLon = lon2 - lon1
        
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1) * cos(lat2) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let earthRadius = 6371.0 // 地球半径（公里）
        
        return earthRadius * c
    }
}

// MARK: - 错误类型

enum BuildingsError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .noData:
            return "No data found"
        }
    }
}

