//
//  CongratulationsView.swift
//  Treasure Hunt, Hong Kong Park
//
//  精美的Congratulations动画
//

import SwiftUI

struct CongratulationsView: View {
    let appGreen: Color
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkRotation: Double = 0
    @State private var ringScale: CGFloat = 0
    @State private var particleStates: [ParticleState] = []
    @State private var glowOpacity: Double = 0
    
    struct ParticleState {
        var offset: CGSize
        var opacity: Double
        var scale: CGFloat
    }
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            ZStack {
                // 粒子效果
                ForEach(0..<12, id: \.self) { index in
                    if index < particleStates.count {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [appGreen, appGreen.opacity(0.5)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 6, height: 6)
                            .offset(particleStates[index].offset)
                            .opacity(particleStates[index].opacity)
                            .scaleEffect(particleStates[index].scale)
                    }
                }
                
                VStack(spacing: 28) {
                    // 成功图标
                    ZStack {
                        // 外圈发光效果
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [appGreen.opacity(0.4), appGreen.opacity(0)],
                                    center: .center,
                                    startRadius: 40,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 140, height: 140)
                            .opacity(glowOpacity)
                        
                        // 扩散圆环
                        Circle()
                            .strokeBorder(appGreen.opacity(0.3), lineWidth: 2)
                            .frame(width: 100, height: 100)
                            .scaleEffect(ringScale)
                            .opacity(1.0 - Double(ringScale) * 0.5)
                        
                        // 主圆形
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [appGreen, appGreen.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 90, height: 90)
                            .shadow(color: appGreen.opacity(0.5), radius: 20, x: 0, y: 10)
                        
                        // 对勾
                        Image(systemName: "checkmark")
                            .font(.system(size: 45, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(checkmarkScale)
                            .rotationEffect(.degrees(checkmarkRotation))
                    }
                    .scaleEffect(scale)
                    
                    // 文字
                    VStack(spacing: 10) {
                        Text("Congratulations!")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Asset transfer completed")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .opacity(opacity)
                }
                .padding(50)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.15), radius: 40, x: 0, y: 20)
                )
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // 初始化粒子状态
            particleStates = (0..<12).map { index in
                let angle = Double(index) * 30.0
                let distance: CGFloat = 80
                return ParticleState(
                    offset: .zero,
                    opacity: 0,
                    scale: 0.5
                )
            }
            
            // 主动画序列
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // 对勾动画
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15)) {
                checkmarkScale = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.3).delay(0.15)) {
                checkmarkRotation = 360
            }
            
            // 圆环扩散
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                ringScale = 2.0
            }
            
            // 发光效果
            withAnimation(.easeInOut(duration: 0.8).delay(0.1)) {
                glowOpacity = 1.0
            }
            
            // 粒子动画
            for i in 0..<12 {
                let angle = Double(i) * 30.0
                let radian = angle * .pi / 180
                let distance: CGFloat = 100
                
                withAnimation(
                    .easeOut(duration: 0.8)
                    .delay(0.3 + Double(i) * 0.03)
                ) {
                    particleStates[i].offset = CGSize(
                        width: cos(radian) * distance,
                        height: sin(radian) * distance
                    )
                    particleStates[i].opacity = 1.0
                    particleStates[i].scale = 1.0
                }
                
                withAnimation(
                    .easeIn(duration: 0.4)
                    .delay(0.8 + Double(i) * 0.03)
                ) {
                    particleStates[i].opacity = 0
                    particleStates[i].scale = 0.3
                }
            }
            
            // 2.5秒后自动消失
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                dismiss()
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            opacity = 0
            scale = 0.85
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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

