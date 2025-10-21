//
//  SocialLoginAuthView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Created by refactoring on 20/10/2025.
//

import SwiftUI

struct SocialLoginAuthView: View {
    // Bindings from parent
    @Binding var showSocialLoginSheet: Bool
    @Binding var pendingSocialProvider: SocialProvider?
    
    // Actions
    let onSocialLogin: () -> Void
    
    // App color
    let appGreen: Color
    
    var body: some View {
        // 确保provider有值（使用默认值避免nil导致内容不显示）
        let provider = pendingSocialProvider ?? .facebook
        
        return VStack(spacing: 24) {
            Spacer()
            
            // 平台Logo和标题
            VStack(spacing: 16) {
                // 平台图标
                ZStack {
                    Circle()
                        .fill(appGreen)
                        .frame(width: 80, height: 80)
                    
                    Text(provider == .apple ? "" : (provider == .facebook ? "f" : "G"))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Connect with \(provider.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(provider.displayName) would like to connect with Treasure Hunt")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // 授权按钮
            VStack(spacing: 12) {
                Button(action: onSocialLogin) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(appGreen)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background {
                            ZStack {
                                Color.clear.background(.ultraThinMaterial)
                                appGreen.opacity(0.1)
                            }
                        }
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(appGreen.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Button(action: {
                    showSocialLoginSheet = false
                    pendingSocialProvider = nil
                }) {
                    Text("Cancel")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .presentationDetents([.medium])
    }
}

