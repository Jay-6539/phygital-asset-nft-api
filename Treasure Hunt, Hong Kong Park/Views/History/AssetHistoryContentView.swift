//
//  AssetHistoryContentView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Created by AI Assistant on 2024
//

import SwiftUI

struct AssetHistoryContentView: View {
    let building: Treasure?
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                        Text("Back")
                            .font(.headline)
                    }
                    .foregroundColor(appGreen)
                }
                
                Spacer()
                
                Text("Asset History")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 占位符，保持标题居中
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                    Text("Back")
                        .font(.headline)
                }
                .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // 内容区域
            VStack(spacing: 20) {
                // 建筑信息
                if let building = building {
                    VStack(spacing: 16) {
                        Text(building.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(building.address)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                // 历史记录区域
                ScrollView {
                    VStack(spacing: 16) {
                        // 显示历史记录提示
                        VStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No check-in history yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Check-in按钮
                Button(action: {
                    // Check-in功能
                }) {
                    Text("Check In Mine")
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
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}
