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
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // 在主线程上更新图片
            DispatchQueue.main.async {
                if let uiImage = info[.originalImage] as? UIImage {
                    self.parent.image = uiImage
                }
                
                // 延迟关闭，确保图片已设置
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.parent.presentationMode.wrappedValue.dismiss()
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // 在主线程上关闭
            DispatchQueue.main.async {
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

