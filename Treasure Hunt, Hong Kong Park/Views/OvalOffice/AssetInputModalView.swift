//
//  AssetInputModalView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Created by refactoring on 21/10/2025.
//

import SwiftUI
import UIKit

/// Asset信息输入弹窗组件
/// 用于注册新Asset或Check-in时输入Asset信息
struct AssetInputModal: View {
    @Binding var assetName: String
    @Binding var assetImage: UIImage?
    @Binding var assetDescription: String
    let appGreen: Color
    @ObservedObject var nfcManager: NFCManager
    let onCancel: () -> Void
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showCameraUnavailableAlert = false
    @State private var displayTitle: String = "Asset Information"
    @State private var displayInputText: String = "INPUT"
    @State private var showingPhotoOptions = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Spacer()
                
                Text(displayTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            
            Divider()
            
            // 主要内容区域
            ScrollView {
                    VStack(spacing: 16) {
                        // 名称输入框
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Asset Name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("max 8 characters", text: $assetName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                                .onChange(of: assetName) { _, newValue in
                                    if newValue.count > 8 {
                                        assetName = String(newValue.prefix(8))
                                    }
                                }
                        }
                        
                        // 照片上传/拍摄
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Photo")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // 可点击的照片框，占据整个宽度
                            Button(action: {
                                Logger.debug("📸 照片按钮被点击")
                                Logger.debug("当前 showingPhotoOptions: \(showingPhotoOptions)")
                                showingPhotoOptions = true
                                Logger.debug("设置后 showingPhotoOptions: \(showingPhotoOptions)")
                            }) {
                                if let image = assetImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 300)
                                        .clipped()
                                        .cornerRadius(12)
                                        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 300)
                                        .overlay(
                                            VStack(spacing: 12) {
                                                Image(systemName: "photo")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.gray)
                                                Text("Tap to add photo")
                                                    .font(.headline)
                                                    .foregroundColor(.gray)
                                            }
                                        )
                                        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // 文字描述输入框
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter description", text: $assetDescription, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                                .lineLimit(6...12)
                                .frame(minHeight: 120)
                        }
                        .padding(.top, 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
                
                // 底部按钮区域
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 16) {
                        // 注册模式和Check-in模式都显示"TAP NFC again to Check out"按钮
                        Button("TAP NFC again to Check out") {
                            // 根据当前阶段触发不同的NFC扫描
                            if nfcManager.currentPhase == .checkInInput {
                                // Check-in模式：触发第二次check-in扫描
                                nfcManager.startCheckInSecondScan()
                            } else {
                                // 注册模式：触发第二次注册扫描
                                nfcManager.startSecondScan()
                            }
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(appGreen)
                        .frame(maxWidth: .infinity, minHeight: 44)
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
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
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
                        .disabled(nfcManager.currentPhase == .secondScan || nfcManager.currentPhase == .checkInSecondScan)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color(.systemBackground))
            }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .sheet(isPresented: Binding(
            get: { 
                let showing = showingImagePicker || showingCamera
                if showing {
                    Logger.debug("📸 ImagePicker sheet 将显示: picker=\(showingImagePicker), camera=\(showingCamera)")
                }
                return showing
            },
            set: { newValue in
                Logger.debug("📸 ImagePicker sheet 状态变化: \(newValue)")
                if !newValue {
                    // 延迟重置，确保相机完全关闭
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.showingImagePicker = false
                        self.showingCamera = false
                        Logger.debug("📸 重置 showingImagePicker 和 showingCamera")
                    }
                }
            }
        )) {
            ImagePicker(image: $assetImage, sourceType: sourceType)
                .onAppear {
                    Logger.debug("📸 ImagePicker 已显示，sourceType: \(sourceType == .camera ? "Camera" : "PhotoLibrary")")
                }
                .onDisappear {
                    Logger.debug("📸 ImagePicker 已消失")
                    // 确保sheet关闭后状态被重置
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showingImagePicker = false
                        self.showingCamera = false
                        Logger.debug("📸 延迟重置完成")
                    }
                }
        }
        .actionSheet(isPresented: $showingPhotoOptions) {
            ActionSheet(
                title: Text("Select Photo"),
                buttons: [
                    .default(Text("Upload Photo")) {
                        Logger.debug("📸 用户选择：上传照片")
                        // 延迟打开，避免与 actionSheet 关闭冲突
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.sourceType = .photoLibrary
                            self.showingImagePicker = true
                            Logger.debug("📸 设置 showingImagePicker = true")
                        }
                    },
                    .default(Text("Take Photo")) {
                        Logger.debug("📸 用户选择：拍照")
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Logger.debug("📸 相机可用")
                            // 延迟打开相机，避免与 actionSheet 关闭冲突
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.sourceType = .camera
                                self.showingCamera = true
                                Logger.debug("📸 设置 showingCamera = true")
                            }
                        } else {
                            Logger.error("📸 相机不可用")
                            showCameraUnavailableAlert = true
                        }
                    },
                    .cancel(Text("Cancel")) {
                        Logger.debug("📸 用户取消选择照片")
                    }
                ]
            )
        }
        .onChange(of: showingPhotoOptions) { oldValue, newValue in
            Logger.debug("📸 showingPhotoOptions 变化: \(oldValue) -> \(newValue)")
        }
        .onChange(of: showingImagePicker) { oldValue, newValue in
            Logger.debug("📸 showingImagePicker 变化: \(oldValue) -> \(newValue)")
        }
        .onChange(of: showingCamera) { oldValue, newValue in
            Logger.debug("📸 showingCamera 变化: \(oldValue) -> \(newValue)")
        }
        .onChange(of: assetImage) { oldValue, newValue in
            Logger.debug("📸 assetImage 变化: \(oldValue != nil ? "有图片" : "无") -> \(newValue != nil ? "有图片" : "无")")
            if newValue != nil {
                Logger.success("📸 照片已选择/拍摄成功！")
            }
        }
        .alert("Camera Unavailable", isPresented: $showCameraUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your device camera is not available or permission is restricted.")
        }
        .onAppear {
            // 初始化显示标题
            displayTitle = assetName.isEmpty ? "Asset Information" : assetName
        }
    }
}


