//
//  AssetInputModalView.swift
//  Phygital Asset
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
    @State private var localImage: UIImage? = nil // 本地图片缓存，避免直接更新binding导致Metal冲突
    @State private var isProcessingPhoto = false // 防止重复调用相机
    
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
                        .frame(width: 44, height: 44)
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
                                showingPhotoOptions = true
                            }) {
                                if let image = localImage ?? assetImage {
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
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $localImage, sourceType: sourceType)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    print("📸 ImagePicker onDisappear - resetting states")
                    print("📸   showingImagePicker: \(showingImagePicker)")
                    print("📸   showingCamera: \(showingCamera)")
                    
                    // 延迟重置状态，确保sheet完全关闭
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.showingImagePicker = false
                        self.showingCamera = false
                        self.isProcessingPhoto = false
                    }
                }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $localImage, sourceType: sourceType)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    print("📸 Camera sheet onDisappear - resetting states")
                    
                    // 延迟重置状态，确保sheet完全关闭
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.showingImagePicker = false
                        self.showingCamera = false
                        self.isProcessingPhoto = false
                    }
                }
        }
        .onChange(of: localImage) { oldValue, newValue in
            // 图片选择完成后，延迟更新到binding，避免Metal冲突
            if newValue != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.assetImage = newValue
                    // 确保在处理完成后重置标志
                    self.isProcessingPhoto = false
                }
            }
        }
        .confirmationDialog("Select Photo", isPresented: $showingPhotoOptions, titleVisibility: .visible) {
            Button("Upload Photo") {
                guard !isProcessingPhoto else { return }
                isProcessingPhoto = true
                sourceType = .photoLibrary
                showingImagePicker = true
            }
            
            Button("Take Photo") {
                print("📸 Take Photo button tapped, isProcessingPhoto: \(isProcessingPhoto)")
                guard !isProcessingPhoto else { 
                    print("📸 ❌ Already processing photo, ignoring")
                    return 
                }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    print("📸 ✅ Setting up camera")
                    isProcessingPhoto = true
                    sourceType = .camera
                    showingCamera = true
                } else {
                    print("📸 ❌ Camera not available")
                    showCameraUnavailableAlert = true
                }
            }
            
            Button("Cancel", role: .cancel) {
                isProcessingPhoto = false
            }
        }
        .alert("Camera Unavailable", isPresented: $showCameraUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your device camera is not available or permission is restricted.")
        }
        .onAppear {
            // 初始化显示标题和本地图片缓存
            displayTitle = assetName.isEmpty ? "Asset Information" : assetName
            localImage = assetImage
        }
    }
}


