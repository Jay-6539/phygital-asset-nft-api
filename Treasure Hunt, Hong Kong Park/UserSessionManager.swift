//
//  UserSessionManager.swift
//  Treasure Hunt, Hong Kong Park
//
//  用户会话管理器 - 处理用户登录状态持久化
//

import Foundation
import SwiftUI

class UserSessionManager: ObservableObject {
    static let shared = UserSessionManager()
    
    @Published var isLoggedIn: Bool = false
    @Published var currentUsername: String? = nil
    @Published var currentUserId: String? = nil
    @Published var currentUserEmail: String? = nil
    @Published var loginProvider: String? = nil  // "username", "apple", "facebook", "google"
    
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults Keys
    private let isLoggedInKey = "isUserLoggedIn"
    private let usernameKey = "currentUsername"
    private let userIdKey = "currentUserId"
    private let userEmailKey = "currentUserEmail"
    private let loginProviderKey = "loginProvider"
    
    init() {
        loadSession()
    }
    
    /// 从 UserDefaults 和 Keychain 加载会话
    private func loadSession() {
        // 非敏感信息从 UserDefaults 读取
        isLoggedIn = userDefaults.bool(forKey: isLoggedInKey)
        currentUsername = userDefaults.string(forKey: usernameKey)
        loginProvider = userDefaults.string(forKey: loginProviderKey)
        
        // 敏感信息从 Keychain 读取
        currentUserId = KeychainManager.shared.load(key: KeychainManager.SecureKey.userId)
        currentUserEmail = KeychainManager.shared.load(key: KeychainManager.SecureKey.userEmail)
        
        if isLoggedIn, let username = currentUsername {
            Logger.auth("Session restored: \(username) (secure data from Keychain)")
        }
    }
    
    /// 保存用户会话（敏感信息存入 Keychain）
    func saveSession(user: CloudUser) {
        isLoggedIn = true
        currentUsername = user.username
        currentUserId = user.id
        currentUserEmail = user.email
        loginProvider = user.provider
        
        // 非敏感信息存入 UserDefaults
        userDefaults.set(true, forKey: isLoggedInKey)
        userDefaults.set(user.username, forKey: usernameKey)
        userDefaults.set(user.provider, forKey: loginProviderKey)
        
        // 敏感信息存入 Keychain（更安全）
        if let userId = user.id {
            KeychainManager.shared.save(key: KeychainManager.SecureKey.userId, value: userId)
        }
        if let email = user.email {
            KeychainManager.shared.save(key: KeychainManager.SecureKey.userEmail, value: email)
        }
        if let providerId = user.providerId {
            KeychainManager.shared.save(key: "provider_id", value: providerId)
        }
        
        Logger.auth("Session saved: \(user.username) (sensitive data in Keychain)")
    }
    
    /// 清除用户会话（登出）
    func clearSession() {
        isLoggedIn = false
        currentUsername = nil
        currentUserId = nil
        currentUserEmail = nil
        loginProvider = nil
        
        // 清除 UserDefaults
        userDefaults.removeObject(forKey: isLoggedInKey)
        userDefaults.removeObject(forKey: usernameKey)
        userDefaults.removeObject(forKey: loginProviderKey)
        
        // 清除 Keychain 中的敏感信息
        KeychainManager.shared.delete(key: KeychainManager.SecureKey.userId)
        KeychainManager.shared.delete(key: KeychainManager.SecureKey.userEmail)
        KeychainManager.shared.delete(key: "provider_id")
        
        Logger.auth("Session cleared (Keychain + UserDefaults)")
    }
    
    /// 更新用户名（如果用户在社交登录后修改了用户名）
    func updateUsername(_ newUsername: String) {
        currentUsername = newUsername
        userDefaults.set(newUsername, forKey: usernameKey)
        Logger.auth("Username updated: \(newUsername)")
    }
}

