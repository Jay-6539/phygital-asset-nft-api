//
//  GridOverlayView.swift
//  Phygital Asset
//
//  网格覆盖层视图 - 在 Oval Office 平面图上显示网格
//

import SwiftUI

struct GridOverlayView: View {
    let scale: CGFloat
    let offset: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            let imageSize = UIImage(named: "OvalOfficePlan")?.size ?? .zero
            let viewSize = geometry.size
            
            // 计算图片在当前视图中的实际显示尺寸
            let scaledImageWidth = imageSize.width * scale
            let scaledImageHeight = imageSize.height * scale
            
            // 计算图片在视图中的偏移量（居中显示）
            let offsetX = (viewSize.width - scaledImageWidth) / 2
            let offsetY = (viewSize.height - scaledImageHeight) / 2
            
            // 创建网格
            Path { path in
                let gridSize: CGFloat = 5.0 * scale // 5像素的网格，按比例缩放
                
                // 垂直网格线
                var x = offsetX + offset.width
                while x <= offsetX + scaledImageWidth + offset.width {
                    path.move(to: CGPoint(x: x, y: offsetY + offset.height))
                    path.addLine(to: CGPoint(x: x, y: offsetY + scaledImageHeight + offset.height))
                    x += gridSize
                }
                
                // 水平网格线
                var y = offsetY + offset.height
                while y <= offsetY + scaledImageHeight + offset.height {
                    path.move(to: CGPoint(x: offsetX + offset.width, y: y))
                    path.addLine(to: CGPoint(x: offsetX + scaledImageWidth + offset.width, y: y))
                    y += gridSize
                }
            }
            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5) // 淡灰色细线
        }
    }
}

