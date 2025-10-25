//
//  ImagePicker.swift
//  Treasure Hunt, Hong Kong Park
//
//  图片选择器 - UIImagePickerController 的 SwiftUI 包装
//

import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 防止重复设置sourceType
        if uiViewController.sourceType != sourceType {
            uiViewController.sourceType = sourceType
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("📸 ImagePickerController didFinishPicking")
            
            // 验证并更新图片
            if let uiImage = info[.originalImage] as? UIImage {
                print("📸 Got image: size=\(uiImage.size), scale=\(uiImage.scale)")
                
                // 验证图片尺寸有效
                guard uiImage.size.width > 0 && uiImage.size.height > 0 else {
                    print("📸 ❌ Invalid image dimensions")
                    DispatchQueue.main.async {
                        self.parent.presentationMode.wrappedValue.dismiss()
                    }
                    return
                }
                
                // 先 dismiss picker，避免 Metal 渲染冲突
                DispatchQueue.main.async {
                    self.parent.presentationMode.wrappedValue.dismiss()
                    
                    // 延迟更新图片，确保 picker 完全关闭后再更新
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.parent.image = uiImage
                        print("📸 ✅ Image updated after dismiss")
                    }
                }
            } else {
                // 没有图片，直接关闭
                DispatchQueue.main.async {
                    self.parent.presentationMode.wrappedValue.dismiss()
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            DispatchQueue.main.async {
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

