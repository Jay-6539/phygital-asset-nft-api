//
//  BidNotificationButton.swift
//  Treasure Hunt, Hong Kong Park
//
//  Bid通知按钮（显示在Market右上角）
//

import SwiftUI

struct BidNotificationButton: View {
    let unreadCount: Int
    let appGreen: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                // 主按钮
                ZStack {
                    Circle()
                        .fill(Color.white)
                    
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(unreadCount > 0 ? appGreen : .gray)
                }
                .frame(width: 36, height: 36)
                .shadow(radius: 2)
                
                // 绿色数字徽章
                if unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(appGreen)
                            .frame(width: 18, height: 18)
                        
                        if unreadCount < 100 {
                            Text("\(unreadCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("99+")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .offset(x: 4, y: -4)
                    .shadow(color: appGreen.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        BidNotificationButton(unreadCount: 0, appGreen: .green, action: {})
        BidNotificationButton(unreadCount: 3, appGreen: .green, action: {})
        BidNotificationButton(unreadCount: 99, appGreen: .green, action: {})
        BidNotificationButton(unreadCount: 100, appGreen: .green, action: {})
    }
    .padding()
}

