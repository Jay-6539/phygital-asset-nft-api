//
//  WelcomeView.swift
//  Phygital Asset
//
//  Created by refactoring on 20/10/2025.
//

import SwiftUI

struct WelcomeView: View {
    // Bindings from parent
    @Binding var username: String
    @Binding var showWelcome: Bool
    @Binding var showTerms: Bool
    @Binding var isMapPreloading: Bool
    
    // Actions
    let onSignOut: () -> Void
    let onExploreButtonTap: () -> Void
    let onPreloadMap: () -> Void
    
    // Device-specific sizing
    let welcomeImageHeight: CGFloat
    let welcomeImageVerticalPadding: CGFloat
    
    // App color
    let appGreen: Color
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航区域 - 固定高度46px，与其他页面一致
            HStack {
                Spacer()
                
                // Sign Out 按钮 - 精致的毛玻璃小按钮
                Button(action: onSignOut) {
                    Text("Sign Out")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(appGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    .background {
                        ZStack {
                            Color.clear.background(.ultraThinMaterial)
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    appGreen.opacity(0.12),
                                    appGreen.opacity(0.04)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    }
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.white.opacity(0.5), location: 0.0),
                                        .init(color: Color.white.opacity(0.0), location: 0.3),
                                        .init(color: appGreen.opacity(0.15), location: 0.7),
                                        .init(color: appGreen.opacity(0.3), location: 1.0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: appGreen.opacity(0.15), radius: 6, x: 0, y: 3)
                    .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
                }
                .padding(.top, 8)
                .padding(.trailing, 16)
            }
            .frame(height: 46)
            
            // 固定高度区域，确保标题位置一致
            VStack(spacing: 0) {
                // 标题 - WELCOME!（液体质感）
                Text("WELCOME!")
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
                            Text("WELCOME!")
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                        )
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 2)
                    .shadow(color: Color.white.opacity(0.4), radius: 2, x: 0, y: -1)
                    .blur(radius: 0.3)
                    .padding(.top, 20)
                    .frame(height: 100)
                
                
                // 占位空间 - 与其他页面保持一致
                Spacer()
                    .frame(height: 60)
            }
            
            // 用户名单独一行 - 紧贴标题下方
            if !username.isEmpty {
                Text(username.uppercased())
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
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
                            Text(username.uppercased())
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                        )
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 2)
                    .shadow(color: Color.white.opacity(0.4), radius: 2, x: 0, y: -1)
                    .blur(radius: 0.3)
                    .padding(.top, -50)
            }
            
            // 描述文字 - 向上移动，2行显示
            VStack(alignment: .leading, spacing: 4) {
                if username.isEmpty {
                    Text("This is a phygital world! You can mine others' and register your own treasures!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, -30)
                } else {
                    Text("This is a phygital world! You can mine others' and register your own treasures!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 5)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
                .frame(minHeight: 10)
            
            // Earth logo treasure hunt 图片 - 宽度与按钮一致，保持原始高度
            Image("LOGO earth")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: welcomeImageHeight)
                .clipped()
                .padding(.horizontal, 20)
                .padding(.vertical, welcomeImageVerticalPadding * 0.8)
            
            Spacer()
                .frame(minHeight: 10)
            
            // 按钮 - 固定位置
            Button(action: onExploreButtonTap) {
                HStack {
                    if isMapPreloading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: appGreen))
                            .scaleEffect(0.8)
                        Text("Loading treasures...")
                            .font(.headline)
                            .foregroundColor(appGreen)
                    } else {
                        Text("Explore this Phygital World!")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(appGreen)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    ZStack {
                        // 毛玻璃基础层
                        Color.clear.background(.ultraThinMaterial)
                        
                        // 浅绿色渐变叠加层（从上到下渐变）
                        LinearGradient(
                            gradient: Gradient(colors: [
                                appGreen.opacity(0.15),
                                appGreen.opacity(0.05)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .cornerRadius(12)
                .overlay(
                    // 边缘高光效果
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(0.6), location: 0.0),
                                    .init(color: Color.white.opacity(0.0), location: 0.3),
                                    .init(color: appGreen.opacity(0.2), location: 0.7),
                                    .init(color: appGreen.opacity(0.4), location: 1.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: appGreen.opacity(0.2), radius: 8, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .disabled(isMapPreloading)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .onAppear {
            onPreloadMap()
        }
    }
}

