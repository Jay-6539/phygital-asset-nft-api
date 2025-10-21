//
//  LoginView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Created by refactoring on 20/10/2025.
//

import SwiftUI

struct LoginView: View {
    // Bindings from parent
    @Binding var username: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var isLoginMode: Bool
    @Binding var isAuthenticating: Bool
    @Binding var showLogin: Bool
    @Binding var showTerms: Bool
    @Binding var isFromSocialLogin: Bool
    
    // Social login actions
    let onAppleLogin: () -> Void
    let onFacebookLogin: () -> Void
    let onGoogleLogin: () -> Void
    let onUsernameLogin: () async -> Void
    
    // App color
    let appGreen: Color
    
    // 按钮禁用状态计算
    private var isButtonDisabled: Bool {
        username.isEmpty || password.isEmpty || (!isLoginMode && confirmPassword.isEmpty) || isAuthenticating
    }
    
    // 登录/注册按钮视图
    private var loginButton: some View {
        Button(action: {
            Task {
                await onUsernameLogin()
            }
        }) {
            HStack {
                if isAuthenticating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: isButtonDisabled ? Color.gray : appGreen))
                        .scaleEffect(0.8)
                }
                Text(isAuthenticating ? "Authenticating..." : (isLoginMode ? "Login with Username" : "Create Account"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isButtonDisabled ? Color.gray : appGreen)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background {
                premiumButtonBackground
            }
            .cornerRadius(12)
            .overlay(premiumButtonBorder)
            .shadow(color: isButtonDisabled ? Color.gray.opacity(0.2) : appGreen.opacity(0.2), radius: 8, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .disabled(username.isEmpty || password.isEmpty || (!isLoginMode && confirmPassword.isEmpty) || isAuthenticating)
        .padding(.horizontal, 20)
    }
    
    // 按钮背景
    private var premiumButtonBackground: some View {
        ZStack {
            Color.clear.background(.ultraThinMaterial)
            LinearGradient(
                gradient: Gradient(colors: [
                    isButtonDisabled ? Color.gray.opacity(0.15) : appGreen.opacity(0.15),
                    isButtonDisabled ? Color.gray.opacity(0.05) : appGreen.opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // 按钮边框
    private var premiumButtonBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0.6), location: 0.0),
                        .init(color: Color.white.opacity(0.0), location: 0.3),
                        .init(color: isButtonDisabled ? Color.gray.opacity(0.2) : appGreen.opacity(0.2), location: 0.7),
                        .init(color: isButtonDisabled ? Color.gray.opacity(0.4) : appGreen.opacity(0.4), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 返回按钮区域 - 占位符，保持与Choose Username页面布局一致
            HStack {
                Spacer()
            }
            .frame(height: 46) // 与Choose Username页面的返回按钮区域高度一致
            
            // 固定高度区域，确保标题位置一致
            VStack(spacing: 0) {
                // 标题 - 液体质感圆润效果（柔和渐变）
                Text(isLoginMode ? "LOGIN" : "REGISTER")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.black.opacity(0.95), location: 0.0),
                                .init(color: Color.black.opacity(0.85), location: 0.4),
                                .init(color: Color.black.opacity(0.7), location: 0.7),
                                .init(color: Color.black.opacity(0.55), location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        // 柔和的顶部高光
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(0.25), location: 0.0),
                                .init(color: Color.white.opacity(0.1), location: 0.2),
                                .init(color: Color.white.opacity(0.0), location: 0.4)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .mask(
                            Text(isLoginMode ? "LOGIN" : "REGISTER")
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                        )
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 2)
                    .shadow(color: Color.white.opacity(0.4), radius: 2, x: 0, y: -1)
                    .blur(radius: 0.3)
                    .padding(.top, 20)
                    .frame(height: 100)
                
                
                // 描述文字 - 固定位置（已移除灰色文字）
                Spacer()
                    .frame(height: 60)
            }
            
            ScrollView {
                VStack(spacing: 30) {
                    
                    // 第三方登录选项 - 图标按钮
                    HStack(spacing: 24) {
                        // Apple 登录按钮
                        Button(action: onAppleLogin) {
                            Image("Apple")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                        }
                        
                        // Facebook 登录按钮
                        Button(action: onFacebookLogin) {
                            Image("Facebook")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                        }
                        
                        // Google 登录按钮
                        Button(action: onGoogleLogin) {
                            Image("Google")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                        }
                        
                        // WeChat 图标
                        Image("Wechat")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                    }
                    .padding(.horizontal, 20)
                    
                    // 分隔线
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.horizontal, 20)
                    
                    // 输入框
                    VStack(spacing: 16) {
                        TextField("Username", text: $username)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocorrectionDisabled(true)
                            .textContentType(.username)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        if !isLoginMode {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 登录/注册按钮
                    loginButton
                }
            }
            
            Spacer()
            
            // 切换登录/注册模式 - 固定在屏幕底部
            Button(action: {
                isLoginMode.toggle()
                username = ""
                password = ""
                confirmPassword = ""
            }) {
                Text(isLoginMode ? "Don't have an account? Create one" : "Already have an account? Login")
                    .font(.body)
                    .foregroundColor(appGreen)
            }
            .padding(.bottom, 20)
        }
        .background(Color.gray.opacity(0.05))
    }
}

