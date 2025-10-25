//
//  CreditsManager.swift
//  Treasure Hunt, Hong Kong Park
//
//  Credits（积分）管理器
//

import Foundation

class CreditsManager {
    static let shared = CreditsManager()
    private init() {}
    
    private let userDefaults = UserDefaults.standard
    private let creditsKey = "user_credits_"
    private let frozenCreditsKey = "user_frozen_credits_"
    
    // MARK: - 获取冻结的Credits
    func getFrozenCredits(for username: String) -> Int {
        let key = frozenCreditsKey + username
        return userDefaults.integer(forKey: key)
    }
    
    // MARK: - 获取可用的Credits（总额 - 冻结）
    func getAvailableCredits(for username: String) -> Int {
        let total = getCredits(for: username)
        let frozen = getFrozenCredits(for: username)
        let available = total - frozen
        Logger.debug("💰 Available credits for @\(username): \(available) (total: \(total), frozen: \(frozen))")
        return max(0, available)
    }
    
    // MARK: - 冻结Credits（出价时）
    func freezeCredits(_ amount: Int, for username: String) {
        let currentFrozen = getFrozenCredits(for: username)
        let newFrozen = currentFrozen + amount
        let key = frozenCreditsKey + username
        userDefaults.set(newFrozen, forKey: key)
        
        Logger.debug("🧊 Frozen \(amount) credits for @\(username)")
        Logger.debug("   Frozen total: \(currentFrozen) → \(newFrozen)")
    }
    
    // MARK: - 解冻Credits（Bid取消/完成/拒绝时）
    func unfreezeCredits(_ amount: Int, for username: String) {
        let currentFrozen = getFrozenCredits(for: username)
        let newFrozen = max(0, currentFrozen - amount)
        let key = frozenCreditsKey + username
        userDefaults.set(newFrozen, forKey: key)
        
        Logger.debug("🔓 Unfrozen \(amount) credits for @\(username)")
        Logger.debug("   Frozen total: \(currentFrozen) → \(newFrozen)")
    }
    
    // MARK: - 获取Credits
    func getCredits(for username: String) -> Int {
        let key = creditsKey + username
        let credits = userDefaults.integer(forKey: key)
        Logger.debug("💰 Credits for @\(username): \(credits)")
        return credits
    }
    
    // MARK: - 设置Credits
    func setCredits(_ amount: Int, for username: String) {
        let key = creditsKey + username
        userDefaults.set(amount, forKey: key)
        Logger.debug("💰 Credits updated for @\(username): \(amount)")
    }
    
    // MARK: - 增加Credits
    func addCredits(_ amount: Int, for username: String, reason: String = "") {
        let currentCredits = getCredits(for: username)
        let newCredits = currentCredits + amount
        setCredits(newCredits, for: username)
        
        Logger.success("💰 +\(amount) credits for @\(username) (\(reason))")
        Logger.debug("   Total: \(currentCredits) → \(newCredits)")
    }
    
    // MARK: - 扣除Credits
    func deductCredits(_ amount: Int, for username: String, reason: String = "") throws {
        let currentCredits = getCredits(for: username)
        
        guard currentCredits >= amount else {
            Logger.error("❌ Insufficient credits for @\(username): has \(currentCredits), needs \(amount)")
            throw NSError(domain: "CreditsManager", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Insufficient credits. You have \(currentCredits) credits but need \(amount)."
            ])
        }
        
        let newCredits = currentCredits - amount
        setCredits(newCredits, for: username)
        
        Logger.success("💰 -\(amount) credits for @\(username) (\(reason))")
        Logger.debug("   Total: \(currentCredits) → \(newCredits)")
    }
    
    // MARK: - 检查余额是否足够
    func hasEnoughCredits(_ amount: Int, for username: String) -> Bool {
        let currentCredits = getCredits(for: username)
        return currentCredits >= amount
    }
    
    // MARK: - 转账Credits（买卖交易）
    func transferCredits(
        amount: Int,
        from buyerUsername: String,
        to sellerUsername: String,
        reason: String = "Asset trade"
    ) throws {
        // 先检查买家余额
        try deductCredits(amount, for: buyerUsername, reason: "Payment: \(reason)")
        
        // 给卖家增加
        addCredits(amount, for: sellerUsername, reason: "Sale: \(reason)")
        
        Logger.success("💸 Transfer completed: \(amount) credits from @\(buyerUsername) to @\(sellerUsername)")
    }
    
    // MARK: - 初始化新用户Credits（可选）
    func initializeNewUser(_ username: String, initialCredits: Int = 1000) {
        let currentCredits = getCredits(for: username)
        
        if currentCredits == 0 {
            setCredits(initialCredits, for: username)
            Logger.success("🎁 New user @\(username) initialized with \(initialCredits) credits")
        }
    }
}

