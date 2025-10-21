//
//  GlassButton.swift
//  Treasure Hunt, Hong Kong Park
//
//  Created by refactoring on 21/10/2025.
//

import SwiftUI

// Apple Glass风格按钮
struct GlassButton: View {
    let title: String
    let action: () -> Void
    let appGreen: Color
    var isDisabled: Bool = false
    var isLoading: Bool = false
    var loadingText: String = "Loading..."
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: appGreen))
                        .scaleEffect(0.8)
                }
                Text(isLoading ? loadingText : title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(appGreen)
            }
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
        .disabled(isDisabled || isLoading)
    }
}

// 预览
#Preview {
    VStack(spacing: 20) {
        GlassButton(
            title: "Continue",
            action: {},
            appGreen: Color(red: 45/255, green: 156/255, blue: 73/255)
        )
        
        GlassButton(
            title: "Loading",
            action: {},
            appGreen: Color(red: 45/255, green: 156/255, blue: 73/255),
            isLoading: true
        )
        
        GlassButton(
            title: "Disabled",
            action: {},
            appGreen: Color(red: 45/255, green: 156/255, blue: 73/255),
            isDisabled: true
        )
    }
    .padding()
}

