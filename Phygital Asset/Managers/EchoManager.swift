//
//  EchoManager.swift
//  Phygital Asset
//
//  Echo（代币）管理器
//

import Foundation

class EchoManager {
    static let shared = EchoManager()
    private init() {}
    
    private let userDefaults = UserDefaults.standard
    private let echoKey = "user_echo_"
    private let frozenEchoKey = "user_frozen_echo_"
    
    // MARK: - 获取冻结的Echo
    func getFrozenEcho(for username: String) -> Int {
        let key = frozenEchoKey + username
        return userDefaults.integer(forKey: key)
    }
    
    // MARK: - 获取可用的Echo（总额 - 冻结）
    func getAvailableEcho(for username: String) -> Int {
        let total = getEcho(for: username)
        let frozen = getFrozenEcho(for: username)
        let available = total - frozen
        Logger.debug("💰 Available echo for @\(username): \(available) (total: \(total), frozen: \(frozen))")
        return max(0, available)
    }
    
    // MARK: - 冻结Echo（出价时）
    func freezeEcho(_ amount: Int, for username: String) {
        let currentFrozen = getFrozenEcho(for: username)
        let newFrozen = currentFrozen + amount
        let key = frozenEchoKey + username
        userDefaults.set(newFrozen, forKey: key)
        
        Logger.debug("🧊 Frozen \(amount) echo for @\(username)")
        Logger.debug("   Frozen total: \(currentFrozen) → \(newFrozen)")
    }
    
    // MARK: - 解冻Echo（Bid取消/完成/拒绝时）
    func unfreezeEcho(_ amount: Int, for username: String) {
        let currentFrozen = getFrozenEcho(for: username)
        let newFrozen = max(0, currentFrozen - amount)
        let key = frozenEchoKey + username
        userDefaults.set(newFrozen, forKey: key)
        
        Logger.debug("🔓 Unfrozen \(amount) echo for @\(username)")
        Logger.debug("   Frozen total: \(currentFrozen) → \(newFrozen)")
    }
    
    // MARK: - 获取Echo
    func getEcho(for username: String) -> Int {
        let key = echoKey + username
        let echo = userDefaults.integer(forKey: key)
        Logger.debug("💰 Echo for @\(username): \(echo)")
        return echo
    }
    
    // MARK: - 设置Echo
    func setEcho(_ amount: Int, for username: String) {
        let key = echoKey + username
        userDefaults.set(amount, forKey: key)
        Logger.debug("💰 Echo updated for @\(username): \(amount)")
    }
    
    // MARK: - 增加Echo
    func addEcho(_ amount: Int, for username: String, reason: String = "") {
        let currentEcho = getEcho(for: username)
        let newEcho = currentEcho + amount
        setEcho(newEcho, for: username)
        
        Logger.success("💰 +\(amount) echo for @\(username) (\(reason))")
        Logger.debug("   Total: \(currentEcho) → \(newEcho)")
    }
    
    // MARK: - 扣除Echo
    func deductEcho(_ amount: Int, for username: String, reason: String = "") throws {
        let currentEcho = getEcho(for: username)
        
        guard currentEcho >= amount else {
            Logger.error("❌ Insufficient echo for @\(username): has \(currentEcho), needs \(amount)")
            throw NSError(domain: "EchoManager", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Insufficient echo. You have \(currentEcho) echo but need \(amount)."
            ])
        }
        
        let newEcho = currentEcho - amount
        setEcho(newEcho, for: username)
        
        Logger.success("💰 -\(amount) echo for @\(username) (\(reason))")
        Logger.debug("   Total: \(currentEcho) → \(newEcho)")
    }
    
    // MARK: - 检查余额是否足够
    func hasEnoughEcho(_ amount: Int, for username: String) -> Bool {
        let currentEcho = getEcho(for: username)
        return currentEcho >= amount
    }
    
    // MARK: - 转账Echo（买卖交易）
    func transferEcho(
        amount: Int,
        from buyerUsername: String,
        to sellerUsername: String,
        reason: String = "Asset trade"
    ) throws {
        let currentEcho = getEcho(for: buyerUsername)
        let frozenEcho = getFrozenEcho(for: buyerUsername)
        
        Logger.debug("💰 Transfer attempt: \(amount) echo from @\(buyerUsername)")
        Logger.debug("   Current total: \(currentEcho), Frozen: \(frozenEcho), Available: \(currentEcho - frozenEcho)")
        
        // 检查总余额（包括frozen部分）是否足够
        // 注意：对于Bid交易，我们允许使用frozen echo
        guard currentEcho >= amount else {
            Logger.error("❌ Insufficient total echo for @\(buyerUsername): has \(currentEcho), needs \(amount)")
            throw NSError(domain: "EchoManager", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Insufficient echo. You have \(currentEcho) echo but need \(amount)."
            ])
        }
        
        // 扣除买家Echo
        let newBuyerEcho = currentEcho - amount
        setEcho(newBuyerEcho, for: buyerUsername)
        Logger.success("💰 -\(amount) echo for @\(buyerUsername) (Payment: \(reason))")
        Logger.debug("   Total: \(currentEcho) → \(newBuyerEcho)")
        
        // 给卖家增加
        addEcho(amount, for: sellerUsername, reason: "Sale: \(reason)")
        
        Logger.success("💸 Transfer completed: \(amount) echo from @\(buyerUsername) to @\(sellerUsername)")
    }
    
    // MARK: - 初始化新用户Echo（可选）
    func initializeNewUser(_ username: String, initialEcho: Int = 1000) {
        let currentEcho = getEcho(for: username)
        
        if currentEcho == 0 {
            setEcho(initialEcho, for: username)
            Logger.success("🎁 New user @\(username) initialized with \(initialEcho) echo")
        }
    }
}

