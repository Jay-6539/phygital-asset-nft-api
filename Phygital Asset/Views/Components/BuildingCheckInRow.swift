//
//  BuildingCheckInRow.swift
//  Phygital Asset
//
//  Created by AI Assistant on 2024
//

import SwiftUI

struct BuildingCheckInRow: View {
    let checkIn: BuildingCheckIn
    @State private var image: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 用户名和时间
            HStack {
                Text(checkIn.username)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(checkIn.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Asset名称（如果有）
            if let assetName = checkIn.assetName, !assetName.isEmpty {
                Text(assetName)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(appGreen)
            }
            
            // 描述
            if !checkIn.description.isEmpty {
                Text(checkIn.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // 图片（从本地加载）
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 80)
                    .clipped()
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            loadLocalImage()
        }
    }
    
    private func loadLocalImage() {
        // 从 Supabase 加载图片
        Logger.debug("Loading image for check-in: \(checkIn.id)")
        
        if let imageUrl = checkIn.imageUrl, !imageUrl.isEmpty {
            Logger.debug("Image URL found: \(imageUrl)")
            Task {
                do {
                    if let loadedImage = try await BuildingCheckInManager.shared.downloadImage(from: imageUrl) {
                        Logger.success("✅ Image loaded successfully")
                        await MainActor.run {
                            self.image = loadedImage
                        }
                    } else {
                        Logger.warning("⚠️ Image URL valid but image is nil")
                    }
                } catch {
                    Logger.error("❌ Failed to load image: \(error.localizedDescription)")
                }
            }
        } else {
            Logger.debug("No image URL for this check-in")
        }
    }
}
