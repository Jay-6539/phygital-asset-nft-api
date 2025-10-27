//
//  MapLogoView.swift
//  Phygital Asset
//
//  地图Logo视图 - 显示宝藏寻宝路线图标
//

import SwiftUI

struct MapLogoView: View {
    var body: some View {
        ZStack {
            // 外框
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(appGreen, lineWidth: 2)

            // 虚线路径（宝藏路线）
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                Path { p in
                    p.move(to: CGPoint(x: w * 0.15, y: h * 0.80))
                    p.addCurve(
                        to: CGPoint(x: w * 0.55, y: h * 0.40),
                        control1: CGPoint(x: w * 0.30, y: h * 0.65),
                        control2: CGPoint(x: w * 0.45, y: h * 0.50)
                    )
                    p.addCurve(
                        to: CGPoint(x: w * 0.80, y: h * 0.20),
                        control1: CGPoint(x: w * 0.65, y: h * 0.30),
                        control2: CGPoint(x: w * 0.72, y: h * 0.22)
                    )
                }
                .stroke(
                    appGreen,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [4, 4])
                )

                // 起点小圆点
                Circle()
                    .stroke(appGreen, lineWidth: 2)
                    .frame(width: 6, height: 6)
                    .position(x: w * 0.15, y: h * 0.80)

                // 终点 X 标记
                Path { p in
                    p.move(to: CGPoint(x: w * 0.80 - 6, y: h * 0.20 - 6))
                    p.addLine(to: CGPoint(x: w * 0.80 + 6, y: h * 0.20 + 6))
                    p.move(to: CGPoint(x: w * 0.80 + 6, y: h * 0.20 - 6))
                    p.addLine(to: CGPoint(x: w * 0.80 - 6, y: h * 0.20 + 6))
                }
                .stroke(appGreen, lineWidth: 2)
            }
            .padding(10)
        }
        .frame(width: 80, height: 80)
    }
}

