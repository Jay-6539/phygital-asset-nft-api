//
//  NFCErrorView.swift
//  Phygital Asset
//
//  Created by AI Assistant on 2024
//

import SwiftUI

struct NFCErrorView: View {
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onBack()
                }
            
            // 错误信息框
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Spacer()
                    
                    Text("Location Error")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: onBack) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                
                Divider()
                
                // 内容区域
                VStack(spacing: 30) {
                    Spacer()
                    
                    // 错误图标
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 80))
                        .foregroundColor(appGreen)
                    
                    // 错误信息
                    VStack(spacing: 16) {
                        Text("NFC and Asset Location Mismatch")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("The NFC tag location is more than 30 meters away from the target building. Please ensure you are near the correct building.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    // 关闭按钮 - 绿色毛玻璃样式
                    Button(action: onBack) {
                        Text("Close")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(appGreen)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background {
                                ZStack {
                                    Color.clear.background(.ultraThinMaterial)
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
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
                .background(Color(.systemBackground))
            }
            .frame(maxWidth: 340, maxHeight: 500)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 20)
        }
    }
}
