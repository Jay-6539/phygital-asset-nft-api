//
//  NFCErrorModal.swift
//  Treasure Hunt, Hong Kong Park
//
//  Created by AI Assistant on 2024
//

import SwiftUI

struct NFCErrorModal: View {
    let onBack: () -> Void
    
    var body: some View {
        // 错误信息框
        VStack(spacing: 24) {
            // 错误图标
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(appGreen)
            
            // 错误信息
            VStack(spacing: 16) {
                Text("NFC and Asset Location Mismatch")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("The NFC tag location is more than 30 meters away from the target building. Please ensure you are near the correct building.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // 返回按钮
            Button(action: onBack) {
                Text("Back to Navigation")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(appGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
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
        }
        .frame(maxWidth: 300)
        .padding(.vertical, 30)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 20)
    }
}
