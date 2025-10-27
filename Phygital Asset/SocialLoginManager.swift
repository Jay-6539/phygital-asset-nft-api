//
//  SocialLoginManager.swift
//  Phygital Asset
//
//  Created by Jay on 16/10/2025.
//

import Foundation
import SwiftUI
import FacebookLogin
import FacebookCore
import GoogleSignIn
import AuthenticationServices

class SocialLoginManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userInfo: UserInfo?
    @Published var errorMessage: String?
    @Published var loginFailed = false  // 新增：标记登录失败
    
    struct UserInfo {
        let id: String
        let name: String
        let email: String
        let provider: String // "facebook", "google", or "apple"
    }
    
    init() {
        // 初始化Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            Logger.error("GoogleService-Info.plist not found or CLIENT_ID missing")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
    
    // MARK: - Facebook Login
    func loginWithFacebook() {
        // 重置错误状态
        loginFailed = false
        errorMessage = nil
        
        // 获取当前的 UIViewController
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            errorMessage = "Unable to get current view controller"
            loginFailed = true
            Logger.error("Facebook login failed: Unable to get rootViewController")
            return
        }
        
        // 找到最顶层的 ViewController
        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        let loginManager = LoginManager()
        Logger.auth("Starting Facebook login...")
        
        // 只请求 public_profile，email 可能需要应用审核
        loginManager.logIn(permissions: ["public_profile"], from: topController) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Facebook login failed: \(error.localizedDescription)"
                    self?.loginFailed = true
                    Logger.error("Facebook login error: \(error.localizedDescription)")
                    return
                }
                
                guard let result = result, !result.isCancelled else {
                    self?.errorMessage = "Facebook login cancelled"
                    self?.loginFailed = true
                    Logger.warning("Facebook login cancelled by user")
                    return
                }
                
                Logger.success("Facebook login authorized successfully, fetching user info...")
                if let token = result.token {
                    self?.fetchFacebookUserInfo(token: token)
                }
            }
        }
    }
    
    private func fetchFacebookUserInfo(token: AccessToken) {
        let request = GraphRequest(graphPath: "me", parameters: ["fields": "id,name,email"])
        request.start { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to fetch Facebook user info: \(error.localizedDescription)"
                    self?.loginFailed = true
                    return
                }
                
                guard let data = result as? [String: Any],
                      let id = data["id"] as? String,
                      let name = data["name"] as? String else {
                    self?.errorMessage = "Unable to parse Facebook user information"
                    self?.loginFailed = true
                    return
                }
                
                let email = data["email"] as? String ?? ""
                self?.userInfo = UserInfo(id: id, name: name, email: email, provider: "facebook")
                self?.isLoggedIn = true
                Logger.success("Facebook login successful: \(name)")
            }
        }
    }
    
    // MARK: - Google Login
    func loginWithGoogle() {
        Logger.auth("Starting Google login...")
        
        // 重置错误状态
        loginFailed = false
        errorMessage = nil
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentingViewController = scene.windows.first?.rootViewController else {
            errorMessage = "Unable to get current view controller"
            loginFailed = true
            Logger.error("Google login failed: Unable to get rootViewController")
            return
        }
        
        // 找到最顶层的 ViewController
        var topController = presentingViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: topController) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Google login failed: \(error.localizedDescription)"
                    self?.loginFailed = true
                    Logger.error("Google login error: \(error.localizedDescription)")
                    return
                }
                
                guard let user = result?.user else {
                    self?.errorMessage = "Google login failed: Unable to get user information"
                    self?.loginFailed = true
                    Logger.error("Google login failed: Unable to get user information")
                    return
                }
                
                let email = user.profile?.email ?? ""
                let name = user.profile?.name ?? ""
                let id = user.userID ?? ""
                
                Logger.success("Google login successful: \(name) (\(email))")
                
                self?.userInfo = UserInfo(id: id, name: name, email: email, provider: "google")
                self?.isLoggedIn = true
            }
        }
    }
    
    // MARK: - Apple Login
    func loginWithApple(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        // 需要在调用处设置delegate
        // controller.delegate = ...
        // controller.presentationContextProvider = ...
        
        controller.performRequests()
    }
    
    func handleAppleLoginResult(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Unable to get Apple login credentials"
            loginFailed = true
            return
        }
        
        let userID = appleIDCredential.user
        let fullName = appleIDCredential.fullName
        let email = appleIDCredential.email
        
        let name = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        DispatchQueue.main.async {
            self.userInfo = UserInfo(
                id: userID,
                name: name.isEmpty ? "Apple User" : name,
                email: email ?? "",
                provider: "apple"
            )
            self.isLoggedIn = true
            Logger.success("Apple login successful: \(name)")
        }
    }
    
    // MARK: - Logout
    func logout() {
        // Facebook登出
        LoginManager().logOut()
        
        // Google登出
        GIDSignIn.sharedInstance.signOut()
        
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.userInfo = nil
            self.errorMessage = nil
        }
    }
}