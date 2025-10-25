//
//  CongratulationsView.swift
//  Treasure Hunt, Hong Kong Park
//
//  简洁的Congratulations动画
//

import SwiftUI

struct CongratulationsView: View {
    let appGreen: Color
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var checkmarkScale: CGFloat = 0
    @State private var confettiOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 24) {
                // 对勾图标
                ZStack {
                    Circle()
                        .fill(appGreen)
                        .frame(width: 80, height: 80)
                        .shadow(color: appGreen.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkmarkScale)
                }
                .scaleEffect(scale)
                
                // Congratulations文字
                VStack(spacing: 8) {
                    Text("Congratulations!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Asset transfer completed")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(opacity)
                
                // 简洁的装饰元素
                HStack(spacing: 12) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(appGreen.opacity(0.6))
                            .frame(width: 8, height: 8)
                            .offset(y: confettiOpacity * 20 * CGFloat(index % 2 == 0 ? -1 : 1))
                    }
                }
                .opacity(confettiOpacity)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 15)
            )
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // 动画序列
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // 延迟显示对勾
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.2)) {
                checkmarkScale = 1.0
            }
            
            // 装饰元素动画
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                confettiOpacity = 1.0
            }
            
            // 2秒后自动消失
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
            scale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

#Preview {
    CongratulationsView(
        appGreen: .green,
        onDismiss: {}
    )
}

