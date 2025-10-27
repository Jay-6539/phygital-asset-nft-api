//
//  ContentView+MapHelpers.swift
//  Phygital Asset
//
//  Created by refactoring on 21/10/2025.
//

import Foundation
import MapKit

// 地图相关辅助方法
extension ContentView {
    // 注意：这些方法已经在ContentView中定义
    // 这个文件作为组织参考，实际方法仍在ContentView中
    // 如果需要移动这些方法到extension，需要确保它们不访问private状态
}

// MARK: - 未来优化建议
// 可以考虑将以下方法移到这里：
// - zoom(by:)
// - performSearch(_:)
// - clearSearch()
// - locateOvalOffice()
// - centerOnUserLocation()
// - restoreInitialMapState()
// - expandCluster(_:)
// - updateClusters(debounce:)
//
// 但需要注意：
// - 这些方法访问了大量@State变量
// - 移动到extension后无法访问private @State
// - 需要通过参数传递或改为public

