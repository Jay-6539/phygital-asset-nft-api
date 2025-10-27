//
//  XPManager.swift
//  Phygital Asset
//
//  XP（经验值）管理器 - 用于跟踪用户活跃度和等级
//

import Foundation

class XPManager {
    static let shared = XPManager()
    private init() {}
    
    private let userDefaults = UserDefaults.standard
    private let xpKey = "user_xp_"
    private let levelKey = "user_level_"
    
    // XP等级配置
    private let xpPerLevel: Int = 1000  // 每级所需XP
    
    // MARK: - 获取XP
    func getXP(for username: String) -> Int {
        let key = xpKey + username
        let xp = userDefaults.integer(forKey: key)
        Logger.debug("⭐ XP for @\(username): \(xp)")
        return xp
    }
    
    // MARK: - 设置XP
    func setXP(_ amount: Int, for username: String) {
        let key = xpKey + username
        userDefaults.set(amount, forKey: key)
        
        // 更新等级
        updateLevel(for: username, xp: amount)
        
        Logger.debug("⭐ XP updated for @\(username): \(amount)")
    }
    
    // MARK: - 增加XP
    func addXP(_ amount: Int, for username: String, reason: String = "") {
        let currentXP = getXP(for: username)
        let newXP = currentXP + amount
        setXP(newXP, for: username)
        
        Logger.success("⭐ +\(amount) XP for @\(username) (\(reason))")
        Logger.debug("   Total: \(currentXP) → \(newXP)")
        
        // 检查是否升级
        checkLevelUp(username: username, oldXP: currentXP, newXP: newXP)
    }
    
    // MARK: - 获取等级
    func getLevel(for username: String) -> Int {
        let key = levelKey + username
        let level = userDefaults.integer(forKey: key)
        return max(1, level)  // 最低1级
    }
    
    // MARK: - 更新等级
    private func updateLevel(for username: String, xp: Int) {
        let newLevel = calculateLevel(xp: xp)
        let key = levelKey + username
        userDefaults.set(newLevel, forKey: key)
    }
    
    // MARK: - 计算等级
    func calculateLevel(xp: Int) -> Int {
        return max(1, (xp / xpPerLevel) + 1)
    }
    
    // MARK: - 检查升级
    private func checkLevelUp(username: String, oldXP: Int, newXP: Int) {
        let oldLevel = calculateLevel(xp: oldXP)
        let newLevel = calculateLevel(xp: newXP)
        
        if newLevel > oldLevel {
            Logger.success("🎉 @\(username) leveled up! Level \(oldLevel) → \(newLevel)")
            // 这里可以触发升级通知或奖励
        }
    }
    
    // MARK: - 获取当前等级进度
    func getLevelProgress(for username: String) -> (currentLevel: Int, currentXP: Int, xpForNextLevel: Int, progressPercentage: Float) {
        let totalXP = getXP(for: username)
        let currentLevel = getLevel(for: username)
        
        // 计算当前等级的XP进度
        let xpInCurrentLevel = totalXP % xpPerLevel
        let xpForNextLevel = xpPerLevel
        let progressPercentage = Float(xpInCurrentLevel) / Float(xpForNextLevel)
        
        return (currentLevel, xpInCurrentLevel, xpForNextLevel, progressPercentage)
    }
    
    // MARK: - XP奖励配置
    enum XPReward: Int {
        case threadCreated = 10        // 创建Thread（NFC记录）
        case buildingDiscovered = 50   // 发现新建筑
        case threadTransferred = 20    // Thread转移
        case bidAccepted = 30          // Bid被接受
        case dailyLogin = 5            // 每日登录
    }
    
    // MARK: - 便捷方法：添加预定义的XP奖励
    func awardXP(_ reward: XPReward, for username: String) {
        addXP(reward.rawValue, for: username, reason: reward.description)
    }
    
    // MARK: - 初始化新用户XP
    func initializeNewUser(_ username: String) {
        let currentXP = getXP(for: username)
        
        if currentXP == 0 {
            setXP(0, for: username)
            Logger.success("🎁 New user @\(username) initialized with 0 XP (Level 1)")
        }
    }
}

// MARK: - XPReward Description
extension XPManager.XPReward {
    var description: String {
        switch self {
        case .threadCreated:
            return "Thread created"
        case .buildingDiscovered:
            return "Building discovered"
        case .threadTransferred:
            return "Thread transferred"
        case .bidAccepted:
            return "Bid accepted"
        case .dailyLogin:
            return "Daily login"
        }
    }
}

