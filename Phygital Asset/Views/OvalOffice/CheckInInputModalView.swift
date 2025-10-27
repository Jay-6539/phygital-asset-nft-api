//
//  CheckInInputModalView.swift
//  Phygital Asset
//
//  Created by refactoring on 21/10/2025.
//

import SwiftUI

/// Check-in输入模态框 - 覆盖层版本
/// 用于导航界面中的Check-in输入，带有半透明背景覆盖层
struct CheckInInputModal: View {
    @Binding var assetName: String
    @Binding var assetImage: UIImage?
    @Binding var assetDescription: String
    let appGreen: Color
    @ObservedObject var nfcManager: NFCManager
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // 输入模态框
            AssetInputModal(
                assetName: $assetName,
                assetImage: $assetImage,
                assetDescription: $assetDescription,
                appGreen: appGreen,
                nfcManager: nfcManager,
                onCancel: onCancel
            )
            .frame(maxWidth: 400, maxHeight: 700)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}

