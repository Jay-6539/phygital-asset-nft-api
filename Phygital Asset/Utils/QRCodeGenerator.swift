//
//  QRCodeGenerator.swift
//  Phygital Asset
//
//  QR码生成工具
//

import UIKit
import CoreImage.CIFilterBuiltins

class QRCodeGenerator {
    static let shared = QRCodeGenerator()
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    private init() {}
    
    /// 生成QR码图片
    func generateQRCode(from string: String, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        guard let data = string.data(using: .utf8) else {
            Logger.error("Failed to convert string to data")
            return nil
        }
        
        filter.message = data
        filter.correctionLevel = "H"  // 高纠错级别
        
        guard let outputImage = filter.outputImage else {
            Logger.error("Failed to generate QR code")
            return nil
        }
        
        // 缩放到指定大小
        let scaleX = size.width / outputImage.extent.width
        let scaleY = size.height / outputImage.extent.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            Logger.error("Failed to create CG image")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// 从TransferQRData生成QR码
    func generateTransferQRCode(from data: TransferQRData, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        guard let jsonString = data.toJSONString() else {
            Logger.error("Failed to encode transfer data")
            return nil
        }
        
        // 使用自定义URL scheme
        let qrString = "treasurehunt://transfer/\(jsonString)"
        
        Logger.debug("生成转让QR码")
        Logger.debug("  Transfer Code: \(data.transferCode)")
        
        return generateQRCode(from: qrString, size: size)
    }
}

