//
//  ChooseUsernameView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Created by refactoring on 20/10/2025.
//

import SwiftUI

struct ChooseUsernameView: View {
    // Bindings from parent
    @Binding var username: String
    @Binding var agreedToTerms: Bool
    @Binding var agreedToEmail: Bool
    @Binding var showTerms: Bool
    @Binding var showLogin: Bool
    @Binding var showWelcome: Bool
    @Binding var isFromSocialLogin: Bool
    
    // Focus state
    @FocusState private var isUsernameFieldFocused: Bool
    @FocusState private var isEmailFieldFocused: Bool
    
    // Email input state
    @State private var showEmailInput: Bool = false
    @State private var emailAddress: String = ""
    
    // Callback for saving email
    let onSaveEmail: (String) -> Void
    
    // App color
    let appGreen: Color
    
    // 继续按钮视图
    private var continueButton: some View {
        Button(action: {
            if agreedToTerms {
                // 如果用户勾选了接收邮件，先显示email输入框
                if agreedToEmail {
                    showEmailInput = true
                } else {
                    // 直接进入欢迎页面
                    showTerms = false
                    showWelcome = true
                    isFromSocialLogin = false
                }
            }
        }) {
            Text("Continue")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(agreedToTerms ? appGreen : Color.gray)
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    premiumButtonBackground
                }
                .cornerRadius(12)
                .overlay(premiumButtonBorder)
                .shadow(color: agreedToTerms ? appGreen.opacity(0.2) : Color.gray.opacity(0.2), radius: 8, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .disabled(!agreedToTerms)
        .padding(.horizontal, 20)
    }
    
    // 按钮背景
    private var premiumButtonBackground: some View {
        ZStack {
            Color.clear.background(.ultraThinMaterial)
            LinearGradient(
                gradient: Gradient(colors: [
                    agreedToTerms ? appGreen.opacity(0.15) : Color.gray.opacity(0.15),
                    agreedToTerms ? appGreen.opacity(0.05) : Color.gray.opacity(0.05)
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
                        .init(color: agreedToTerms ? appGreen.opacity(0.2) : Color.gray.opacity(0.2), location: 0.7),
                        .init(color: agreedToTerms ? appGreen.opacity(0.4) : Color.gray.opacity(0.4), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 返回按钮区域 - 固定高度46px，与其他页面一致
            HStack {
                Button(action: {
                    showTerms = false
                    showLogin = true
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.9), in: Circle())
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 8)
                .padding(.leading, 8)
                
                Spacer()
            }
            .frame(height: 46)
            
            // 固定高度区域，确保标题位置一致
            VStack(spacing: 0) {
                // 标题 - 液体质感圆润效果
                Text("CHOOSE USERNAME")
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
                            Text("CHOOSE USERNAME")
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                        )
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 2)
                    .shadow(color: Color.white.opacity(0.4), radius: 2, x: 0, y: -1)
                    .blur(radius: 0.3)
                    .padding(.top, 20)
                    .frame(height: 100)
                
                
                // 描述文字 - 固定位置
                Text("Please choose how you'd like to be displayed")
                     .font(.body)
                     .foregroundColor(.secondary)
                     .multilineTextAlignment(.leading)
                     .padding(.horizontal, 20)
                     // 使复选框+文字区域与 Continue 按钮同宽并左对齐
                     .frame(maxWidth: .infinity, alignment: .leading)
                     .frame(height: 60)
            }
            
            ScrollView {
                VStack(spacing: 30) {
                    // 社交登录加载指示器
                    if isFromSocialLogin && username.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Signing in...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                    
                    // 用户名输入框
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Username", text: $username)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocorrectionDisabled(true)
                            .textContentType(.username)
                            .focused($isUsernameFieldFocused)  // 绑定焦点状态
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 协议选项
                    VStack(spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            Button(action: { agreedToTerms.toggle() }) {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundColor(agreedToTerms ? appGreen : .gray)
                            }
                            
                            Text("I agree to the Terms of Use and Privacy Policy.*")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(alignment: .top, spacing: 12) {
                            Button(action: { agreedToEmail.toggle() }) {
                                Image(systemName: agreedToEmail ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundColor(agreedToEmail ? appGreen : .gray)
                            }
                            
                            Text("Email me news, tips, and offers.")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    
                    // 继续按钮
                    continueButton
                    
                    // 登录链接
                    Button(action: {
                        showTerms = false
                        showLogin = true
                    }) {
                        Text("Already have an account? Log in")
                            .font(.body)
                            .foregroundColor(appGreen)
                    }
                    .padding(.top, 10)
                }
            }
            
            Spacer()
            
            // 隐私声明 - 固定在屏幕底部（输入框聚焦时隐藏）
            if !isUsernameFieldFocused {
                VStack(spacing: 8) {
                    Text("Your profile and gameplay are made available to other players and treasure hunt application Authorized Developers. Control your privacy in Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("We may collect and use your data including location, photos, and usage patterns to improve our treasure hunting experience. We respect your privacy and comply with App Tracking Transparency requirements.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.gray.opacity(0.05))
        .sheet(isPresented: $showEmailInput) {
            emailInputSheet
        }
    }
    
    // Email输入弹窗
    private var emailInputSheet: some View {
        VStack(spacing: 20) {
            Text("Enter Your Email Address")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("We'll send you news, tips, and special offers")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            TextField("Email Address", text: $emailAddress)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled(true)
                .textContentType(.emailAddress)
                .focused($isEmailFieldFocused)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .submitLabel(.done)
                .onSubmit {
                    saveEmailAndContinue()
                }
            
            HStack(spacing: 12) {
                // 取消按钮
                Button(action: {
                    showEmailInput = false
                    emailAddress = ""
                    // 直接进入欢迎页面（跳过email）
                    showTerms = false
                    showWelcome = true
                    isFromSocialLogin = false
                }) {
                    Text("Skip")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background {
                            ZStack {
                                Color.clear.background(.ultraThinMaterial)
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.15),
                                        Color.gray.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                        }
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color.white.opacity(0.6), location: 0.0),
                                            .init(color: Color.white.opacity(0.0), location: 0.3),
                                            .init(color: Color.gray.opacity(0.2), location: 0.7),
                                            .init(color: Color.gray.opacity(0.4), location: 1.0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.gray.opacity(0.2), radius: 8, x: 0, y: 4)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // 保存按钮
                Button(action: {
                    saveEmailAndContinue()
                }) {
                    Text("Save")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(emailAddress.isEmpty ? Color.gray : appGreen)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background {
                            ZStack {
                                Color.clear.background(.ultraThinMaterial)
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        emailAddress.isEmpty ? Color.gray.opacity(0.15) : appGreen.opacity(0.15),
                                        emailAddress.isEmpty ? Color.gray.opacity(0.05) : appGreen.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                        }
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color.white.opacity(0.6), location: 0.0),
                                            .init(color: Color.white.opacity(0.0), location: 0.3),
                                            .init(color: emailAddress.isEmpty ? Color.gray.opacity(0.2) : appGreen.opacity(0.2), location: 0.7),
                                            .init(color: emailAddress.isEmpty ? Color.gray.opacity(0.4) : appGreen.opacity(0.4), location: 1.0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: emailAddress.isEmpty ? Color.gray.opacity(0.2) : appGreen.opacity(0.2), radius: 8, x: 0, y: 4)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .disabled(emailAddress.isEmpty)
            }
        }
        .padding(30)
        .presentationDetents([.height(350)])
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isEmailFieldFocused = true
            }
        }
    }
    
    // 保存email并继续
    private func saveEmailAndContinue() {
        guard !emailAddress.isEmpty else { return }
        
        // 保存email
        onSaveEmail(emailAddress)
        
        // 关闭弹窗并进入欢迎页面
        showEmailInput = false
        showTerms = false
        showWelcome = true
        isFromSocialLogin = false
    }
}

