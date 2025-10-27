//
//  AssetInfo.swift
//  Phygital Asset
//
//  Created by refactoring on 21/10/2025.
//

import Foundation
import UIKit

// Asset信息结构
struct AssetInfo {
    let id = UUID()
    let coordinate: GridCoordinate
    var name: String = ""
    var image: UIImage? = nil
    var description: String = ""
    var nfcUUID: String = "" // NFC标签的唯一标识符
    var userInteractions: [UserInteraction] = [] // 用户check-in历史记录
    var latitude: Double? = nil  // GPS纬度
    var longitude: Double? = nil // GPS经度
    
    init(coordinate: GridCoordinate, nfcUUID: String = "") {
        self.coordinate = coordinate
        self.nfcUUID = nfcUUID
    }
    
    // GPS坐标的便捷访问
    var hasGPSCoordinates: Bool {
        return latitude != nil && longitude != nil
    }
    
    var gpsCoordinatesString: String {
        if let lat = latitude, let lon = longitude {
            return String(format: "%.6f, %.6f", lat, lon)
        }
        return "Not available"
    }
}

