//
//  OvalOfficeViewModel.swift
//  Phygital Asset
//
//  Created for Office Map refactoring
//

import SwiftUI
import CoreLocation

/// Office Map的状态管理和业务逻辑
class OvalOfficeViewModel: ObservableObject {
    // MARK: - 显示状态
    
    /// 是否显示Office Map
    @Published var showOvalOffice: Bool = false
    
    /// Office Map缩放比例
    @Published var ovalOfficeScale: CGFloat = 1.0
    
    /// Office Map偏移量
    @Published var ovalOfficeOffset: CGSize = .zero
    
    /// 上次放大倍数（用于手势）
    @Published var ovalOfficeLastMagnification: CGFloat = 1.0
    
    /// 拖动开始时的偏移量
    @Published var ovalOfficeDragStartOffset: CGSize = .zero
    
    // MARK: - Asset状态
    
    /// 是否正在注册Asset
    @Published var isRegisteringAsset: Bool = false
    
    /// 是否显示Asset信息模态框
    @Published var showAssetInfoModal: Bool = false
    
    /// 选中的Asset信息
    @Published var selectedAssetInfo: AssetInfo? = nil
    
    /// 是否是新Asset
    @Published var isNewAsset: Bool = false
    
    /// Office内的Assets列表
    @Published var officeAssets: [AssetInfo] = []
    
    /// 是否显示Asset输入模态框
    @Published var showAssetInputModal: Bool = false
    
    /// 选中的Asset索引
    @Published var selectedAssetIndex: Int? = nil
    
    /// Asset名称
    @Published var assetName: String = ""
    
    /// Asset图片
    @Published var assetImage: UIImage? = nil
    
    /// Asset描述
    @Published var assetDescription: String = ""
    
    // MARK: - 初始化
    
    init() {
        Logger.debug("OvalOfficeViewModel initialized")
    }
    
    // MARK: - 公共方法
    
    /// 重置Office Map状态
    func resetOfficeMap() {
        showOvalOffice = false
        ovalOfficeScale = 1.0
        ovalOfficeOffset = .zero
        ovalOfficeLastMagnification = 1.0
        ovalOfficeDragStartOffset = .zero
        Logger.debug("Office Map state reset")
    }
    
    /// 重置Asset输入状态
    func resetAssetInput() {
        assetName = ""
        assetImage = nil
        assetDescription = ""
        isNewAsset = false
        selectedAssetIndex = nil
        Logger.debug("Asset input state reset")
    }
    
    /// 加载Office Assets
    func loadOfficeAssets(_ assets: [AssetInfo]) {
        officeAssets = assets
        Logger.debug("Loaded \(assets.count) office assets")
    }
    
    /// 添加新Asset
    func addAsset(_ asset: AssetInfo) {
        officeAssets.append(asset)
        Logger.success("Asset added: \(asset.name)")
    }
    
    /// 更新Asset
    func updateAsset(at index: Int, with asset: AssetInfo) {
        guard officeAssets.indices.contains(index) else {
            Logger.error("Invalid asset index: \(index)")
            return
        }
        officeAssets[index] = asset
        Logger.success("Asset updated: \(asset.name)")
    }
}

