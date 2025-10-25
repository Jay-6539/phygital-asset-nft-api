//
//  OvalOfficeCheckInRow.swift
//  Treasure Hunt, Hong Kong Park
//
//  Created by AI Assistant on 2024
//

import SwiftUI

struct OvalOfficeCheckInRow: View {
    let checkIn: OvalOfficeCheckIn
    let appGreen: Color
    
    @State private var image: UIImage? = nil
    @State private var isLoadingImage: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 时间和Grid坐标
            HStack {
                Text(checkIn.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "map")
                        .font(.caption)
                        .foregroundColor(appGreen)
                    Text("Grid (\(checkIn.gridX), \(checkIn.gridY))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Asset名称
            if let assetName = checkIn.assetName, !assetName.isEmpty {
                Text(assetName)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            // 描述
            if !checkIn.description.isEmpty {
                Text(checkIn.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // 图片
            if isLoadingImage {
                ProgressView()
                    .frame(height: 80)
            } else if let image = image {
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
            loadImageIfNeeded()
        }
    }
    
    private func loadImageIfNeeded() {
        guard let imageUrl = checkIn.imageUrl, !imageUrl.isEmpty, image == nil else {
            return
        }
        
        isLoadingImage = true
        
        Task {
            do {
                let loadedImage = try await OvalOfficeCheckInManager.shared.downloadImage(from: imageUrl)
                await MainActor.run {
                    self.image = loadedImage
                    self.isLoadingImage = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingImage = false
                }
                Logger.error("Failed to load image: \(error.localizedDescription)")
            }
        }
    }
}
