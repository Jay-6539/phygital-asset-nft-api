//
//  KeychainManager.swift
//  Treasure Hunt, Hong Kong Park
//
//  Keychain 安全存储管理器 - 用于存储敏感用户信息
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private let serviceName = "com.jay.treasurehunt"
    
    private init() {}
    
    /// 保存字符串到 Keychain
    /// - Parameters:
    ///   - key: 存储键
    ///   - value: 要存储的字符串
    /// - Returns: 是否成功
    @discardableResult
    func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            Logger.error("Failed to convert string to data for key: \(key)")
            return false
        }
        
        // 删除已存在的项
        delete(key: key)
        
        // 创建查询字典
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // 保存到 Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            Logger.debug("Keychain save success: \(key)")
            return true
        } else {
            Logger.error("Keychain save failed for \(key): \(status)")
            return false
        }
    }
    
    /// 从 Keychain 读取字符串
    /// - Parameter key: 存储键
    /// - Returns: 读取的字符串，失败返回 nil
    func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            if status != errSecItemNotFound {
                Logger.error("Keychain load failed for \(key): \(status)")
            }
            return nil
        }
        
        Logger.debug("Keychain load success: \(key)")
        return value
    }
    
    /// 从 Keychain 删除项
    /// - Parameter key: 存储键
    /// - Returns: 是否成功
    @discardableResult
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            Logger.debug("Keychain delete success: \(key)")
            return true
        } else {
            Logger.error("Keychain delete failed for \(key): \(status)")
            return false
        }
    }
    
    /// 清空所有 Keychain 项
    func deleteAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            Logger.success("Keychain cleared all items")
        } else {
            Logger.error("Keychain clear all failed: \(status)")
        }
    }
    
    /// 检查 Keychain 中是否存在某个键
    /// - Parameter key: 存储键
    /// - Returns: 是否存在
    func exists(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}

// MARK: - 便捷扩展：UserDefaults + Keychain 混合存储

extension KeychainManager {
    /// Keychain 存储键
    enum SecureKey {
        static let userId = "user_id"
        static let userEmail = "user_email"
        static let providerId = "provider_id"
        static let password = "user_password"  // 如果需要存储密码（通常不应该）
    }
}

