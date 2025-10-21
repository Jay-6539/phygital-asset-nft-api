//
//  NotificationPermissionView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Created by refactoring on 20/10/2025.
//

import SwiftUI

struct NotificationPermissionView: View {
    // Bindings from parent
    @Binding var showNotifications: Bool
    
    // App color
    let appGreen: Color
    
    var body: some View {
        VStack(spacing: 0) {
            // 固定高度区域，确保标题位置一致
            VStack(spacing: 0) {
                // 标题 - 固定位置
                Text("Allow notifications?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 60)
                    .frame(height: 100)
                
                
                // 描述文字 - 固定位置
                Text("Get beginner-friendly tips and reminders to help you get started.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .padding(.horizontal, 20)
                    .frame(height: 60)
            }
            
            Spacer()
            
            // 按钮区域 - 固定位置
            VStack(spacing: 16) {
                // 主要按钮
                Button(action: {
                    showNotifications = false
                }) {
                    Text("Yes, please")
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
                .padding(.horizontal, 20)
                
                // 次要选项
                Button(action: {
                    showNotifications = false
                }) {
                    Text("Maybe later")
                        .font(.body)
                        .foregroundColor(appGreen)
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
    }
}

