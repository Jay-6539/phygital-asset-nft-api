//
//  LoadingSkeletonView.swift
//  Treasure Hunt, Hong Kong Park
//
//  加载骨架屏组件
//

import SwiftUI

/// 骨架加载动画视图
struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGray5),
                        Color(.systemGray6),
                        Color(.systemGray5)
                    ]),
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating.toggle()
                }
            }
    }
}

/// Market统计卡片骨架
struct StatCardSkeleton: View {
    var body: some View {
        VStack(spacing: 6) {
            SkeletonView()
                .frame(width: 30, height: 30)
                .cornerRadius(15)
            
            SkeletonView()
                .frame(width: 40, height: 20)
                .cornerRadius(4)
            
            SkeletonView()
                .frame(width: 50, height: 12)
                .cornerRadius(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

/// Market建筑卡片骨架
struct BuildingCardSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            // 排名圆形
            SkeletonView()
                .frame(width: 44, height: 44)
                .cornerRadius(22)
            
            VStack(alignment: .leading, spacing: 4) {
                SkeletonView()
                    .frame(width: 150, height: 16)
                    .cornerRadius(4)
                
                SkeletonView()
                    .frame(width: 100, height: 12)
                    .cornerRadius(3)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

/// Market用户行骨架
struct UserRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            // 排名
            SkeletonView()
                .frame(width: 36, height: 36)
                .cornerRadius(18)
            
            // 头像
            SkeletonView()
                .frame(width: 44, height: 44)
                .cornerRadius(22)
            
            VStack(alignment: .leading, spacing: 4) {
                SkeletonView()
                    .frame(width: 120, height: 16)
                    .cornerRadius(4)
                
                SkeletonView()
                    .frame(width: 150, height: 12)
                    .cornerRadius(3)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                SkeletonView()
                    .frame(width: 40, height: 20)
                    .cornerRadius(4)
                
                SkeletonView()
                    .frame(width: 35, height: 10)
                    .cornerRadius(3)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 12) {
            StatCardSkeleton()
            StatCardSkeleton()
            StatCardSkeleton()
        }
        .padding()
        
        BuildingCardSkeleton()
            .padding(.horizontal)
        
        UserRowSkeleton()
            .padding(.horizontal)
    }
    .background(Color(.systemGroupedBackground))
}

