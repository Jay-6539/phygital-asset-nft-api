//
//  ImageCacheManager.swift
//  Treasure Hunt, Hong Kong Park
//
//  图片缓存管理器 - 避免重复下载图片
//

import UIKit
import SwiftUI

class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL?
    
    private init() {
        // 设置缓存限制
        cache.countLimit = 100 // 最多缓存100张图片
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // 获取缓存目录
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ImageCache")
        
        // 创建缓存目录
        if let cacheDir = cacheDirectory {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
        
        Logger.debug("🖼️ ImageCache initialized")
    }
    
    // MARK: - 内存缓存
    
    /// 从内存缓存获取图片
    func getFromMemory(url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }
    
    /// 保存图片到内存缓存
    func saveToMemory(image: UIImage, url: String) {
        let cost = image.jpegData(compressionQuality: 0.8)?.count ?? 0
        cache.setObject(image, forKey: url as NSString, cost: cost)
    }
    
    // MARK: - 磁盘缓存
    
    /// 从磁盘缓存获取图片
    func getFromDisk(url: String) -> UIImage? {
        guard let cacheDirectory = cacheDirectory else { return nil }
        
        let fileName = url.md5Hash
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        // 同时保存到内存缓存
        saveToMemory(image: image, url: url)
        
        return image
    }
    
    /// 保存图片到磁盘缓存
    func saveToDisk(image: UIImage, url: String) {
        guard let cacheDirectory = cacheDirectory,
              let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let fileName = url.md5Hash
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        try? data.write(to: fileURL)
    }
    
    // MARK: - 统一接口
    
    /// 获取图片（先查内存，再查磁盘）
    func getImage(url: String) -> UIImage? {
        // 先查内存
        if let image = getFromMemory(url: url) {
            return image
        }
        
        // 再查磁盘
        if let image = getFromDisk(url: url) {
            return image
        }
        
        return nil
    }
    
    /// 保存图片（同时保存到内存和磁盘）
    func saveImage(image: UIImage, url: String) {
        saveToMemory(image: image, url: url)
        
        // 异步保存到磁盘，不阻塞主线程
        DispatchQueue.global(qos: .utility).async {
            self.saveToDisk(image: image, url: url)
        }
    }
    
    /// 清除所有缓存
    func clearCache() {
        cache.removeAllObjects()
        
        guard let cacheDirectory = cacheDirectory else { return }
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        Logger.debug("🗑️ Image cache cleared")
    }
}

// MARK: - String Hash Extension (SHA256 instead of MD5)
import CryptoKit

extension String {
    var md5Hash: String {
        // Note: Keep the name 'md5Hash' for backward compatibility
        // but use SHA256 for security
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

