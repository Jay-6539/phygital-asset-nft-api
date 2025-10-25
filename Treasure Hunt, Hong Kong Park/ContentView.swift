//
//  ContentView.swift
//  Treasure Hunt, Hong Kong Park
//
//  Created by Jay on 19/8/2025.
//

import SwiftUI
import MapKit
import CoreLocation
import AppTrackingTransparency
import CoreNFC
import FacebookLogin
import FacebookCore
import GoogleSignIn
import AuthenticationServices

// 全局绿色定义
let appGreen = Color(red: 45/255, green: 156/255, blue: 73/255)

// 登录方式枚举
enum LoginMethod {
    case username       // 用户名密码登录
    case apple         // Apple登录
    case facebook      // Facebook登录
    case google        // Google登录
}

// 社交平台枚举
enum SocialProvider {
    case apple
    case facebook
    case google
    
    var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .facebook: return "Facebook"
        case .google: return "Google"
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        Logger.location("LocationManager: Requesting location...")
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Logger.location("LocationManager: Got location: \(location.coordinate)")
        self.location = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.location("LocationManager: Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Logger.location("LocationManager: Authorization status changed to: \(status.rawValue)")
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            Logger.location("LocationManager: Authorization granted, requesting location...")
            locationManager.requestLocation()
        } else if status == .denied {
            Logger.location("LocationManager: Location access denied")
        }
    }
}

// NFC扫描阶段枚举
enum NFCScanPhase {
    case idle               // 未开始
    case firstScan          // 第一次扫描（开始注册）
    case awaitingInput      // 等待用户输入Asset信息
    case secondScan         // 第二次扫描（完成注册）
    case completed          // 完成
    case nfcAlreadyRegistered // NFC已被注册（新增）
    case checkInFirstScan   // Check-in第一次扫描（验证Asset）
    case checkInInput       // 等待用户输入Check-in信息
    case checkInSecondScan  // Check-in第二次扫描（确认完成）
    case checkInCompleted   // Check-in完成
    case exploreScan        // 探索扫描（读取任何NFC标签）
}

// NFC管理器 - 支持读写功能
class NFCManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var isNFCAvailable: Bool = false
    @Published var nfcMessage: String = ""
    @Published var didDetectNFC: Bool = false
    @Published var currentPhase: NFCScanPhase = .idle
    @Published var assetUUID: String = "" // 存储Asset的唯一标识符
    @Published var registeredAssetInfo: AssetInfo? = nil // 存储已注册NFC的Asset信息
    
    private var nfcSession: NFCNDEFReaderSession?
    var onNFCDetected: (() -> Void)?
    var onNFCError: ((String) -> Void)?
    var onNFCAlreadyRegistered: ((AssetInfo) -> Void)? // 新增：NFC已注册回调
    private var customAlertMessage: String = ""
    private var customSuccessMessage: String = ""
    private var shouldWriteToTag: Bool = false
    private var dataToWrite: String = ""
    
    override init() {
        super.init()
        isNFCAvailable = NFCNDEFReaderSession.readingAvailable
    }
    
    // 生成20位随机UUID
    private func generateAssetUUID() -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return String(uuid.prefix(20))
    }
    
    // 开始第一次NFC扫描（生成UUID并写入）
    func startFirstScan() {
        currentPhase = .firstScan
        customAlertMessage = "Hold your iPhone near the NFC tag to register"
        customSuccessMessage = "UUID written! Tap on map to select location."
        
        // 生成20位随机UUID
        assetUUID = generateAssetUUID()
        dataToWrite = assetUUID
        shouldWriteToTag = true
        
        Logger.debug("Generated Asset UUID: \(assetUUID)")
        startScanning()
    }
    
    // 开始第二次NFC扫描（读取UUID验证）
    func startSecondScan() {
        currentPhase = .secondScan
        customAlertMessage = "Hold your iPhone near the NFC tag to check out"
        customSuccessMessage = "UUID verified! Registration completed."
        shouldWriteToTag = false
        startScanning()
    }
    
    // 开始Check-in第一次扫描（验证已注册的Asset）
    func startCheckInFirstScan(expectedUUID: String) {
        currentPhase = .checkInFirstScan
        assetUUID = expectedUUID  // 设置期望的UUID
        customAlertMessage = "Hold your iPhone near the Asset's NFC tag to check in"
        customSuccessMessage = "UUID verified! You can now add your description."
        shouldWriteToTag = false
        startScanning()
        Logger.debug("Starting check-in first scan for UUID: \(expectedUUID)")
    }
    
    // 开始Check-in第二次扫描（确认完成check-in）
    func startCheckInSecondScan() {
        currentPhase = .checkInSecondScan
        customAlertMessage = "Hold your iPhone near the NFC tag to check out"
        customSuccessMessage = "NFC tag detected! Check-in completed."
        shouldWriteToTag = false
        startScanning()
        Logger.debug("Starting check-in second scan to confirm")
    }
    
    // 开始探索扫描（读取任何NFC标签）
    func startExploreScan() {
        currentPhase = .exploreScan
        customAlertMessage = "Hold your iPhone near the NFC tag to explore"
        customSuccessMessage = "NFC tag detected! Exploring asset."
        shouldWriteToTag = false
        startScanning()
        Logger.debug("Starting explore scan to read any NFC tag")
    }
    
    // 直接启动Check-in输入模式（跳过NFC验证）
    func startDirectCheckIn() {
        currentPhase = .checkInInput
        Logger.debug("Starting direct check-in input mode (no NFC verification required)")
        
        // 直接触发输入模式
        DispatchQueue.main.async {
            self.didDetectNFC = true
            self.nfcMessage = "Ready for check-in input"
            self.onNFCDetected?()
        }
    }
    
    // 开始NFC扫描（内部方法）
    private func startScanning() {
        guard NFCNDEFReaderSession.readingAvailable else {
            nfcMessage = "NFC is not available on this device"
            Logger.nfc("NFC not available on this device")
            return
        }
        
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        nfcSession?.alertMessage = customAlertMessage
        nfcSession?.begin()
        Logger.nfc("NFC scanning started for phase: \(currentPhase)")
    }
    
    // 读取任何NFC标签（探索模式）
    private func readAnyNFCTag(tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        Logger.nfc("Reading any NFC tag for exploration...")
        
        tag.readNDEF { message, error in
            if let error = error {
                Logger.error("Read error: \(error.localizedDescription)")
                session.invalidate(errorMessage: "Read error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.onNFCError?("Failed to read NFC tag: \(error.localizedDescription)")
                }
                return
            }
            
            guard let message = message else {
                Logger.warning("No NDEF message found on tag")
                session.alertMessage = "No data found on NFC tag"
                session.invalidate()
                DispatchQueue.main.async {
                    self.onNFCError?("No data found on NFC tag")
                }
                return
            }
            
            Logger.nfc("NFC tag read successfully for exploration")
            Logger.info("Found \(message.records.count) NDEF records")
            
            // 尝试从NDEF记录中读取UUID
            var readUUID: String? = nil
            for record in message.records {
                // wellKnownTypeTextPayload 格式: [语言代码长度(1 byte)][语言代码(2 bytes "en")][实际文本]
                // 所以我们需要跳过前3个字节
                Logger.debug("📦 NDEF record type: \(record.typeNameFormat.rawValue)")
                Logger.debug("📦 NDEF payload 长度: \(record.payload.count) bytes")
                
                if record.payload.count > 3 {
                    // 打印原始payload的十六进制表示以便调试
                    let hexString = record.payload.map { String(format: "%02X", $0) }.joined(separator: " ")
                    Logger.debug("📦 原始 NDEF payload (hex): \(hexString)")
                    
                    // Text Record格式分析：
                    // Byte 0: Status byte (包含编码和语言代码长度)
                    let statusByte = record.payload[0]
                    let isUTF16 = (statusByte & 0x80) != 0 // 最高位表示是否为UTF-16
                    let languageCodeLength = Int(statusByte & 0x3F) // 低6位是语言代码长度
                    Logger.debug("📦 语言代码长度: \(languageCodeLength) bytes")
                    Logger.debug("📦 编码格式: \(isUTF16 ? "UTF-16" : "UTF-8")")
                    
                    // 跳过 status byte + 语言代码
                    let textStartIndex = 1 + languageCodeLength
                    
                    if record.payload.count > textStartIndex {
                        let textData = record.payload.subdata(in: textStartIndex..<record.payload.count)
                        
                        // 根据编码格式选择解码方式
                        let encoding: String.Encoding = isUTF16 ? .utf16 : .utf8
                        
                        if let payload = String(data: textData, encoding: encoding) {
                            Logger.debug("📦 解析后的 NDEF payload: '\(payload)'")
                            let cleanPayload = payload.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            // 检查是否为有效的UUID（20个字符，全是字母数字）
                            if cleanPayload.count == 20 {
                                let alphanumericSet = CharacterSet.alphanumerics
                                if cleanPayload.unicodeScalars.allSatisfy({ alphanumericSet.contains($0) }) {
                                    readUUID = cleanPayload
                                    Logger.success("✅ 从NFC读取到有效UUID: \(readUUID!)")
                                    break
                                } else {
                                    Logger.warning("⚠️ Payload长度正确但包含非字母数字字符: '\(cleanPayload)'")
                                }
                            } else {
                                Logger.warning("⚠️ Payload长度不正确: \(cleanPayload.count) (期望20)")
                            }
                        } else {
                            Logger.warning("⚠️ 无法将payload解码为\(isUTF16 ? "UTF-16" : "UTF-8")字符串")
                        }
                    } else {
                        Logger.warning("⚠️ Text start index超出payload范围")
                    }
                } else {
                    Logger.warning("⚠️ NDEF payload 太短: \(record.payload.count) bytes")
                }
            }
            
            // 如果没有读取到UUID，说明是空白NFC标签
            if readUUID == nil {
                Logger.warning("⚠️ 空白NFC标签，正在生成并写入UUID...")
                
                // 生成新的UUID
                let newUUID = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(20).description
                readUUID = newUUID
                Logger.success("✅ 生成新UUID: \(newUUID)")
                
                // 将UUID写入到NFC标签
                guard let payload = NFCNDEFPayload.wellKnownTypeTextPayload(
                    string: newUUID,
                    locale: Locale(identifier: "en")
                ) else {
                    Logger.error("❌ 无法创建NDEF payload")
                    session.alertMessage = "空白标签，已生成UUID但无法写入"
                    
                    // 即使写入失败，仍使用生成的UUID
                    DispatchQueue.main.async {
                        self.assetUUID = newUUID
                        if self.currentPhase == .checkInFirstScan {
                            self.currentPhase = .checkInInput
                        }
                        self.didDetectNFC = true
                        self.onNFCDetected?()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        session.invalidate()
                    }
                    return
                }
                
                let ndefMessage = NFCNDEFMessage(records: [payload])
                
                // 写入UUID到标签
                tag.writeNDEF(ndefMessage) { error in
                    if let error = error {
                        Logger.error("❌ 写入UUID失败: \(error.localizedDescription)")
                        session.alertMessage = "UUID已生成但写入失败，请重试"
                    } else {
                        Logger.success("✅ UUID成功写入空白NFC标签！")
                        session.alertMessage = "空白NFC标签已初始化"
                    }
                    
                    DispatchQueue.main.async {
                        self.assetUUID = newUUID
                        Logger.success("✅ assetUUID 已设置为: \(self.assetUUID)")
                        
                        if self.currentPhase == .checkInFirstScan {
                            self.currentPhase = .checkInInput
                            Logger.debug("✅ Check-in第一次扫描完成，进入输入阶段")
                        }
                        
                        self.didDetectNFC = true
                        self.nfcMessage = "NFC tag detected successfully"
                        self.onNFCDetected?()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        session.invalidate()
                    }
                }
                return
            }
            
            // 显示成功消息（从标签读取到UUID的情况）
            session.alertMessage = self.customSuccessMessage
            
            DispatchQueue.main.async {
                // 设置读取到的UUID
                self.assetUUID = readUUID ?? ""
                Logger.success("✅ assetUUID 已设置为: \(self.assetUUID)")
                
                // 根据当前阶段更新下一个阶段
                if self.currentPhase == .checkInFirstScan {
                    self.currentPhase = .checkInInput
                    Logger.debug("✅ Check-in第一次扫描完成，进入输入阶段")
                }
                
                self.didDetectNFC = true
                self.nfcMessage = "NFC tag detected successfully"
                self.onNFCDetected?()
            }
            
            // 延迟关闭会话
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                session.invalidate()
            }
        }
    }
    
    // 停止NFC扫描
    func stopScanning() {
        nfcSession?.invalidate()
        nfcSession = nil
        Logger.nfc("NFC scanning stopped")
    }
    
    // 重置状态
    func reset() {
        currentPhase = .idle
        didDetectNFC = false
        nfcMessage = ""
        assetUUID = ""
        dataToWrite = ""
        shouldWriteToTag = false
        stopScanning()
    }
    
    // 灵活的UUID匹配函数
    private func isUUIDMatch(readUUID: String, expectedUUID: String) -> Bool {
        // 完全匹配
        if readUUID == expectedUUID {
            return true
        }
        
        // 如果期望的UUID是数字ID（如"899"），尝试在读取的UUID中查找
        if expectedUUID.allSatisfy({ $0.isNumber }) {
            // 检查读取的UUID是否包含期望的数字ID
            if readUUID.contains(expectedUUID) {
                Logger.nfc("UUID partial match: '\(readUUID)' contains '\(expectedUUID)'")
                return true
            }
        }
        
        // 如果读取的UUID是十六进制格式，尝试提取数字部分
        if readUUID.count > expectedUUID.count {
            // 尝试从十六进制UUID中提取数字部分
            let numericPart = readUUID.filter { $0.isNumber }
            if numericPart == expectedUUID {
                Logger.nfc("UUID numeric match: extracted '\(numericPart)' from '\(readUUID)'")
                return true
            }
        }
        
        Logger.error("UUID no match: '\(readUUID)' vs '\(expectedUUID)'")
        return false
    }
    
    // NFCNDEFReaderSessionDelegate 方法 - 用于快速检测
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // 这个方法用于快速检测，实际读写在 didDetect tags 中进行
        Logger.nfc("NFC tag detected with messages: \(messages.count)")
    }
    
    // 检测到NFC标签（支持读写）
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No NFC tag detected")
            return
        }
        
        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
                return
            }
            
            // 查询标签状态
            tag.queryNDEFStatus { status, capacity, error in
                if let error = error {
                    session.invalidate(errorMessage: "Query error: \(error.localizedDescription)")
                    return
                }
                
                Logger.nfc("NFC tag status: \(status.rawValue), capacity: \(capacity)")
                
                // 状态说明：0=readWrite, 1=readOnly, 2=notSupported
                let statusDescription: String
                switch status.rawValue {
                case 0:
                    statusDescription = "ReadWrite (0)"
                case 1:
                    statusDescription = "ReadOnly (1)"
                case 2:
                    statusDescription = "NotSupported (2)"
                default:
                    statusDescription = "Unknown (\(status.rawValue))"
                }
                Logger.nfc("NFC tag status description: \(statusDescription)")
                
                switch self.currentPhase {
                case .firstScan:
                    // 第一次扫描：先读取检查是否已注册，再决定是否写入UUID
                    Logger.debug("Checking if NFC tag is already registered...")
                    self.checkAndHandleNFCRegistration(tag: tag, session: session)
                    
                case .secondScan:
                    // 第二次扫描：读取并验证UUID
                    // 无论状态如何都尝试读取，因为某些标签的状态查询不准确
                    Logger.debug("Attempting to read UUID from tag...")
                    self.readAndVerifyUUID(tag: tag, session: session)
                    
                case .checkInFirstScan:
                    // Check-in第一次扫描：读取NFC UUID
                    Logger.debug("NFC tag detected for check-in (first scan), reading UUID...")
                    // 读取UUID
                    self.readAnyNFCTag(tag: tag, session: session)
                    
                case .checkInSecondScan:
                    // Check-in第二次扫描：读取NFC UUID确认
                    Logger.debug("Detected NFC tag for check-out confirmation, reading UUID...")
                    // 读取UUID确认
                    tag.readNDEF { message, error in
                        if let error = error {
                            Logger.error("Read error: \(error.localizedDescription)")
                            session.alertMessage = self.customSuccessMessage
                            session.invalidate()
                            DispatchQueue.main.async {
                                self.didDetectNFC = true
                                self.currentPhase = .checkInCompleted
                                self.onNFCDetected?()
                            }
                            return
                        }
                        
                        // 尝试读取UUID
                        var readUUID: String? = nil
                        if let message = message {
                            for record in message.records {
                                // Text Record格式分析
                                if record.payload.count > 3 {
                                    let statusByte = record.payload[0]
                                    let isUTF16 = (statusByte & 0x80) != 0
                                    let languageCodeLength = Int(statusByte & 0x3F)
                                    let textStartIndex = 1 + languageCodeLength
                                    
                                    if record.payload.count > textStartIndex {
                                        let textData = record.payload.subdata(in: textStartIndex..<record.payload.count)
                                        let encoding: String.Encoding = isUTF16 ? .utf16 : .utf8
                                        
                                        if let payload = String(data: textData, encoding: encoding) {
                                            let cleanPayload = payload.trimmingCharacters(in: .whitespacesAndNewlines)
                                            if cleanPayload.count == 20 {
                                                let alphanumericSet = CharacterSet.alphanumerics
                                                if cleanPayload.unicodeScalars.allSatisfy({ alphanumericSet.contains($0) }) {
                                                    readUUID = cleanPayload
                                                    Logger.success("✅ Check-out时读取到有效UUID: \(readUUID!)")
                                                    break
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 更新assetUUID（如果读取成功）
                        if let uuid = readUUID {
                            DispatchQueue.main.async {
                                self.assetUUID = uuid
                                Logger.success("✅ 更新assetUUID为: \(uuid)")
                            }
                        }
                        
                        session.alertMessage = self.customSuccessMessage
                        session.invalidate()
                        
                        DispatchQueue.main.async {
                            self.didDetectNFC = true
                            self.currentPhase = .checkInCompleted
                            self.onNFCDetected?()
                        }
                    }
                    
                case .exploreScan:
                    // 探索扫描：读取任何NFC标签
                    Logger.debug("Attempting to read any NFC tag for exploration...")
                    self.readAnyNFCTag(tag: tag, session: session)
                    
                default:
                    break
                }
            }
        }
    }
    
    // 写入UUID到NFC标签
    private func writeUUIDToTag(tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        Logger.debug("Creating NDEF payload for UUID: \(dataToWrite)")
        
        // 创建NDEF文本记录
        guard let payload = NFCNDEFPayload.wellKnownTypeTextPayload(
            string: dataToWrite,
            locale: Locale(identifier: "en")
        ) else {
            Logger.error("Failed to create NDEF payload")
            session.invalidate(errorMessage: "Failed to create payload")
            DispatchQueue.main.async {
                self.onNFCError?("Failed to create NFC payload")
            }
            return
        }
        
        Logger.nfc("NDEF payload created successfully")
        Logger.debug("Payload type: \(String(data: payload.type, encoding: .utf8) ?? "unknown")")
        Logger.debug("Payload length: \(payload.payload.count) bytes")
        Logger.debug("Payload (hex): \(payload.payload.map { String(format: "%02X", $0) }.joined(separator: " "))")
        
        let message = NFCNDEFMessage(records: [payload])
        
        Logger.debug("Writing UUID to NFC tag: '\(dataToWrite)'")
        Logger.nfc("UUID length: \(dataToWrite.count) characters")
        
        // 写入标签
        tag.writeNDEF(message) { error in
            if let error = error {
                Logger.error("Write error: \(error.localizedDescription)")
                session.invalidate(errorMessage: "Write error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.onNFCError?("Failed to write to NFC tag: \(error.localizedDescription)")
                }
                return
            }
            
            Logger.success("UUID written successfully to NFC tag!")
            Logger.debug("Written UUID: '\(self.dataToWrite)'")
            session.alertMessage = self.customSuccessMessage
            
            DispatchQueue.main.async {
                self.didDetectNFC = true
                self.nfcMessage = "UUID written successfully"
                self.currentPhase = .awaitingInput
                self.onNFCDetected?()
            }
            
            // 延迟关闭会话
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                session.invalidate()
            }
        }
    }
    
    // 检查NFC是否已注册（新方法）
    private func checkAndHandleNFCRegistration(tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        // 先尝试读取NFC上的UUID
        tag.readNDEF { message, error in
            if let error = error {
                // 读取失败，可能是空标签，允许写入
                Logger.warning("NFC tag is empty or read failed: \(error.localizedDescription)")
                Logger.success("Tag is empty, proceeding to write new UUID")
                self.writeUUIDToTag(tag: tag, session: session)
                return
            }
            
            guard let message = message, let record = message.records.first else {
                // 没有数据，允许写入
                Logger.success("Tag has no data, proceeding to write new UUID")
                self.writeUUIDToTag(tag: tag, session: session)
                return
            }
            
            // 解析已存在的UUID
            var existingUUID = ""
            if record.typeNameFormat == .nfcWellKnown,
               let type = String(data: record.type, encoding: .utf8),
               type == "T" {
                let statusByte = record.payload[0]
                let languageCodeLength = Int(statusByte & 0x3F)
                let isUTF16 = (statusByte & 0x80) != 0
                let textStartIndex = 1 + languageCodeLength
                let textData = record.payload.advanced(by: textStartIndex)
                
                if isUTF16 {
                    var actualTextData = textData
                    if textData.count >= 2 {
                        let bom = textData.prefix(2)
                        if bom[0] == 0xFF && bom[1] == 0xFE {
                            actualTextData = textData.advanced(by: 2)
                        }
                    }
                    existingUUID = String(data: actualTextData, encoding: .utf16LittleEndian) ?? ""
                } else {
                    existingUUID = String(data: textData, encoding: .utf8) ?? ""
                }
            }
            
            if existingUUID.isEmpty {
                // 无法读取UUID，允许写入
                Logger.success("Could not read UUID from tag, proceeding to write new UUID")
                self.writeUUIDToTag(tag: tag, session: session)
                return
            }
            
            // 找到了已存在的UUID，检查是否已注册
            Logger.debug("Found existing UUID on tag: \(existingUUID)")
            Logger.warning("This NFC tag is already registered!")
            
            session.alertMessage = "This NFC is already registered"
            session.invalidate()
            
            DispatchQueue.main.async {
                self.assetUUID = existingUUID
                self.currentPhase = .nfcAlreadyRegistered
                self.nfcMessage = "NFC already registered"
                
                // 触发回调，让UI显示提示
                self.onNFCAlreadyRegistered?(AssetInfo(
                    coordinate: GridCoordinate(x: 0, y: 0),
                    nfcUUID: existingUUID
                ))
            }
        }
    }
    
    // 读取并验证UUID
    private func readAndVerifyUUID(tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        tag.readNDEF { message, error in
            if let error = error {
                Logger.error("Read error: \(error.localizedDescription)")
                session.invalidate(errorMessage: "Read error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.onNFCError?("Failed to read from NFC tag: \(error.localizedDescription)")
                }
                return
            }
            
            guard let message = message else {
                Logger.error("No NDEF message found on tag")
                session.invalidate(errorMessage: "No data found on tag. Please scan the tag you used in first scan.")
                DispatchQueue.main.async {
                    self.onNFCError?("NFC tag is empty or not formatted correctly")
                }
                return
            }
            
            Logger.success("NDEF message found with \(message.records.count) records")
            
            guard let record = message.records.first else {
                Logger.error("No records in NDEF message")
                session.invalidate(errorMessage: "No data found on tag. Please scan the tag you used in first scan.")
                DispatchQueue.main.async {
                    self.onNFCError?("NFC tag has no data")
                }
                return
            }
            
            // 打印记录详细信息
            Logger.debug("Record type name format: \(record.typeNameFormat.rawValue)")
            Logger.debug("Record type: \(String(data: record.type, encoding: .utf8) ?? "unknown")")
            Logger.debug("Record payload length: \(record.payload.count) bytes")
            Logger.debug("Record payload (hex): \(record.payload.map { String(format: "%02X", $0) }.joined(separator: " "))")
            
            // 解析文本记录
            var readUUID = ""
            if record.typeNameFormat == .nfcWellKnown,
               let type = String(data: record.type, encoding: .utf8),
               type == "T" {
                // 获取状态字节
                let statusByte = record.payload[0]
                let languageCodeLength = Int(statusByte & 0x3F)
                let isUTF16 = (statusByte & 0x80) != 0  // bit 7 表示是否使用UTF-16
                
                Logger.debug("Language code length: \(languageCodeLength)")
                Logger.debug("Encoding: \(isUTF16 ? "UTF-16" : "UTF-8")")
                
                // 跳过状态字节和语言代码
                let textStartIndex = 1 + languageCodeLength
                let textData = record.payload.advanced(by: textStartIndex)
                
                // 根据编码类型解析
                if isUTF16 {
                    // UTF-16编码
                    // 检查是否有BOM (FF FE 或 FE FF)
                    var actualTextData = textData
                    if textData.count >= 2 {
                        let bom = textData.prefix(2)
                        if bom[0] == 0xFF && bom[1] == 0xFE {
                            // UTF-16 LE with BOM
                            Logger.info("Found UTF-16 LE BOM")
                            actualTextData = textData.advanced(by: 2)
                        } else if bom[0] == 0xFE && bom[1] == 0xFF {
                            // UTF-16 BE with BOM
                            Logger.info("Found UTF-16 BE BOM")
                            actualTextData = textData.advanced(by: 2)
                        }
                    }
                    
                    // 尝试UTF-16 LE解码
                    if let uuid = String(data: actualTextData, encoding: .utf16LittleEndian) {
                        readUUID = uuid
                        Logger.debug("Parsed UUID from UTF-16 LE: \(readUUID)")
                    } else if let uuid = String(data: actualTextData, encoding: .utf16BigEndian) {
                        readUUID = uuid
                        Logger.debug("Parsed UUID from UTF-16 BE: \(readUUID)")
                    } else if let uuid = String(data: actualTextData, encoding: .utf16) {
                        readUUID = uuid
                        Logger.debug("Parsed UUID from UTF-16: \(readUUID)")
                    } else {
                        Logger.error("Failed to decode UTF-16")
                    }
                } else {
                    // UTF-8编码
                    readUUID = String(data: textData, encoding: .utf8) ?? ""
                    Logger.debug("Parsed UUID from UTF-8: \(readUUID)")
                }
            } else {
                // 尝试直接解析
                readUUID = String(data: record.payload, encoding: .utf8) ?? ""
                Logger.debug("Parsed UUID from raw payload: \(readUUID)")
            }
            
            Logger.nfc("Read UUID from NFC tag: '\(readUUID)'")
            Logger.debug("Expected UUID: '\(self.assetUUID)'")
            Logger.nfc("UUID lengths - Read: \(readUUID.count), Expected: \(self.assetUUID.count)")
            
            // 验证UUID是否匹配
            if readUUID.isEmpty {
                Logger.error("Read UUID is empty!")
                session.invalidate(errorMessage: "Failed to read UUID from tag. Tag may be corrupted.")
                DispatchQueue.main.async {
                    self.onNFCError?("Failed to read UUID. Please try scanning again or use a different NFC tag.")
                }
            } else if self.isUUIDMatch(readUUID: readUUID, expectedUUID: self.assetUUID) {
                Logger.success("UUID match successful!")
                session.alertMessage = self.customSuccessMessage
                
                DispatchQueue.main.async {
                    self.didDetectNFC = true
                    self.nfcMessage = "UUID verified successfully"
                    
                    // 根据当前阶段转换到不同的状态
                    switch self.currentPhase {
                    case .secondScan:
                        self.currentPhase = .completed  // 完成注册
                    case .checkInFirstScan:
                        self.currentPhase = .checkInInput  // 允许check-in输入
                    case .checkInSecondScan:
                        self.currentPhase = .checkInCompleted  // 完成check-in
                    case .exploreScan:
                        self.currentPhase = .idle  // 探索完成，重置状态
                    default:
                        break
                    }
                    
                    self.onNFCDetected?()
                }
                
                // 延迟关闭会话
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    session.invalidate()
                }
            } else {
                Logger.error("UUID mismatch!")
                session.invalidate(errorMessage: "UUID mismatch! Please scan the same NFC tag you used in first scan.")
                DispatchQueue.main.async {
                    self.onNFCError?("UUID mismatch. Expected: \(self.assetUUID), Got: \(readUUID)")
                }
            }
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError {
            if readerError.code != .readerSessionInvalidationErrorUserCanceled {
                DispatchQueue.main.async {
                    self.nfcMessage = "NFC scan error: \(error.localizedDescription)"
                    Logger.nfc("NFC session invalidated with error: \(error.localizedDescription)")
                }
            } else {
                Logger.nfc("NFC session cancelled by user")
            }
        }
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        Logger.nfc("NFC reader session became active")
    }
}

struct LeftTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Treasure: Identifiable {
    let id: String  // 使用建筑ID
    let coordinate: CLLocationCoordinate2D
    let name: String  // 建筑名称
    let district: String  // 地区
    let address: String  // 地址
    
    // 根据地区获取颜色
    var districtColor: Color {
        return DistrictColorManager.shared.colorForDistrict(district)
    }
}

// 地区颜色管理器
class DistrictColorManager {
    static let shared = DistrictColorManager()
    
    private var districtColors: [String: Color] = [:]
    private let availableColors: [Color] = [
        appGreen, .blue, .green, .orange, .purple, 
        .pink, .yellow, .cyan, .mint, .indigo,
        .teal, .brown
    ]
    
    func colorForDistrict(_ district: String) -> Color {
        if let existingColor = districtColors[district] {
            return existingColor
        }
        
        // 为新地区分配颜色
        let colorIndex = districtColors.count % availableColors.count
        let newColor = availableColors[colorIndex]
        districtColors[district] = newColor
        
        return newColor
    }
    
    func getAllDistrictColors() -> [String: Color] {
        return districtColors
    }
}

// 建筑聚合数据结构
struct BuildingCluster: Identifiable {
    let buildings: [Treasure]  // 包含的建筑
    let centerCoordinate: CLLocationCoordinate2D  // 聚合中心坐标
    
    // 基于建筑ID生成稳定的聚合ID，避免重新渲染时闪烁
    var id: String {
        let buildingIds = buildings.map { $0.id }.sorted()
        return buildingIds.joined(separator: "-")
    }
    
    var count: Int {
        return buildings.count
    }
    
    var isCluster: Bool {
        return buildings.count > 1
    }
    
    // 聚合点的主要颜色（使用第一个建筑的地区颜色）
    var primaryColor: Color {
        return buildings.first?.districtColor ?? .gray
    }
}

// 建筑聚合管理器
class BuildingClusteringManager {
    static let shared = BuildingClusteringManager()
    
    // 根据地图缩放级别和建筑列表生成聚合
    func clusterBuildings(_ buildings: [Treasure], zoomLevel: Double, forceExpand: Bool = false) -> [BuildingCluster] {
        // 性能优化：如果建筑数量很少，直接返回单个聚合
        if buildings.isEmpty {
            return []
        }
        
        if buildings.count <= 10 && !forceExpand {
            // 少于10个建筑，直接拆分为单个点
            return buildings.map { building in
                BuildingCluster(
                    buildings: [building],
                    centerCoordinate: building.coordinate
                )
            }
        }
        
        // 根据缩放级别确定聚合距离
        // 如果是强制展开模式，使用极小的聚合距离
        let clusterDistance = forceExpand ? 0.00005 : calculateClusterDistance(zoomLevel: zoomLevel)
        
        var clusters: [BuildingCluster] = []
        var unprocessed = buildings
        
        while !unprocessed.isEmpty {
            let current = unprocessed.removeFirst()
            var clusterBuildings = [current]
            
            // 性能优化：限制单个聚合的最大建筑数量
            let maxClusterSize = 200
            
            // 查找附近的建筑
            unprocessed.removeAll { building in
                // 如果已达到最大聚合数量，停止添加
                if clusterBuildings.count >= maxClusterSize {
                    return false
                }
                
                let distance = self.distance(
                    from: current.coordinate,
                    to: building.coordinate
                )
                
                if distance < clusterDistance {
                    clusterBuildings.append(building)
                    return true
                }
                return false
            }
            
            // 创建聚合
            let centerCoord = calculateCenter(buildings: clusterBuildings)
            let cluster = BuildingCluster(
                buildings: clusterBuildings,
                centerCoordinate: centerCoord
            )
            clusters.append(cluster)
        }
        
        // 将小于10个建筑的聚合点拆分为单个点
        // 注意：如果是forceExpand模式，已经使用极小聚合距离，跳过这个逻辑
        if forceExpand {
            // 强制展开模式：所有点都拆分为单个点
            var finalClusters: [BuildingCluster] = []
            for cluster in clusters {
                for building in cluster.buildings {
                    let singleCluster = BuildingCluster(
                        buildings: [building],
                        centerCoordinate: building.coordinate
                    )
                    finalClusters.append(singleCluster)
                }
            }
            return finalClusters
        } else {
            // 正常模式：智能拆分聚合点
            var finalClusters: [BuildingCluster] = []
            for cluster in clusters {
                if cluster.count < 10 {
                    // 检查是否有图标重叠（建筑间距离太近）
                    let hasOverlap = checkIconOverlap(buildings: cluster.buildings, zoomLevel: zoomLevel)
                    
                    if hasOverlap {
                        // 有重叠，保持聚合
                        finalClusters.append(cluster)
                    } else {
                        // 无重叠，拆分为单个建筑
                        for building in cluster.buildings {
                            let singleCluster = BuildingCluster(
                                buildings: [building],
                                centerCoordinate: building.coordinate
                            )
                            finalClusters.append(singleCluster)
                        }
                    }
                } else {
                    // 保持聚合
                    finalClusters.append(cluster)
                }
            }
            return finalClusters
        }
    }
    
    // 检查建筑图标是否会重叠
    private func checkIconOverlap(buildings: [Treasure], zoomLevel: Double) -> Bool {
        // 图标大小约为28pt（定位针高度）
        // 需要转换为地图坐标的度数
        // 在iPhone屏幕上，假设地图高度约700pt
        // 如果zoomLevel=0.01（地图跨度），则700pt = 0.01度
        // 所以28pt ≈ 0.01 * (28/700) ≈ 0.0004度
        
        let iconSizeInDegrees = zoomLevel * (32.0 / 700.0)  // 32pt包含阴影和间距
        let overlapThreshold = iconSizeInDegrees * 1.2  // 增加20%安全距离
        
        // 检查任意两个建筑之间的距离
        for i in 0..<buildings.count {
            for j in (i+1)..<buildings.count {
                let dist = distance(
                    from: buildings[i].coordinate,
                    to: buildings[j].coordinate
                )
                
                if dist < overlapThreshold {
                    // 发现重叠
                    return true
                }
            }
        }
        
        // 无重叠
        return false
    }
    
    // 根据缩放级别计算聚合距离（度数）
    private func calculateClusterDistance(zoomLevel: Double) -> Double {
        // zoomLevel是currentRegion.span.latitudeDelta
        // zoomLevel越大，地图显示范围越大（缩小），聚合距离应越大
        // zoomLevel越小，地图显示范围越小（放大），聚合距离应越小
        
        if zoomLevel > 0.2 {
            // 全香港范围，大范围聚合
            return 0.05
        } else if zoomLevel > 0.05 {
            // 中等范围（几个区），中等聚合
            return 0.015
        } else if zoomLevel > 0.01 {
            // 小范围（一个区），小聚合
            return 0.005
        } else if zoomLevel > 0.003 {
            // 很小范围（街道级别），很少聚合
            return 0.001
        } else {
            // 极小范围（建筑级别），几乎不聚合
            return 0.0003
        }
    }
    
    // 计算两点之间的距离（度数）
    private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let latDiff = from.latitude - to.latitude
        let lonDiff = from.longitude - to.longitude
        return sqrt(latDiff * latDiff + lonDiff * lonDiff)
    }
    
    // 计算聚合中心点
    private func calculateCenter(buildings: [Treasure]) -> CLLocationCoordinate2D {
        let totalLat = buildings.reduce(0.0) { $0 + $1.coordinate.latitude }
        let totalLon = buildings.reduce(0.0) { $0 + $1.coordinate.longitude }
        
        return CLLocationCoordinate2D(
            latitude: totalLat / Double(buildings.count),
            longitude: totalLon / Double(buildings.count)
        )
    }
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // 根据设备类型动态调整欢迎页图片高度与上下间距
    private var welcomeImageHeight: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 500  // iPad 合理高度
        } else {
            return 350  // iPhone 合理高度
        }
    }
    private var welcomeImageVerticalPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 12 : 20
    }
    
    @State private var showMap: Bool = false
    @State private var showLogin: Bool = true
    @State private var showTerms: Bool = false
    @State private var showWelcome: Bool = false
    @State private var showNotifications: Bool = false
    // showHome已删除 - Phygital Assets页面不再使用
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoginMode: Bool = true
    @State private var agreedToTerms: Bool = true  // 默认勾选
    @State private var agreedToEmail: Bool = false
    @State private var userEmail: String = ""  // 用户输入的email地址
    @State private var socialProvider: String = ""  // 社交登录提供商
    @State private var socialProviderId: String = ""  // 社交登录提供商ID
    @FocusState private var isUsernameFieldFocused: Bool  // 跟踪username输入框焦点状态
    @FocusState private var isSearchFieldFocused: Bool  // 跟踪搜索框焦点状态
    @State private var isMapPreloading: Bool = false  // 欢迎页预加载标记
    @State private var hasPreloadedMap: Bool = false  // 是否已完成预加载
    @State private var isFromSocialLogin: Bool = false  // 是否来自社交登录
    @State private var currentSheetView: SheetViewType? = nil  // 当前显示的sheet类型
    @State private var showBuildingHistory: Bool = false  // 显示建筑的历史记录（在地图内部，不使用fullScreenCover）
    @State private var nfcCoordinate: CLLocationCoordinate2D? = nil  // NFC的GPS坐标
    @State private var currentNfcUuid: String? = nil  // 当前NFC的UUID
    @State private var isNewNfcTag: Bool = false  // 标记当前NFC是否为新标签（跳过GPS检查）
    @State private var showCheckInInputModal: Bool = false  // 导航界面中的Check-in输入模态框
    
    // 社交登录管理器
    @StateObject private var socialLoginManager = SocialLoginManager()
    
    // 用户会话管理器
    @StateObject private var userSession = UserSessionManager.shared
    
    // 网络监控器
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    // Supabase 管理器
    private let supabaseManager = SupabaseManager.shared
    
    // Apple登录coordinator（保持引用避免被释放）
    @State private var appleSignInCoordinator: AppleSignInCoordinator?
    
    // 登录相关状态
    @State private var isAuthenticating = false
    @State private var authError: String?
    @State private var showAuthError = false
    
    // Sheet视图类型枚举
    enum SheetViewType: Identifiable {
        case nfcScan
        case assetHistory
        case nfcMismatchAlert
        
        var id: String {
            switch self {
            case .nfcScan: return "nfcScan"
            case .assetHistory: return "assetHistory"
            case .nfcMismatchAlert: return "nfcMismatchAlert"
            }
        }
    }
    
    // 社交登录相关
    @State private var loginMethod: LoginMethod = .username  // 登录方式
    @State private var socialUsername: String = ""  // 社交媒体用户名
    @State private var showSocialLoginSheet: Bool = false  // 显示社交登录授权
    @State private var pendingSocialProvider: SocialProvider? = nil  // 待授权的社交平台
    @State private var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    @State private var showTrackingPermissionAlert: Bool = false
    @State private var showLocationPermissionAlert: Bool = false
    @State private var pendingAction: (() -> Void)? = nil
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 22.2772, longitude: 114.1603),
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )
    )
    @State private var currentRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.35, longitude: 114.15),  // 香港中心
        span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)  // 覆盖全香港
    )
    @State private var treasures: [Treasure] = []
    @State private var selectedTreasure: Treasure? = nil
    @State private var buildingClusters: [BuildingCluster] = []  // 聚合后的建筑群
    @State private var currentZoomLevel: Double = 0.35  // 当前缩放级别（与currentRegion.span保持一致）
    @State private var isExpandingCluster: Bool = false  // 标记是否正在展开聚合点
    @State private var clusterUpdateWorkItem: DispatchWorkItem? = nil  // 防抖timer
    
    // 搜索功能相关
    @State private var showSearch: Bool = false  // 显示搜索框
    @State private var searchText: String = ""  // 搜索文本
    @State private var searchResults: [Treasure] = []  // 搜索结果
    @State private var isSearchMode: Bool = false  // 是否处于搜索模式（有搜索结果时）
    @State private var showNoResultsAlert: Bool = false  // 显示无结果提示
    @State private var initialRegion: MKCoordinateRegion? = nil  // 初始地图区域
    @State private var initialClusters: [BuildingCluster] = []  // 初始聚合状态
    @State private var buildingDetailRegion: MKCoordinateRegion? = nil  // 点击建筑前的地图区域（用于关闭信息框时恢复）
    @State private var buildingDetailClusters: [BuildingCluster] = []  // 点击建筑前的聚合状态（用于关闭信息框时恢复）
    
    // 底部菜单
    @State private var showMyHistory: Bool = false  // 是否显示用户的历史记录
    @State private var showReceiveTransferFromMap: Bool = false  // 是否显示接收转让界面（从地图按钮）
    @State private var showOvalOfficeHistory: Bool = false  // 是否显示Oval Office历史记录modal
    @State private var showBottomMenu: Bool = false  // 是否显示底部按钮的扇形菜单
    @State private var showMarket: Bool = false  // 是否显示Market页面
    @State private var unreadBidCount: Int = 0  // 未读Bid数量
    
    @State private var routePolyline: MKPolyline? = nil
    @State private var routeDistanceMeters: CLLocationDistance? = nil
    @State private var isRouting: Bool = false
    @State private var showClue: Bool = false
    @State private var showNavigation: Bool = false
    @State private var showGPSError: Bool = false  // GPS错误提示（独立状态，避免sheet冲突）
    // Office Map状态已移到OvalOfficeViewModel
    @State private var showUserDetailModal: Bool = false
    @State private var selectedUserInteraction: UserInteraction? = nil
    @State private var currentInteractionIndex: Int = 0  // 当前查看的历史记录索引
    @State private var showNFCAlreadyRegisteredAlert: Bool = false  // NFC已注册提示弹窗
    @State private var alreadyRegisteredNFCUUID: String = ""  // 已注册的NFC UUID
    
    @State private var clueText: String = ""
    @State private var clueImageURL: URL? = nil
    @State private var showFullScreenImage: Bool = false
    @StateObject private var locationManager = LocationManager()
    @StateObject private var nfcManager = NFCManager()
    @StateObject private var persistenceManager = PersistenceManager.shared
    @StateObject private var ovalOfficeVM = OvalOfficeViewModel()
    private let hkParkLatRange: ClosedRange<Double> = 22.2755...22.2792
    private let hkParkLonRange: ClosedRange<Double> = 114.1587...114.1620
    
    // MARK: - App Tracking Transparency
    
    /// 请求App Tracking Transparency权限
    private func requestTrackingPermission() {
        if #available(iOS 14, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    DispatchQueue.main.async {
                        self.trackingAuthorizationStatus = status
                        Logger.debug("Tracking authorization status: \(status.rawValue)")
                        switch status {
                        case .authorized:
                            Logger.info("User granted tracking permission")
                        case .denied:
                            Logger.warning("User denied tracking permission")
                        case .restricted:
                            Logger.debug("Tracking permission restricted")
                        case .notDetermined:
                            Logger.debug("Tracking permission not determined")
                        @unknown default:
                            Logger.warning("Unknown tracking permission status")
                        }
                    }
                }
            }
        } else {
            Logger.info("App Tracking Transparency not available on this iOS version")
        }
    }
    
    /// 检查当前的跟踪授权状态
    private func checkTrackingAuthorizationStatus() {
        if #available(iOS 14, *) {
            trackingAuthorizationStatus = ATTrackingManager.trackingAuthorizationStatus
        } else {
            trackingAuthorizationStatus = .authorized // 在iOS 14以下版本默认允许
        }
    }
    
    /// 检查位置权限并显示弹窗
    private func checkLocationPermissionAndExecute(action: @escaping () -> Void) {
        let status = locationManager.authorizationStatus
        Logger.location("Current location authorization status: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            // 权限未确定，显示弹窗
            pendingAction = action
            showLocationPermissionAlert = true
        case .authorizedWhenInUse, .authorizedAlways:
            // 权限已授予，直接执行操作
            action()
        case .denied, .restricted:
            // 权限被拒绝，显示弹窗解释
            pendingAction = action
            showLocationPermissionAlert = true
        @unknown default:
            // 未知状态，显示弹窗
            pendingAction = action
            showLocationPermissionAlert = true
        }
    }
    
    /// 处理位置权限弹窗的同意操作
    private func handleLocationPermissionGranted() {
        showLocationPermissionAlert = false
        if let action = pendingAction {
            pendingAction = nil
            // 请求位置权限
            locationManager.requestLocation()
            // 执行待处理的操作
            action()
        }
    }
    
    /// 处理位置权限弹窗的拒绝操作
    private func handleLocationPermissionDenied() {
        showLocationPermissionAlert = false
        pendingAction = nil
    }
    
    // MARK: - 数据持久化操作
    
    /// 从磁盘加载所有Asset
    private func loadAssetsFromDisk() {
        Logger.database("Loading assets from disk...")
        let allAssets = persistenceManager.loadAssets()
        
        // 过滤掉没有GPS信息的assets
        let validAssets = allAssets.filter { asset in
            asset.hasGPSCoordinates
        }
        
        let removedCount = allAssets.count - validAssets.count
        if removedCount > 0 {
            Logger.info("Removed \(removedCount) assets without GPS coordinates")
        }
        
        ovalOfficeVM.officeAssets = validAssets
        Logger.database("Loaded \(ovalOfficeVM.officeAssets.count) assets (with GPS coordinates)")
        
        // 如果有assets被删除，保存更新后的列表
        if removedCount > 0 {
            saveAssetsToDisk()
        }
    }
    
    /// 保存所有Asset到磁盘
    private func saveAssetsToDisk() {
        let coordinates = ovalOfficeVM.officeAssets.map { $0.coordinate }
        persistenceManager.saveAssets(ovalOfficeVM.officeAssets, coordinates: coordinates)
    }
    
    /// 快速保存单个Asset
    private func quickSaveAsset(_ asset: AssetInfo) {
        persistenceManager.quickSaveAsset(asset, coordinate: asset.coordinate)
    }
    
    // MARK: - Image Processing
    
    // 检查PNG图片中指定坐标的像素是否透明
    private func isPixelTransparent(at point: CGPoint, in image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return true }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // 确保坐标在图片范围内
        let x = Int(point.x)
        let y = Int(point.y)
        
        guard x >= 0 && x < width && y >= 0 && y < height else { return true }
        
        // 创建像素数据
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: 1,
            height: 1,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return true }
        
        // 绘制指定像素
        context.draw(cgImage, in: CGRect(x: -x, y: -y, width: width, height: height))
        
        // 检查alpha通道（第4个字节，索引3）
        let alpha = pixelData[3]
        return alpha < 128 // 如果alpha值小于128，认为是透明的
    }
    
    // 将屏幕坐标转换为网格坐标
    private func screenToGridCoordinate(_ screenPoint: CGPoint, viewSize: CGSize) -> GridCoordinate? {
        guard let image = UIImage(named: "OvalOfficePlan") else { return nil }
        let imageSize = image.size
        let gridSize: CGFloat = 5.0 // 5像素的网格
        
        // 计算图片在当前视图中的实际显示尺寸
        let scaledImageWidth = imageSize.width * ovalOfficeVM.ovalOfficeScale
        let scaledImageHeight = imageSize.height * ovalOfficeVM.ovalOfficeScale
        
        // 计算图片在视图中的偏移量（居中显示）
        let offsetX = (viewSize.width - scaledImageWidth) / 2
        let offsetY = (viewSize.height - scaledImageHeight) / 2
        
        // 计算相对于图片的坐标
        let relativeX = screenPoint.x - offsetX - ovalOfficeVM.ovalOfficeOffset.width
        let relativeY = screenPoint.y - offsetY - ovalOfficeVM.ovalOfficeOffset.height
        
        // 检查是否在图片范围内
        if relativeX >= 0 && relativeX <= scaledImageWidth &&
           relativeY >= 0 && relativeY <= scaledImageHeight {
            
            // 转换为原始图片坐标
            let originalX = relativeX / ovalOfficeVM.ovalOfficeScale
            let originalY = relativeY / ovalOfficeVM.ovalOfficeScale
            
            // 检查点击位置是否在PNG图片的非透明像素上
            let imagePoint = CGPoint(x: originalX, y: originalY)
            if isPixelTransparent(at: imagePoint, in: image) {
                Logger.debug("Click on transparent pixel - asset registration ignored")
                return nil
            }
            
            // 转换为网格坐标（使用网格中心点）
            let gridX = Int(originalX / gridSize)
            let gridY = Int(originalY / gridSize)
            
            return GridCoordinate(x: gridX, y: gridY)
        }
        
        return nil
    }
    
    // 将网格坐标转换为屏幕坐标
    private func gridToScreenCoordinate(_ gridCoord: GridCoordinate, viewSize: CGSize) -> CGPoint {
        let imageSize = UIImage(named: "OvalOfficePlan")?.size ?? .zero
        let gridSize: CGFloat = 5.0 // 5像素的网格
        
        // 计算图片在当前视图中的实际显示尺寸
        let scaledImageWidth = imageSize.width * ovalOfficeVM.ovalOfficeScale
        let scaledImageHeight = imageSize.height * ovalOfficeVM.ovalOfficeScale
        
        // 计算图片在视图中的偏移量（居中显示）
        let offsetX = (viewSize.width - scaledImageWidth) / 2
        let offsetY = (viewSize.height - scaledImageHeight) / 2
        
        // 将网格坐标转换为原始图片坐标（网格中心点）
        let originalX = CGFloat(gridCoord.x) * gridSize + gridSize / 2
        let originalY = CGFloat(gridCoord.y) * gridSize + gridSize / 2
        
        // 转换为屏幕坐标
        let screenX = originalX * ovalOfficeVM.ovalOfficeScale + offsetX + ovalOfficeVM.ovalOfficeOffset.width
        let screenY = originalY * ovalOfficeVM.ovalOfficeScale + offsetY + ovalOfficeVM.ovalOfficeOffset.height
        
        return CGPoint(x: screenX, y: screenY)
    }
    
    private var mainView: some View {
        ZStack {
            if showLogin {
                // 登录/注册页面
                loginView
            } else if showTerms {
                // 用户协议页面
                termsView
            } else if showWelcome {
                // 欢迎页面
                welcomeView
            } else if showNotifications {
                // 通知权限页面
                notificationsView
            } else {
                // 占位页面（用户会直接进入地图）
                Color.clear
            }
        }
        .alert("Location Permission Required", isPresented: $showLocationPermissionAlert) {
            Button("Allow") {
                handleLocationPermissionGranted()
            }
            Button("Deny") {
                handleLocationPermissionDenied()
            }
        } message: {
            Text("This app needs access to your location to provide treasure hunting features and show your position on the map. Your location data will be used to enhance your treasure hunting experience.")
        }
    }
    
    // MARK: - Auth Views (使用独立文件)
    private var termsView: some View {
        ChooseUsernameView(
            username: $username,
            agreedToTerms: $agreedToTerms,
            agreedToEmail: $agreedToEmail,
            showTerms: $showTerms,
            showLogin: $showLogin,
            showWelcome: $showWelcome,
            isFromSocialLogin: $isFromSocialLogin,
            onSaveEmail: { email in
                handleSaveEmail(email)
            },
            appGreen: appGreen
        )
    }
    
    private var loginView: some View {
        LoginView(
            username: $username,
            password: $password,
            confirmPassword: $confirmPassword,
            isLoginMode: $isLoginMode,
            isAuthenticating: $isAuthenticating,
            showLogin: $showLogin,
            showTerms: $showTerms,
            isFromSocialLogin: $isFromSocialLogin,
            onAppleLogin: { handleAppleLogin() },
            onFacebookLogin: {
                isFromSocialLogin = true
                showLogin = false
                showTerms = true
                socialLoginManager.loginWithFacebook()
            },
            onGoogleLogin: {
                isFromSocialLogin = true
                showLogin = false
                showTerms = true
                socialLoginManager.loginWithGoogle()
            },
            onUsernameLogin: { await handleUsernameLogin() },
            appGreen: appGreen
        )
        .sheet(isPresented: $showSocialLoginSheet) {
            socialLoginAuthView
        }
        .onAppear {
            StartupTime.mark("loginView onAppear")
            AppLoadingState.shared.isContentReady = true
            Logger.success("Login view ready, signaling to splash overlay")
        }
    }
    
    private var socialLoginAuthView: some View {
        SocialLoginAuthView(
            showSocialLoginSheet: $showSocialLoginSheet,
            pendingSocialProvider: $pendingSocialProvider,
            onSocialLogin: { handleSocialLogin() },
            appGreen: appGreen
        )
    }
    
    // 处理社交登录授权
    private func handleSocialLogin() {
        guard let provider = pendingSocialProvider else { return }
        
        Logger.auth("Processing \(provider.displayName) login...")
        
        // 模拟授权成功，获取用户信息
        // 真实实现需要调用Facebook/Google/Apple SDK
        switch provider {
        case .apple:
            // 模拟Apple返回的用户名
            socialUsername = "User_Apple_\(Int.random(in: 1000...9999))"
            loginMethod = .apple
            Logger.auth("Apple login successful: \(socialUsername)")
            
        case .facebook:
            // 模拟Facebook返回的用户名
            socialUsername = "User_FB_\(Int.random(in: 1000...9999))"
            loginMethod = .facebook
            Logger.auth("Facebook login successful: \(socialUsername)")
            
        case .google:
            // 模拟Google返回的用户名
            socialUsername = "User_G_\(Int.random(in: 1000...9999))"
            loginMethod = .google
            Logger.auth("Google login successful: \(socialUsername)")
        }
        
        // 关闭授权界面
        showSocialLoginSheet = false
        pendingSocialProvider = nil
        
        // 跳转到用户协议页面，让用户选择用户名并同意条款
        showLogin = false
        showTerms = true
        showWelcome = false
        isFromSocialLogin = true  // 标记来自社交登录
        
        // 使用社交媒体的用户名作为默认值
        username = socialUsername
    }
    
    // 处理Apple登录
    private func handleAppleLogin() {
        Logger.auth("Starting Apple login...")
        
        // 重置错误状态
        socialLoginManager.loginFailed = false
        socialLoginManager.errorMessage = nil
        
        // 立即切换到choose username页面
        isFromSocialLogin = true
        showLogin = false
        showTerms = true
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        // 使用coordinator作为delegate
        let coordinator = AppleSignInCoordinator(
            onSuccess: { authorization in
                Logger.auth("Apple login authorized successfully, handling result...")
                self.handleAppleLoginSuccess(authorization)
            },
            onError: { error in
                Logger.error("Apple login error: \(error.localizedDescription)")
                // 设置登录失败状态
                self.socialLoginManager.errorMessage = "Apple login failed: \(error.localizedDescription)"
                self.socialLoginManager.loginFailed = true
            }
        )
        
        controller.delegate = coordinator
        controller.presentationContextProvider = coordinator
        
        // 保持coordinator的引用
        appleSignInCoordinator = coordinator
        
        controller.performRequests()
    }
    
    private func handleAppleLoginSuccess(_ authorization: ASAuthorization) {
        socialLoginManager.handleAppleLoginResult(authorization)
    }
    
    // MARK: - 用户认证方法
    
    /// 检查自动登录
    private func checkAutoLogin() {
        if userSession.isLoggedIn, let savedUsername = userSession.currentUsername {
            Logger.auth("Auto-login: \(savedUsername)")
            username = savedUsername
            showLogin = false
            showTerms = false
            showWelcome = true
        }
    }
    
    /// 保存用户email地址和社交账户信息
    private func handleSaveEmail(_ email: String) {
        userEmail = email
        Logger.auth("User email saved: \(email)")
        
        // 异步更新到Supabase
        Task {
            do {
                try await supabaseManager.updateUserEmailAndSocial(
                    username: username,
                    email: email,
                    provider: socialProvider.isEmpty ? nil : socialProvider,
                    providerId: socialProviderId.isEmpty ? nil : socialProviderId
                )
                Logger.success("Email and social accounts saved to Supabase")
            } catch {
                Logger.error("Failed to save email: \(error.localizedDescription)")
            }
        }
    }
    
    /// 处理用户名/密码登录
    private func handleUsernameLogin() async {
        guard !username.isEmpty && !password.isEmpty else {
            authError = "Please enter username and password"
            showAuthError = true
            return
        }
        
        isAuthenticating = true
        
        do {
            let user: CloudUser
            
            if isLoginMode {
                // 登录
                user = try await supabaseManager.loginUser(username: username, password: password)
                Logger.success("Login successful: \(user.username)")
            } else {
                // 注册
                guard password == confirmPassword else {
                    authError = "Passwords do not match"
                    showAuthError = true
                    isAuthenticating = false
                    return
                }
                
                user = try await supabaseManager.registerUser(username: username, password: password)
                Logger.success("Registration successful: \(user.username)")
            }
            
            // 保存会话
            await MainActor.run {
                userSession.saveSession(user: user)
                isAuthenticating = false
                                showLogin = false
                                showTerms = true
            }
            
        } catch {
            await MainActor.run {
                authError = error.localizedDescription
                showAuthError = true
                isAuthenticating = false
            }
        }
    }
    
    /// 处理社交登录成功
    private func handleSocialLoginSuccess() {
        guard let userInfo = socialLoginManager.userInfo else { return }
        
        Task {
            do {
                // 使用社交登录信息注册/登录
                let user = try await supabaseManager.socialLogin(
                    username: userInfo.name,
                    email: userInfo.email,
                    provider: userInfo.provider,
                    providerId: userInfo.id
                )
                
                await MainActor.run {
                    // 只更新用户信息，页面已经在choose username了
                    username = user.username
                    userSession.saveSession(user: user)
                    
                    // 保存社交账户信息
                    socialProvider = userInfo.provider
                    socialProviderId = userInfo.id
                    userEmail = userInfo.email
                    
                    Logger.success("Social login complete, user data populated")
                }
                
            } catch {
                // 登录失败，确保返回登录页面
                await MainActor.run {
                    showLogin = true
                    showTerms = false
                    showWelcome = false
                    isFromSocialLogin = false
                    
                    authError = "Social login failed: \(error.localizedDescription)"
                    showAuthError = true
                    
                    Logger.error("Social login failed, returning to login page")
                }
            }
        }
    }
    
    /// 处理登出
    private func handleSignOut() {
        // 清除用户会话
        userSession.clearSession()
        
        // 社交登录登出
        socialLoginManager.logout()
        
        // 重置UI状态
        username = ""
        password = ""
        confirmPassword = ""
        showWelcome = false
        showLogin = true
        showTerms = false
        
        Logger.auth("User signed out")
    }
    
    /// 处理"Explore"按钮点击 - 延迟加载地图数据
    private func handleExploreButtonTap() {
        Logger.ui("User tapped Explore button")
        
        // 如果已经加载过，直接进入地图
        if hasPreloadedMap {
            Logger.info("Map data already loaded, entering map view")
        showWelcome = false
            checkLocationPermissionAndExecute {
                showMap = true
            }
            requestTrackingPermission()
            return
        }
        
        // 开始加载地图数据
        Task { @MainActor in
            isMapPreloading = true
            Logger.info("Loading map data...")
            
            await loadHistoricBuildings()
            
            hasPreloadedMap = true
            isMapPreloading = false
            
            Logger.success("Map data loaded successfully")
            
            // 加载完成后进入地图
            showWelcome = false
            checkLocationPermissionAndExecute {
                showMap = true
            }
            requestTrackingPermission()
        }
    }
    
    // Phygital Assets页面已删除 - 用户直接进入地图
    
    private var notificationsView: some View {
        NotificationPermissionView(
            showNotifications: $showNotifications,
            appGreen: appGreen
        )
    }
    
    private var welcomeView: some View {
        WelcomeView(
            username: $username,
            showWelcome: $showWelcome,
            showTerms: $showTerms,
            isMapPreloading: $isMapPreloading,
            onSignOut: { handleSignOut() },
            onExploreButtonTap: { handleExploreButtonTap() },
            onPreloadMap: {
                Logger.debug("Welcome page appeared, starting map preload...")
                if treasures.isEmpty {
                    isMapPreloading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        generateTreasureLocations(count: 6)
                        Logger.success("Map assets preloaded successfully")
                        isMapPreloading = false
                    }
                }
            },
            welcomeImageHeight: welcomeImageHeight,
            welcomeImageVerticalPadding: welcomeImageVerticalPadding,
            appGreen: appGreen
        )
    }
    // 网络离线提示横幅
    private var networkBanner: some View {
        VStack {
            if !networkMonitor.isConnected {
            HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.white)
                    Text("No network connection")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.9))
                .cornerRadius(8)
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
                Spacer()
            }
        .animation(.easeInOut, value: networkMonitor.isConnected)
    }
    
    // 主视图内容 - 应用监听和alert
    private var contentWithModifiers: some View {
        ZStack {
            mainView
                .overlay(networkBanner)
            
            // Debug 浮动按钮 - 已隐藏，需要时取消注释
            // #if DEBUG
            // DebugDashboard(appGreen: appGreen)
            // #endif
        }
        .onAppear {
            checkAutoLogin()
        }
        .onChange(of: socialLoginManager.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                handleSocialLoginSuccess()
            }
        }
        .onChange(of: socialLoginManager.errorMessage) { _, errorMessage in
            if let error = errorMessage {
                Logger.error("Social login error: \(error)")
                authError = error
                showAuthError = true
            }
        }
        .onChange(of: socialLoginManager.loginFailed) { _, failed in
            if failed {
                Logger.warning("Social login failed, returning to login page")
                isFromSocialLogin = false
                showLogin = true
                showTerms = false
                showWelcome = false
                
                if let error = socialLoginManager.errorMessage {
                    authError = error
                    showAuthError = true
                }
                
                socialLoginManager.loginFailed = false
            }
        }
        .alert("Login Error", isPresented: $showAuthError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authError ?? "An error occurred during login")
        }
    }
    
    // 全屏地图视图
    private var fullScreenMapView: some View {
        // 全屏地图区域
        ZStack(alignment: .topLeading) {
            Map(position: $cameraPosition) {
                    // 用户位置 - 绿色圆点
                    if let userLocation = locationManager.location {
                        Annotation("Your Location", coordinate: userLocation.coordinate) {
                            Circle()
                                .fill(appGreen)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                    }
                    
                    if let routePolyline {
                        MapPolyline(routePolyline)
                            .stroke(appGreen, lineWidth: 3)
                    }
                    
                    // 当有选中的建筑时，隐藏其他建筑点
                    if selectedTreasure == nil {
                        // 没有选中建筑，显示所有聚合点
                        ForEach(buildingClusters) { cluster in
                            Annotation("", coordinate: cluster.centerCoordinate) {
                                Button(action: {
                                if cluster.isCluster {
                                    // 点击聚合点：展开并放大地图
                                    expandCluster(cluster)
                                } else {
                                    // 点击单个建筑：显示详情
                                    if let building = cluster.buildings.first {
                                        // 所有建筑（包括 Oval Office）都先进入导航界面
                                        // 保存当前地图状态
                                        buildingDetailRegion = currentRegion
                                        buildingDetailClusters = buildingClusters
                                        
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            currentRegion.center = building.coordinate
                                            cameraPosition = .region(currentRegion)
                                        }
                                        
                                        selectedTreasure = building
                                        isSearchMode = false  // 退出搜索模式
                                        routePolyline = nil
                                        routeDistanceMeters = nil
                                        isRouting = false
                                        
                                        Logger.debug("Selected building: \(building.name)")
                                        startHunt(to: building.coordinate)
                                        
                                        if showClue {
                                            clueText = generateClueForTreasure(at: building.coordinate)
                                            generateStreetViewImage(for: building.coordinate)
                                        }
                                    }
                                }
                            }) {
                                if cluster.isCluster {
                                    // 聚合标记 - 圆形+数字
                                    ZStack {
                                        Circle()
                                            .fill(cluster.primaryColor)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
                                        
                                        Text("\(cluster.count)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                                } else {
                                    // 单个建筑标记
                                    let building = cluster.buildings[0]
                                    VStack(spacing: 2) {
                                        // SwiftUI绘制的定位针（无缝连接）
                                        ZStack {
                                            // 完整的定位针路径（圆形+三角形一体）
                                            Path { path in
                                                let center = CGPoint(x: 10, y: 8)
                                                let radius: CGFloat = 8
                                                
                                                // 绘制圆形部分（上半部分，从左到右）
                                                path.addArc(
                                                    center: center,
                                                    radius: radius,
                                                    startAngle: .degrees(180),
                                                    endAngle: .degrees(0),
                                                    clockwise: false
                                                )
                                                
                                                // 从圆形右侧连接到三角形底部尖角
                                                path.addLine(to: CGPoint(x: center.x, y: 24))
                                                
                                                // 从尖角回到圆形左侧
                                                path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
                                                
                                                path.closeSubpath()
                                            }
                                            .fill(building.districtColor)
                                            
                                            // 白色中心点
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 6, height: 6)
                                                .offset(x: 0, y: -8)
                                        }
                                        .frame(width: 20, height: 28)
                                        .scaleEffect((selectedTreasure?.id == building.id) ? 1.5 : 1.0)
                                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                        
                                        // 如果是900，显示Oval Office标签
                                        if building.id == "900" {
                                            Text("Oval Office")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)  // 强制一行
                                                .fixedSize()  // 不压缩文字
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(appGreen)
                                                .cornerRadius(4)
                                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    // 有选中的建筑，只显示选中的建筑
                    if let selected = selectedTreasure {
                            Annotation("", coordinate: selected.coordinate) {
                                VStack(spacing: 2) {
                                    // 使用相同的无缝定位针
                                    ZStack {
                                        // 完整的定位针路径
                                        Path { path in
                                            let center = CGPoint(x: 10, y: 8)
                                            let radius: CGFloat = 8
                                            
                                            // 绘制圆形部分
                                            path.addArc(
                                                center: center,
                                                radius: radius,
                                                startAngle: .degrees(180),
                                                endAngle: .degrees(0),
                                                clockwise: false
                                            )
                                            
                                            // 连接到三角形底部尖角
                                            path.addLine(to: CGPoint(x: center.x, y: 24))
                                            
                                            // 回到圆形左侧
                                            path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
                                            
                                            path.closeSubpath()
                                        }
                                        .fill(selected.districtColor)
                                        
                                        // 白色中心点
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 6, height: 6)
                                            .offset(x: 0, y: -8)
                                    }
                                    .frame(width: 20, height: 28)
                                    .scaleEffect(1.5)  // 选中状态，放大显示
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                    
                                    // 如果是Oval Office，显示标签
                                    if selected.id == "900" {
                                        Text("Oval Office")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                            .fixedSize()
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(appGreen)
                                            .cornerRadius(4)
                                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                    }
                                }
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                .onAppear {
                    cameraPosition = .region(currentRegion)
                    if treasures.isEmpty {
                        generateTreasureLocations(count: 6)  // 加载历史建筑
                    }
                    // 请求位置权限
                    locationManager.requestLocation()
                    
                    // 设置地图界面的NFC探索扫描回调
                    nfcManager.onNFCDetected = {
                        DispatchQueue.main.async {
                            if self.nfcManager.currentPhase == .exploreScan || self.nfcManager.didDetectNFC {
                                Logger.success("NFC探索扫描成功，查找对应的建筑...")
                                // 查找匹配的建筑（基于NFC UUID）
                                self.handleNFCExploreResult()
                            }
                        }
                    }
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    // 地图缩放或移动结束时更新聚合
                    currentRegion = context.region
                    
                    // 如果正在展开聚合点，跳过自动更新
                    if isExpandingCluster {
                        isExpandingCluster = false
                        return
                    }
                    
                    if !treasures.isEmpty {
                        updateClusters()
                    }
                }
            
            // 右下角三个小按钮 - 只在不显示Buy界面和clue hint时显示
            if !showReceiveTransferFromMap && !showClue {
                VStack(spacing: 10) {
                    // 指南针按钮 - 定位到用户位置
                    Button(action: { 
                        centerOnUserLocation()
                    }) {
                        ZStack {
                            Circle().fill(Color.white)
                            Image(systemName: "location.north.line")
                                .font(.system(size: 16))
                                .foregroundStyle(appGreen)
                        }
                        .frame(width: 36, height: 36)
                        .shadow(radius: 2)
                    }
                    
                    // 恢复初始状态按钮
                    Button(action: { 
                        restoreInitialMapState()
                    }) {
                        ZStack {
                            Circle().fill(Color.white)
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16))
                                .foregroundStyle(appGreen)
                        }
                        .frame(width: 36, height: 36)
                        .shadow(radius: 2)
                    }
                    
                    // 搜索按钮 - 切换搜索框显示/隐藏
                    Button(action: { 
                        showSearch.toggle()
                        if !showSearch {
                            // 关闭搜索框时清空搜索内容
                            searchText = ""
                            clearSearch()
                        }
                    }) {
                        ZStack {
                            Circle().fill(Color.white)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundStyle(appGreen)
                        }
                        .frame(width: 36, height: 36)
                        .shadow(radius: 2)
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 50)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .zIndex(100)
            }
            
            // 底部中央的扇形菜单按钮组 - 只在不显示Buy界面和没有选中building时显示
            if !showReceiveTransferFromMap && selectedTreasure == nil {
                ZStack(alignment: .bottom) {
                    // 背景遮罩 - 点击关闭菜单
                    if showBottomMenu {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showBottomMenu = false
                                }
                            }
                            .ignoresSafeArea()
                    }
                    
                    // 扇形展开的3个小按钮
                    if showBottomMenu {
                        // Sell按钮（左侧，150度）
                        Button(action: {
                            Logger.debug("Sell button tapped!")
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showBottomMenu = false
                            }
                            
                            // 打开My Assets
                            showMap = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showMyHistory = true
                            }
                        }) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                    .shadow(radius: 4)
                                    .overlay(
                                        Text("Sell")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(appGreen)
                                    )
                            }
                        }
                        .offset(x: -87, y: -50)
                        .transition(.scale.combined(with: .opacity))
                        
                        // Scan按钮（左上，110度）
                        Button(action: {
                            Logger.debug("Scan button tapped!")
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showBottomMenu = false
                            }
                            
                            // 设置NFC回调并启动扫描
                            nfcManager.onNFCDetected = {
                                Logger.debug("NFC detected from Scan button")
                                self.handleNFCExploreResult()
                            }
                            
                            nfcManager.onNFCError = { error in
                                Logger.error("NFC Error from Scan button: \(error)")
                            }
                            
                            nfcManager.startExploreScan()
                        }) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                    .shadow(radius: 4)
                                    .overlay(
                                        Text("Scan")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(appGreen)
                                    )
                            }
                        }
                        .offset(x: -34, y: -94)
                        .transition(.scale.combined(with: .opacity))
                        
                        // Market按钮（右上，70度）
                        Button(action: {
                            Logger.debug("Market button tapped!")
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showBottomMenu = false
                            }
                            
                            // 打开Market页面
                            showMap = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showMarket = true
                            }
                        }) {
                            ZStack(alignment: .topTrailing) {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 50, height: 50)
                                        .shadow(radius: 4)
                                        .overlay(
                                            Text("Market")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(appGreen)
                                        )
                                }
                                
                                // 未读Bid徽章
                                if unreadBidCount > 0 {
                                    ZStack {
                                        Circle()
                                            .fill(appGreen)
                                            .frame(width: 18, height: 18)
                                        
                                        if unreadBidCount < 100 {
                                            Text("\(unreadBidCount)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        } else {
                                            Text("99+")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .offset(x: 8, y: -2)
                                    .shadow(color: appGreen.opacity(0.3), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                        .offset(x: 34, y: -94)
                        .transition(.scale.combined(with: .opacity))
                        
                        // Buy按钮（右侧，30度）
                        Button(action: {
                            Logger.debug("Buy button tapped!")
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showBottomMenu = false
                            }
                            
                            // 打开扫描QR码界面
                            showReceiveTransferFromMap = true
                        }) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                    .shadow(radius: 4)
                                    .overlay(
                                        Text("Buy")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(appGreen)
                                    )
                            }
                        }
                        .offset(x: 87, y: -50)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // 主按钮
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showBottomMenu.toggle()
                        }
                    }) {
                        ZStack {
                            // 毛玻璃背景
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 78, height: 78)
                            
                            // 绿色叠加（菜单打开时变淡）
                            Circle()
                                .fill(appGreen.opacity(showBottomMenu ? 0.1 : 0.3))
                                .frame(width: 78, height: 78)
                            
                            // 边框
                            Circle()
                                .stroke(appGreen.opacity(showBottomMenu ? 0.3 : 0.5), lineWidth: 2)
                                .frame(width: 78, height: 78)
                            
                            // 文字：菜单展开时变绿色，否则白色
                            Text("Asset")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(showBottomMenu ? appGreen : .white)
                        }
                        .shadow(color: appGreen.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                }
                .padding(.bottom, 65)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .zIndex(200)
            }
                
            // 搜索框覆盖层 - 完全独立，不影响右侧按键
            if showSearch {
                    // 搜索输入框 - 使用overlay方式，完全独立定位
                    VStack {
                        Spacer()
                        HStack {
                            // 搜索输入框容器
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 18)) // 更大的图标
                                
                                TextField("Search buildings...", text: $searchText)
                                    .textFieldStyle(.plain)
                                    .autocorrectionDisabled(true)
                                    .font(.system(size: 18)) // 更大的文字
                                    .focused($isSearchFieldFocused)
                                    .onSubmit {
                                        // 回车时搜索
                                        performSearch(searchText)
                                    }
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                        clearSearch()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 18)) // 更大的图标
                                    }
                                }
                                
                                // 搜索确认按钮（回车图标）
                                Button(action: {
                                    // 隐藏键盘
                                    isSearchFieldFocused = false
                                    performSearch(searchText)
                                }) {
                                    Image(systemName: "arrow.turn.down.left")
                                        .foregroundColor(searchText.isEmpty ? .gray : appGreen)
                                        .font(.system(size: 18, weight: .semibold)) // 更大的图标
                                }
                                .disabled(searchText.isEmpty)
                                
                                // 关闭搜索按钮（X图标）
                                Button(action: {
                                    // 隐藏键盘
                                    isSearchFieldFocused = false
                                    showSearch = false
                                    searchText = ""
                                    clearSearch()
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 18, weight: .semibold)) // 更大的图标
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                            .frame(width: 320, height: 54)
                            
                            Spacer() // 占满剩余空间
                        }
                        .padding(.leading, -10 + 20) // 向右移动20像素：-10 + 20 = 10
                        .padding(.trailing, 20)
                        .padding(.bottom, 10) // 向下移动20像素：30 - 20 = 10
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .allowsHitTesting(true) // 确保可以交互
                }


                // 白色信息框 - 显示宝藏信息，类似参考图片风格
                if let selectedTreasure {
                    ZStack {
                        // 半透明背景遮罩层，点击时关闭信息框
                        Color.black.opacity(0.1)
                            .ignoresSafeArea()
                        .onTapGesture {
                            self.selectedTreasure = nil
                            self.showClue = false
                            
                            // 恢复关闭信息框前的地图状态
                            if let savedRegion = buildingDetailRegion {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentRegion = savedRegion
                                    cameraPosition = .region(savedRegion)
                                }
                                
                                // 基于恢复后的地图状态重新计算聚合
                                currentZoomLevel = savedRegion.span.latitudeDelta
                                buildingClusters = BuildingClusteringManager.shared.clusterBuildings(
                                    treasures,
                                    zoomLevel: currentZoomLevel,
                                    forceExpand: false
                                )
                                
                                // 清除路径
                                routePolyline = nil
                                routeDistanceMeters = nil
                                isRouting = false
                                
                                // 清除保存的状态
                                buildingDetailRegion = nil
                                buildingDetailClusters = []
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                        // 标题栏 - 包含关闭按钮
                        HStack {
                            Text("Historic Building")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Button(action: {
                                self.selectedTreasure = nil
                                self.showClue = false // 同时关闭线索框
                                
                                // 恢复关闭信息框前的地图状态
                                if let savedRegion = buildingDetailRegion {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentRegion = savedRegion
                                        cameraPosition = .region(savedRegion)
                                    }
                                    
                                    // 基于恢复后的地图状态重新计算聚合
                                    currentZoomLevel = savedRegion.span.latitudeDelta
                                    buildingClusters = BuildingClusteringManager.shared.clusterBuildings(
                                        treasures,
                                        zoomLevel: currentZoomLevel,
                                        forceExpand: false
                                    )
                                    
                                    // 清除路径
                                    routePolyline = nil
                                    routeDistanceMeters = nil
                                    isRouting = false
                                    
                                    // 清除保存的状态
                                    buildingDetailRegion = nil
                                    buildingDetailClusters = []
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                    .frame(width: 28, height: 28)
                                    .background(Color.clear)
                            }
                        }
                        
                        // 历史建筑信息
                        VStack(alignment: .leading, spacing: 8) {
                            // 建筑名称和距离
                            HStack {
                                Text(selectedTreasure.name)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if let distance = routeDistanceMeters, isRouting {
                                    Text("\(Int(distance.rounded())) m")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            // 地区标签
                            Text(selectedTreasure.district)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedTreasure.districtColor.opacity(0.2))
                                .foregroundColor(selectedTreasure.districtColor)
                                .cornerRadius(6)
                            
                            // 地址
                            Text(selectedTreasure.address)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            // 难度和大小信息
                            HStack {
                                Text("Difficulty: 2.0")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("|")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Size: Small")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // 推荐信息
                            Text("Recommended for treasure hunters")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // 按钮行
                        HStack(spacing: 12) {
                            // Need a Clue? 按钮
                            Button(action: {
                                clueText = generateClueForTreasure(at: selectedTreasure.coordinate)
                                generateStreetViewImage(for: selectedTreasure.coordinate)
                    showClue = true
                }) {
                                HStack {
                                    Image(systemName: "lightbulb")
                                        .font(.caption)
                    Text("Need a Clue?")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(appGreen)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
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
                            }
                            
                            // GO! 按钮
                            Button(action: {
                                showNavigation = true
                            }) {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                    Text("GO!")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                }
                                .foregroundStyle(appGreen)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
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
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.top, 24)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }

                // 线索弹出框 - 显示照片和文字提示
                if showClue {
                    VStack(alignment: .leading, spacing: 12) {
                        // 标题栏
                        HStack {
                            Text("Clue Hint")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            }
                        
                        // 线索图片
                        if let url = clueImageURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 160)
                                        .clipped()
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            showFullScreenImage = true
                                        }
                                case .failure(_):
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 160)
                                            .cornerRadius(8)
                                        VStack(spacing: 8) {
                                        Image(systemName: "photo")
                                                .font(.title2)
                                                .foregroundStyle(.gray)
                                            Text("Image Load Failed")
                                                .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                    }
                                case .empty:
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(height: 160)
                                            .cornerRadius(8)
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                @unknown default:
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(height: 160)
                                            .cornerRadius(8)
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                }
                            }
                        }
                        
                        // 线索文字
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hint:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        Text(clueText)
                                .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    }
                    .padding(16)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                
                // 全屏图片显示
                if showFullScreenImage, let url = clueImageURL {
                    ZStack {
                        // 半透明黑色背景
                        Color.black.opacity(0.9)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showFullScreenImage = false
                            }
                        
                        // 全屏图片
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .onTapGesture {
                                        showFullScreenImage = false
                                    }
                            case .failure(_):
                                VStack(spacing: 16) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.white)
                                    Text("Image Load Failed")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                                .onTapGesture {
                                    showFullScreenImage = false
                                }
                            case .empty:
                                ProgressView()
                                    .scaleEffect(2)
                                    .foregroundStyle(.white)
                            @unknown default:
                                ProgressView()
                                    .scaleEffect(2)
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(20)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: showFullScreenImage)
                }
                
                // 左上角返回按钮
                Button(action: {
                    showMap = false
                    showWelcome = true
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.9), in: Circle())
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 16)
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .zIndex(1000)
                
                
                // 无结果提示框（覆盖在地图上）
                if showNoResultsAlert {
                    ZStack {
                        // 背景遮罩（fade效果）
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                // 点击背景也可以关闭，并恢复到初始状态
                                showNoResultsAlert = false
                                restoreInitialMapState()
                            }
                        
                        // 提示框
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("No Results Found")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("No buildings found matching your search. Please try different keywords.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                showNoResultsAlert = false
                                // 恢复到初始地图状态
                                restoreInitialMapState()
                            }) {
                                Text("OK")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(appGreen)
                                    .frame(width: 120, height: 44)
                                    .background {
                                        ZStack {
                                            Color.clear.background(.ultraThinMaterial)
                                            appGreen.opacity(0.1)
                                        }
                                    }
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(appGreen.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(30)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 10)
                        .padding(.horizontal, 40)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .animation(.easeInOut(duration: 0.3), value: showNoResultsAlert)
                }
                
                // Check-in输入模态框覆盖层（主地图上的）
                if showCheckInInputModal {
                    CheckInInputModal(
                        assetName: $ovalOfficeVM.assetName,
                        assetImage: $ovalOfficeVM.assetImage,
                        assetDescription: $ovalOfficeVM.assetDescription,
                        appGreen: appGreen,
                        nfcManager: nfcManager,
                        onCancel: {
                            // 关闭输入框
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showCheckInInputModal = false
                            }
                            // 重置NFC管理器和注册状态
                            nfcManager.reset()
                        }
                    )
                    .onAppear {
                        Logger.debug("🎯 CheckInInputModal已显示（主地图）")
                    }
                    .zIndex(3000)  // 确保输入框显示在主地图的所有内容之上
                }
            
            // 接收转让界面（从地图Scan按钮）
            if showReceiveTransferFromMap {
                ReceiveTransferView(
                    appGreen: appGreen,
                    username: username,
                    onClose: {
                        showReceiveTransferFromMap = false
                    },
                    onTransferComplete: {
                        showReceiveTransferFromMap = false
                    },
                    nfcManager: nfcManager
                )
            }
        }
        .fullScreenCover(item: $currentSheetView) { sheetType in
            switch sheetType {
            case .nfcScan:
                NFCScanView(
                    onNFCDetected: { coordinate in
                        nfcCoordinate = coordinate
                        currentSheetView = .assetHistory
                    },
                    onCancel: {
                        currentSheetView = nil
                    }
                )
            case .assetHistory:
                // 在主地图上显示Asset历史记录（通过Tap按钮扫描的NFC）
                let _ = Logger.debug("🏛️ ========== 显示 NFCHistoryFullScreenView ==========")
                let _ = Logger.debug("🏛️ currentNfcUuid: '\(currentNfcUuid ?? "nil")'")
                let _ = Logger.debug("🏛️ UUID 长度: \(currentNfcUuid?.count ?? 0)")
                
                NFCHistoryFullScreenView(
                    nfcUuid: currentNfcUuid ?? "",
                    appGreen: appGreen,
                    onClose: {
                        Logger.debug("🔙 关闭NFC历史记录视图")
                        currentSheetView = nil
                        nfcCoordinate = nil
                        currentNfcUuid = nil
                    },
                    onNavigateToBuilding: { latitude, longitude in
                        Logger.debug("📍 导航到GPS坐标: (\(latitude), \(longitude))")
                    },
                    onNavigateToOvalOffice: {
                        Logger.debug("📍 导航到Oval Office")
                        currentSheetView = nil
                        ovalOfficeVM.showOvalOffice = true
                        showMap = false
                    },
                    treasures: treasures,
                    currentUsername: username
                )
            case .nfcMismatchAlert:
                // NFC不匹配警告（现在已不使用，但保留以满足exhaustive要求）
                EmptyView()
            }
        }
        .fullScreenCover(isPresented: $showNavigation) {
            // 导航模式的全屏地图
            ZStack {
                Map(position: $cameraPosition) {
                    // 用户位置 - 绿色圆点
                    if let userLocation = locationManager.location {
                        Annotation("Your Location", coordinate: userLocation.coordinate) {
                            Circle()
                                .fill(appGreen)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                    }
                    
                    // 路线
                    if let routePolyline {
                        MapPolyline(routePolyline)
                            .stroke(appGreen, lineWidth: 3)
                    }
                    
                    // 只显示选中的目标建筑（隐藏其他建筑）
                    if let selectedTreasure = selectedTreasure {
                        Annotation(selectedTreasure.name, coordinate: selectedTreasure.coordinate) {
                            // 目标建筑标记 - 使用无缝定位针
                            VStack(spacing: 2) {
                                ZStack {
                                    // 完整的定位针路径（无缝连接）
                                    Path { path in
                                        let center = CGPoint(x: 10, y: 8)
                                        let radius: CGFloat = 8
                                        
                                        // 绘制圆形部分
                                        path.addArc(
                                            center: center,
                                            radius: radius,
                                            startAngle: .degrees(180),
                                            endAngle: .degrees(0),
                                            clockwise: false
                                        )
                                        
                                        // 连接到三角形底部尖角
                                        path.addLine(to: CGPoint(x: center.x, y: 24))
                                        
                                        // 回到圆形左侧
                                        path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
                                        
                                        path.closeSubpath()
                                    }
                                    .fill(selectedTreasure.districtColor)
                                    
                                    // 白色中心点
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 6, height: 6)
                                        .offset(x: 0, y: -8)
                                }
                                .frame(width: 20, height: 28)
                                .scaleEffect(1.5)  // 导航模式放大显示
                                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                            }
                        }
                    }
                }
                .mapStyle(.standard)
                .onAppear {
                    if let selectedTreasure = selectedTreasure,
                       let userLocation = locationManager.location {
                        calculateRoute(from: userLocation.coordinate, to: selectedTreasure.coordinate)
                    }
                }
                .ignoresSafeArea()  // 地图全屏显示
                .zIndex(0)  // 地图层在最底部
                
                // 返回按钮
                VStack {
                    HStack {
                        Button(action: {
                            showNavigation = false
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .background(Color.white.opacity(0.9), in: Circle())
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.top, 8)
                        .padding(.leading, 8)
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // 交通方式选择按钮（底部）
                    if let selectedTreasure = selectedTreasure {
                        VStack(spacing: 0) {
                            Spacer()
                            
                            VStack(spacing: 12) {
                                // NFC探索按钮 - Premium风格
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        // 直接启动NFC扫描，跳过扫描页面
                                        startDirectNFCScan()
                                    }) {
                                        Text("TAP and Explore this Phygital Asset")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .frame(width: 280, height: 35)
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
                                    }
                                    Spacer()
                                }
                                .padding(.bottom, 8)
                                
                                NavigationMethodsView(
                                    building: selectedTreasure,
                                    userLocation: locationManager.location,
                                    distance: routeDistanceMeters
                                )
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
                .zIndex(100)  // 按钮层在地图之上
                
                
                // Oval Office History Modal - 显示在地图上
                if showOvalOfficeHistory {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                // 点击背景关闭
                                showOvalOfficeHistory = false
                                selectedTreasure = nil
                            }
                        
                        OvalOfficeHistoryModal(
                            building: selectedTreasure,
                            appGreen: appGreen,
                            onStartCheckIn: { buildingId in
                                Logger.debug("🏛️ Starting Oval Office building check-in")
                                Logger.debug("   Building ID: \(buildingId)")
                                Logger.debug("   Current NFC UUID: \(currentNfcUuid ?? "nil")")
                                
                                // 关闭历史记录框
                                showOvalOfficeHistory = false
                                
                                // ✅ 检查是否有NFC UUID
                                if let nfcUuid = currentNfcUuid, !nfcUuid.isEmpty {
                                    // 已有UUID，直接打开输入框
                                    Logger.success("✅ 已有NFC UUID，直接打开输入框")
                                    Logger.debug("   UUID: \(nfcUuid)")
                                    
                                    // ✅ 设置NFC管理器为Check-in模式
                                    nfcManager.currentPhase = .checkInInput
                                    nfcManager.assetUUID = nfcUuid  // 设置期望的UUID
                                    Logger.debug("✅ 设置 nfcManager.currentPhase = .checkInInput")
                                    Logger.debug("✅ 设置 nfcManager.assetUUID = '\(nfcUuid)'")
                                    
                                    // ✅ 设置NFC回调：处理第二次扫描（Check out）
                                    nfcManager.onNFCDetected = {
                                        Logger.success("✅ NFC第二次扫描成功（Oval Office Check In Mine）")
                                        
                                        DispatchQueue.main.async {
                                            guard let selectedBuilding = self.selectedTreasure else {
                                                Logger.error("❌ No building selected")
                                                return
                                            }
                                            
                                            switch self.nfcManager.currentPhase {
                                            case .checkInCompleted:
                                                // Check-in第二次NFC验证成功，保存数据
                                                Logger.success("Check-in second NFC verified, saving data...")
                                                
                                                // 对于Oval Office，直接保存（不需要GPS验证）
                                                self.saveCheckInData(for: selectedBuilding)
                                                self.closeCheckInModal()
                                            default:
                                                break
                                            }
                                        }
                                    }
                                    
                                    // 打开输入框，让用户输入信息
                                    Logger.debug("⏰ 打开 Check-in 输入框（建筑模式）")
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        showCheckInInputModal = true
                                    }
                                    Logger.success("✅ Check-in 输入框已打开")
                                } else {
                                    // 没有UUID，需要先扫描NFC来获取/生成UUID
                                    Logger.warning("⚠️ 没有NFC UUID，需要先扫描NFC")
                                    Logger.debug("   启动NFC扫描（探索模式）")
                                    
                                    // 启动NFC探索扫描
                                    nfcManager.startExploreScan()
                                    
                                    // 设置NFC回调：扫描成功后设置UUID并打开输入框
                                    nfcManager.onNFCDetected = {
                                        Logger.success("✅ NFC扫描成功（Oval Office Check In Mine）")
                                        
                                        DispatchQueue.main.async {
                                            // 设置currentNfcUuid
                                            self.currentNfcUuid = self.nfcManager.assetUUID
                                            Logger.success("✅ 已设置 currentNfcUuid = '\(self.currentNfcUuid ?? "nil")'")
                                            
                                            // 重置NFC管理器（保留currentNfcUuid）
                                            self.nfcManager.reset()
                                            
                                            // 打开输入框
                                            withAnimation(.easeInOut(duration: 0.4)) {
                                                self.showCheckInInputModal = true
                                            }
                                            Logger.success("✅ Check-in 输入框已打开（NFC扫描后）")
                                        }
                                    }
                                    
                                    nfcManager.onNFCError = { error in
                                        Logger.error("❌ NFC扫描失败: \(error)")
                                        // 可以显示错误提示
                                    }
                                }
                            },
                            onZoomIn: {
                                Logger.debug("🔍 ZOOM IN - Opening Oval Office map")
                                showOvalOfficeHistory = false
                                selectedTreasure = nil
                                
                                // 打开 Oval Office 地图
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    ovalOfficeVM.showOvalOffice = true
                                    showMap = false
                                }
                            },
                            onClose: {
                                Logger.debug("Closing Oval Office history modal")
                                showOvalOfficeHistory = false
                                selectedTreasure = nil
                            },
                            nfcUuid: currentNfcUuid
                        )
                    }
                    .zIndex(5000)  // 确保在所有导航界面元素之上
                }
                
                // Asset History覆盖层 - 直接浮现在导航界面上（仅用于建筑扫描模式）
                if showBuildingHistory {
                    AssetHistoryView(
                        targetBuilding: selectedTreasure,
                        nfcCoordinate: nfcCoordinate,
                        nfcUuid: currentNfcUuid,
                        onBackToNavigation: {
                            Logger.debug("🔙 返回初始主地图界面")
                            Logger.debug("   当前 selectedTreasure: \(selectedTreasure?.name ?? "nil")")
                            Logger.debug("   当前 currentSheetView: \(String(describing: currentSheetView))")
                            
                            // ⚠️ 设置标志，防止 onMapCameraChange 干扰
                            isExpandingCluster = true
                            
                            // 使用 DispatchQueue 确保视图立即刷新
                            DispatchQueue.main.async {
                                // 立即关闭所有视图
                                showBuildingHistory = false
                                currentSheetView = nil
                                showNavigation = false  // ⚠️ 关键：关闭导航全屏界面
                                
                                // 清除所有其他状态
                                nfcCoordinate = nil
                                currentNfcUuid = nil
                                routePolyline = nil
                                routeDistanceMeters = nil
                                isRouting = false
                                selectedTreasure = nil
                                buildingDetailRegion = nil
                                buildingDetailClusters = []
                                
                                Logger.debug("   清除后 selectedTreasure: \(selectedTreasure?.name ?? "nil")")
                                Logger.debug("   清除后 currentSheetView: \(String(describing: currentSheetView))")
                            
                                // 重置到初始地图区域（全香港视图）
                                let initialRegion = MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: 22.2731, longitude: 114.0056),
                                    span: MKCoordinateSpan(latitudeDelta: 0.1931, longitudeDelta: 0.3703)
                                )
                                
                                // 基于初始视图重新计算聚合
                                currentZoomLevel = initialRegion.span.latitudeDelta
                                buildingClusters = BuildingClusteringManager.shared.clusterBuildings(
                                    treasures,
                                    zoomLevel: currentZoomLevel,
                                    forceExpand: false
                                )
                                Logger.success("✅ 已返回初始主地图，显示 \(buildingClusters.count) 个聚合点")
                                Logger.debug("   buildingClusters.count: \(buildingClusters.count)")
                                Logger.debug("   selectedTreasure 仍为: \(selectedTreasure?.name ?? "nil")")
                                
                                // 最后更新地图位置
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentRegion = initialRegion
                                    cameraPosition = .region(initialRegion)
                                }
                                
                                Logger.debug("   地图更新后 selectedTreasure: \(selectedTreasure?.name ?? "nil")")
                            }
                        },
                        onShowNFCMismatch: {
                            showGPSError = true  // 使用独立状态，避免sheet冲突
                        },
                        onStartCheckIn: { buildingUUID in
                            // 启动Check-in功能 - 直接显示输入界面，不需要NFC验证
                            Logger.debug("Starting check-in for building UUID: \(buildingUUID)")
                            Logger.debug("当前状态 - showNavigation: \(showNavigation), currentSheetView: \(String(describing: currentSheetView))")
                            Logger.debug("showCheckInInputModal: \(showCheckInInputModal)")
                            
                            // 直接显示输入界面 - 使用覆盖层而不是sheet
                            if let building = selectedTreasure {
                                Logger.debug("✅ selectedTreasure存在: \(building.name)")
                                
                                // 设置NFC状态为checkInInput
                                nfcManager.currentPhase = .checkInInput
                                nfcManager.didDetectNFC = true
                                
                                // 设置输入框的默认值
                                ovalOfficeVM.assetName = building.name
                                ovalOfficeVM.assetImage = nil
                                ovalOfficeVM.assetDescription = ""
                                ovalOfficeVM.isNewAsset = false
                                
                                // 设置NFC回调处理Check-in完成
                                nfcManager.onNFCDetected = {
                                    DispatchQueue.main.async {
                                        switch self.nfcManager.currentPhase {
                                        case .checkInCompleted:
                                            // Check-in第二次NFC验证成功，检查GPS坐标匹配
                                            Logger.success("Check-in second NFC verified, checking GPS coordinates...")
                                            
                                            // 检查GPS坐标匹配
                                            self.handleCheckInCompletion(for: building)
                                        default:
                                            break
                                        }
                                    }
                                }
                                
                                // 使用动画显示输入模态框，实现顺滑过渡
                                Logger.debug("⏰ 即将设置 showCheckInInputModal = true")
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    showCheckInInputModal = true
                                }
                                Logger.debug("✅ showCheckInInputModal已设置为: \(showCheckInInputModal)")
                            } else {
                                Logger.error("❌ selectedTreasure 为 nil!")
                            }
                        },
                        currentUsername: username
                    )
                    .zIndex(500)  // 历史记录视图的zIndex
                }
                
                // NFC错误覆盖层（使用独立状态避免sheet冲突）
                if showGPSError {
                    NFCErrorView(
                        onBack: {
                            Logger.debug("🔙 关闭GPS错误框")
                            
                            // 关闭错误框
                            showGPSError = false
                            
                            // 清除NFC相关状态，避免重复触发
                            nfcCoordinate = nil
                            currentNfcUuid = nil
                            
                            Logger.success("✅ 错误框已关闭")
                        }
                    )
                    .onAppear {
                        Logger.debug("🎯 GPS错误视图已显示")
                    }
                    .zIndex(1000)
                }
                
                // Check-in输入模态框覆盖层
                if showCheckInInputModal {
                    CheckInInputModal(
                        assetName: $ovalOfficeVM.assetName,
                        assetImage: $ovalOfficeVM.assetImage,
                        assetDescription: $ovalOfficeVM.assetDescription,
                        appGreen: appGreen,
                        nfcManager: nfcManager,
                        onCancel: {
                            // 关闭输入框
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showCheckInInputModal = false
                            }
                            // 重置NFC管理器和注册状态
                            nfcManager.reset()
                        }
                    )
                    .onAppear {
                        Logger.debug("🎯 CheckInInputModal已显示")
                    }
                    .zIndex(2000)  // 确保输入框显示在所有内容之上
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // 定位到Oval Office（ID 900）
    private func locateOvalOffice() {
        Logger.debug("Locating Oval Office...")
        
        // 查找ID为900的建筑
        guard let ovalOffice = treasures.first(where: { $0.id == "900" }) else {
            Logger.warning("Oval Office (ID 900) not found")
            return
        }
        
        Logger.database("Found Oval Office at (\(ovalOffice.coordinate.latitude), \(ovalOffice.coordinate.longitude))")
        
        // 使用平滑动画定位并放大
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            // 居中到Oval Office
            currentRegion.center = ovalOffice.coordinate
            
            // 设置合适的缩放级别（0.003度，约330米范围，可以清楚看到周围建筑）
            currentRegion.span = MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
            cameraPosition = .region(currentRegion)
            
            // 选中Oval Office，高亮显示
            selectedTreasure = ovalOffice
            routePolyline = nil
            routeDistanceMeters = nil
            isRouting = false
            
            // 更新聚合，确保900点能单独显示
            currentZoomLevel = currentRegion.span.latitudeDelta
            buildingClusters = BuildingClusteringManager.shared.clusterBuildings(
                treasures,
                zoomLevel: currentZoomLevel,
                forceExpand: false
            )
        }
        
        Logger.success("Navigated to Oval Office")
    }
    
    // 搜索历史建筑
    private func performSearch(_ query: String) {
        guard !query.isEmpty else {
            clearSearch()
            return
        }
        
        Logger.debug("Searching for: \(query)")
        
        // 搜索匹配的建筑（名称、地址、地区）
        let results = treasures.filter { treasure in
            treasure.name.localizedCaseInsensitiveContains(query) ||
            treasure.address.localizedCaseInsensitiveContains(query) ||
            treasure.district.localizedCaseInsensitiveContains(query)
        }
        
        searchResults = results
        Logger.success("Found \(results.count) matching buildings")
        
        if results.isEmpty {
            // 没有匹配结果，显示提示
            showNoResultsAlert = true
            isSearchMode = false
            Logger.warning("No buildings found matching: \(query)")
            
        } else if results.count == 1 {
            // 只有一个匹配结果，直接选中并显示
            let building = results[0]
            isSearchMode = false  // 退出搜索模式（因为会选中建筑）
            
            // 隐藏键盘
            isSearchFieldFocused = false
            
            // 保存当前地图状态
            buildingDetailRegion = currentRegion
            buildingDetailClusters = buildingClusters  // 保存当前聚合状态
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                currentRegion.center = building.coordinate
                currentRegion.span = MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                cameraPosition = .region(currentRegion)
                
                selectedTreasure = building
                routePolyline = nil
                routeDistanceMeters = nil
                isRouting = false
                
                startHunt(to: building.coordinate)
            }
            
            // 关闭搜索框
            showSearch = false
            searchText = ""
            
        } else if results.count > 1 {
            // 多个匹配结果，缩放地图包含所有结果
            isSearchMode = true  // 进入搜索模式
            
            // 隐藏键盘
            isSearchFieldFocused = false
            
            let coordinates = results.map { $0.coordinate }
            let minLat = coordinates.map { $0.latitude }.min() ?? currentRegion.center.latitude
            let maxLat = coordinates.map { $0.latitude }.max() ?? currentRegion.center.latitude
            let minLon = coordinates.map { $0.longitude }.min() ?? currentRegion.center.longitude
            let maxLon = coordinates.map { $0.longitude }.max() ?? currentRegion.center.longitude
            
            let centerLat = (minLat + maxLat) / 2
            let centerLon = (minLon + maxLon) / 2
            let latDelta = (maxLat - minLat) * 1.5  // 50%边距
            let lonDelta = (maxLon - minLon) * 1.5
            
            // 清除选中状态，显示所有匹配的建筑
            selectedTreasure = nil
            
            // 只聚合搜索结果
            currentZoomLevel = max(latDelta, 0.002)
            buildingClusters = BuildingClusteringManager.shared.clusterBuildings(
                results,
                zoomLevel: currentZoomLevel,
                forceExpand: false
            )
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                currentRegion = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                    span: MKCoordinateSpan(latitudeDelta: max(latDelta, 0.002), longitudeDelta: max(lonDelta, 0.002))
                )
                cameraPosition = .region(currentRegion)
            }
        }
    }
    
    // 清除搜索
    private func clearSearch() {
        searchResults = []
        isSearchMode = false
        
        // 恢复显示所有建筑
        if !treasures.isEmpty {
            updateClusters(debounce: false)
        }
    }
    
    // 恢复初始地图状态
    private func restoreInitialMapState() {
        Logger.info("Restoring initial map state...")
        
        // 清除搜索
        showSearch = false
        searchText = ""
        searchResults = []
        isSearchMode = false
        
        // 清除选中状态
        selectedTreasure = nil
        routePolyline = nil
        routeDistanceMeters = nil
        isRouting = false
        showClue = false
        
        // 恢复初始地图区域
        if let initial = initialRegion {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                currentRegion = initial
                cameraPosition = .region(initial)
                currentZoomLevel = initial.span.latitudeDelta
            }
        }
        
        // 恢复初始聚合
        updateClusters(debounce: false)
        
        Logger.success("Map state restored")
    }
    
    // 处理NFC探索扫描结果
    private func handleNFCExploreResult() {
        Logger.debug("🔍 ========== 处理NFC探索扫描结果 ==========")
        Logger.debug("🔍 从 NFCManager 读取到的 UUID: '\(nfcManager.assetUUID)'")
        Logger.debug("🔍 UUID 长度: \(nfcManager.assetUUID.count) 字符")
        Logger.debug("🔍 UUID 是否为空: \(nfcManager.assetUUID.isEmpty)")
        
        Task {
            do {
                // 检查NFC UUID是否已有历史记录
                Logger.debug("🔍 开始检查 NFC UUID 是否已有历史记录...")
                let nfcExists = try await BuildingCheckInManager.shared.checkNFCExists(nfcUuid: nfcManager.assetUUID)
                Logger.debug("🔍 NFC exists检查结果: \(nfcExists)")
                
                await MainActor.run {
                    // 设置当前NFC UUID
                    currentNfcUuid = nfcManager.assetUUID
                    Logger.success("✅ 已设置 currentNfcUuid = '\(currentNfcUuid ?? "nil")'")
                    Logger.debug("   UUID长度: \(currentNfcUuid?.count ?? 0) 字符")
                    
                    // ⚠️ 对于 Tap 探索功能，总是显示历史记录界面
                    // 即使没有记录，也让用户看到空列表（可以点击 "Check In Mine" 添加）
                    Logger.success("📋 显示历史记录界面（Tap探索模式）")
                    Logger.debug("   设置 currentSheetView = .assetHistory")
                    Logger.debug("   传递给 AssetHistoryView 的 nfcUuid: '\(currentNfcUuid ?? "nil")'")
                    Logger.debug("   NFC exists: \(nfcExists) (有记录: \(nfcExists), 无记录: \(!nfcExists))")
                    
                    isNewNfcTag = !nfcExists  // 标记是否为新标签（用于后续可能的处理）
                    currentSheetView = .assetHistory
                    Logger.success("   ✅ currentSheetView 已设置为 .assetHistory")
                    
                    // 重置NFC状态（不影响currentNfcUuid）
                    nfcManager.reset()
                    Logger.debug("   nfcManager.reset() 后，currentNfcUuid 仍为: '\(currentNfcUuid ?? "nil")'")
                    Logger.debug("🔍 ========== NFC探索扫描处理完成 ==========")
                }
            } catch {
                Logger.error("❌ 检查NFC历史记录失败: \(error.localizedDescription)")
                await MainActor.run {
                    // 出错时默认显示历史记录界面
                    Logger.warning("⚠️ 出错，默认显示历史记录界面")
                    // ⚠️ 即使出错，也要设置 currentNfcUuid
                    currentNfcUuid = nfcManager.assetUUID
                    Logger.debug("   设置 currentNfcUuid = '\(currentNfcUuid ?? "nil")'")
                    currentSheetView = .assetHistory
                    nfcManager.reset()
                }
            }
        }
    }
    
    // 显示新NFC的Check-in输入界面
    private func showNewNFCCheckInInput() {
        Logger.debug("🎨 显示新NFC Check-in输入界面")
        Logger.debug("   当前 currentNfcUuid: \(currentNfcUuid ?? "nil")")
        Logger.debug("   当前 nfcManager.assetUUID: \(nfcManager.assetUUID)")
        
        // 如果currentNfcUuid为空但nfcManager有UUID，恢复它
        if (currentNfcUuid == nil || currentNfcUuid?.isEmpty == true) && !nfcManager.assetUUID.isEmpty {
            currentNfcUuid = nfcManager.assetUUID
            Logger.warning("⚠️ 恢复 currentNfcUuid 从 nfcManager: \(currentNfcUuid ?? "nil")")
        }
        
        // 设置输入框的默认值
        ovalOfficeVM.assetName = "New Asset"
        ovalOfficeVM.assetImage = nil
        ovalOfficeVM.assetDescription = ""
        ovalOfficeVM.isNewAsset = true
        
        // 设置NFC回调处理保存完成（新NFC不需要GPS验证）
        nfcManager.onNFCDetected = {
            DispatchQueue.main.async {
                switch self.nfcManager.currentPhase {
                case .checkInCompleted:
                    // 新NFC的第二次NFC验证成功，直接保存数据（跳过GPS检查）
                    Logger.success("New NFC second scan verified, saving data (no GPS check)...")
                    self.handleNewNFCCheckInCompletion()
                default:
                    break
                }
            }
        }
        
        // 直接显示输入界面，使用覆盖层模式
        showCheckInInputModal = true
        
        Logger.success("✅ 新NFC检测成功，进入输入界面（无需GPS验证）")
    }
    
    // 处理新NFC的Check-in完成（跳过GPS检查）
    private func handleNewNFCCheckInCompletion() {
        Logger.debug("💾 处理新NFC Check-in完成（跳过GPS检查）")
        Logger.debug("   currentNfcUuid: \(currentNfcUuid ?? "nil")")
        Logger.debug("   nfcManager.assetUUID: \(nfcManager.assetUUID)")
        
        // 如果currentNfcUuid为空，尝试从nfcManager获取
        if currentNfcUuid == nil || currentNfcUuid?.isEmpty == true {
            currentNfcUuid = nfcManager.assetUUID.isEmpty ? nil : nfcManager.assetUUID
            Logger.warning("⚠️ currentNfcUuid为空，从nfcManager获取: \(currentNfcUuid ?? "nil")")
        }
        
        // ⚠️ 重要：在 Task 开始前保存所有值，避免 reset() 导致数据丢失
        let savedNfcUuid = currentNfcUuid
        let savedAssetName = ovalOfficeVM.assetName.isEmpty ? nil : ovalOfficeVM.assetName
        let savedDescription = ovalOfficeVM.assetDescription
        let savedImage = ovalOfficeVM.assetImage
        
        // 直接保存数据，不进行GPS检查
        Task {
            do {
                let displayUsername = username.isEmpty ? "Guest" : username
                
                // 获取用户当前位置作为GPS坐标
                let latitude = locationManager.location?.coordinate.latitude ?? 22.35
                let longitude = locationManager.location?.coordinate.longitude ?? 114.15
                
                Logger.debug("💾 保存新NFC Check-in:")
                Logger.debug("   buildingId: \(savedNfcUuid ?? "unknown")")
                Logger.debug("   username: \(displayUsername)")
                Logger.debug("   assetName: \(savedAssetName ?? "nil")")
                Logger.debug("   nfcUuid: \(savedNfcUuid ?? "nil")")
                Logger.debug("   GPS: (\(latitude), \(longitude))")
                
                // 保存到asset_checkins表
                // 在探索模式下，使用一个特殊的building_id来标识这是NFC探索模式的记录
                let explorationBuildingId = "nfc_exploration_\(savedNfcUuid ?? "unknown")"
                
                Logger.debug("💾 探索模式保存参数:")
                Logger.debug("   buildingId: \(explorationBuildingId)")
                Logger.debug("   nfcUuid: \(savedNfcUuid ?? "nil")")
                
                let _ = try await BuildingCheckInManager.shared.saveCheckIn(
                    buildingId: explorationBuildingId, // 使用特殊标识作为building_id
                    username: displayUsername,
                    assetName: savedAssetName,
                    description: savedDescription,
                    image: savedImage,
                    nfcUuid: savedNfcUuid,
                    latitude: latitude,
                    longitude: longitude
                )
                
                await MainActor.run {
                    Logger.success("✅ 新NFC信息保存成功")
                    
                    // 关闭所有界面，返回主地图
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showCheckInInputModal = false
                        showBuildingHistory = false
                        currentSheetView = nil
                    }
                    
                    // 重置输入
                    ovalOfficeVM.resetAssetInput()
                    
                    // 重置NFC管理器和状态
                    nfcManager.reset()
                    isNewNfcTag = false
                    currentNfcUuid = nil
                    nfcCoordinate = nil
                    
                    Logger.success("🔙 已返回主地图界面")
                }
            } catch {
                Logger.error("❌ 保存新NFC信息失败: \(error.localizedDescription)")
                await MainActor.run {
                    // 可以在这里显示错误提示
                    Logger.error("保存失败，请重试")
                }
            }
        }
    }
    
    // 直接启动NFC扫描（跳过扫描页面）
    private func startDirectNFCScan() {
        Logger.nfc("Starting direct NFC scan from building...")
        
        // 使用现有的NFCManager直接启动探索扫描
        nfcManager.startExploreScan()
        
        // 设置回调处理NFC检测结果
        nfcManager.onNFCDetected = {
            Logger.success("NFC detected in direct scan from building")
            
            DispatchQueue.main.async {
                // ✅ 重要：设置 currentNfcUuid
                self.currentNfcUuid = self.nfcManager.assetUUID
                Logger.success("✅ [Building Scan] 设置 currentNfcUuid = '\(self.currentNfcUuid ?? "nil")'")
                Logger.debug("   UUID 长度: \(self.currentNfcUuid?.count ?? 0)")
                
                // 使用用户当前位置作为NFC坐标（实际NFC标签的位置）
                if let userLocation = self.locationManager.location {
                    self.nfcCoordinate = userLocation.coordinate
                    Logger.location("Using user location as NFC coordinate: \(userLocation.coordinate)")
                } else {
                    // 备用坐标
                    self.nfcCoordinate = CLLocationCoordinate2D(latitude: 22.35, longitude: 114.15)
                    Logger.location("Using fallback coordinate as NFC coordinate: \(self.nfcCoordinate!)")
                }
                
                // ⚠️ 从建筑扫描NFC时，需要验证GPS距离
                guard let nfcUuid = self.currentNfcUuid, !nfcUuid.isEmpty else {
                    Logger.error("❌ NFC UUID is empty")
                    return
                }
                
                guard let selectedBuilding = self.selectedTreasure else {
                    Logger.error("❌ No building selected")
                    return
                }
                
                // 异步验证GPS距离
                Task {
                    do {
                        // 获取NFC的第一条注册记录（包含GPS信息）
                        let firstCheckIn = try await BuildingCheckInManager.shared.getFirstCheckInByNFC(nfcUuid: nfcUuid)
                        
                        await MainActor.run {
                            if let firstCheckIn = firstCheckIn,
                               let nfcLat = firstCheckIn.gpsLatitude,
                               let nfcLon = firstCheckIn.gpsLongitude {
                                // NFC已注册，检查GPS距离
                                let nfcRegisteredCoord = CLLocationCoordinate2D(latitude: nfcLat, longitude: nfcLon)
                                let buildingCoord = selectedBuilding.coordinate
                                let distance = self.calculateDistance(from: nfcRegisteredCoord, to: buildingCoord)
                                
                                Logger.location("📍 GPS距离验证（建筑扫描模式）:")
                                Logger.debug("   当前建筑: \(selectedBuilding.name)")
                                Logger.debug("   建筑GPS: (\(buildingCoord.latitude), \(buildingCoord.longitude))")
                                Logger.debug("   NFC注册GPS: (\(nfcLat), \(nfcLon))")
                                Logger.debug("   距离: \(String(format: "%.2f", distance)) 米")
                                Logger.debug("   阈值: 40.0 米")
                                
                                if distance > 40.0 {
                                    // 距离超过40米，显示GPS不匹配警告
                                    Logger.error("❌ GPS距离不匹配！距离 \(String(format: "%.2f", distance))m > 40m")
                                    Logger.error("   显示GPS错误提示...")
                                    self.showGPSError = true
                                } else {
                                    // 距离在40米内，显示历史记录
                                    Logger.success("✅ GPS距离匹配！距离 \(String(format: "%.2f", distance))m ≤ 40m")
                                    Logger.success("📋 [Building Scan] 显示历史记录界面（在地图内部）")
                                    Logger.debug("   传递的 nfcUuid: '\(self.currentNfcUuid ?? "nil")'")
                                    
                                    // 检查是否是 Oval Office
                                    if selectedBuilding.id == "900" {
                                        Logger.debug("🏛️ Oval Office detected - showing Oval Office history modal")
                                        self.showOvalOfficeHistory = true
                                    } else {
                                        self.showBuildingHistory = true  // 使用专用状态，避免触发fullScreenCover
                                    }
                                }
                            } else {
                                // NFC未注册（第一次扫描），直接显示历史记录（空列表）
                                Logger.warning("⚠️ NFC未注册，这是第一次扫描")
                                Logger.success("📋 [Building Scan] 显示历史记录界面（在地图内部）")
                                Logger.debug("   传递的 nfcUuid: '\(self.currentNfcUuid ?? "nil")'")
                                
                                // 检查是否是 Oval Office
                                if selectedBuilding.id == "900" {
                                    Logger.debug("🏛️ Oval Office detected - showing Oval Office history modal")
                                    self.showOvalOfficeHistory = true
                                } else {
                                    self.showBuildingHistory = true  // 使用专用状态，避免触发fullScreenCover
                                }
                            }
                        }
                    } catch {
                        Logger.error("❌ 获取NFC第一条记录失败: \(error.localizedDescription)")
                        // 出错时，直接显示历史记录（容错处理）
                        await MainActor.run {
                            Logger.warning("⚠️ 由于错误，跳过GPS验证，直接显示历史记录")
                            
                            // 检查是否是 Oval Office
                            if selectedBuilding.id == "900" {
                                Logger.debug("🏛️ Oval Office detected - showing Oval Office history modal")
                                self.showOvalOfficeHistory = true
                            } else {
                                self.showBuildingHistory = true
                            }
                        }
                    }
                }
            }
        }
        
        nfcManager.onNFCError = { error in
            Logger.error("NFC Error in direct scan from building: \(error)")
            // 可以在这里显示错误提示
        }
    }
    
    // 计算两个GPS坐标之间的距离（米）
    private func calculateDistance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }
    
    // 根据GPS坐标查找最近的建筑（用于导航功能）
    private func findNearestBuilding(latitude: Double, longitude: Double) -> Treasure? {
        let targetLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        // 查找距离最近的建筑
        var nearestBuilding: Treasure? = nil
        var minDistance: CLLocationDistance = Double.infinity
        
        for building in treasures {
            let buildingLocation = CLLocation(latitude: building.coordinate.latitude, longitude: building.coordinate.longitude)
            let distance = targetLocation.distance(from: buildingLocation)
            
            if distance < minDistance {
                minDistance = distance
                nearestBuilding = building
            }
        }
        
        Logger.debug("📍 最近的建筑: \(nearestBuilding?.name ?? "nil"), 距离: \(String(format: "%.2f", minDistance))m")
        
        // 如果最近的建筑距离超过100米，可能不是正确的建筑
        if minDistance > 100 {
            Logger.warning("⚠️ 最近的建筑距离超过100米，可能不准确")
        }
        
        return nearestBuilding
    }
    
    // 处理Check-in完成，检查GPS坐标匹配
    private func handleCheckInCompletion(for building: Treasure) {
        Logger.debug("Current showCheckInInputModal state: \(showCheckInInputModal)")
        
        // 异步检查这个建筑是否已有check-in记录
        Task {
            do {
                // 检查建筑是否已有历史记录
                let existingCheckIns = try await BuildingCheckInManager.shared.getCheckIns(for: building.id)
                let isFirstRegistration = existingCheckIns.isEmpty
                
                await MainActor.run {
                    if isFirstRegistration {
                        // 🆕 第一次注册，跳过GPS检查，直接保存
                        Logger.success("🆕 这是该建筑的第一次NFC注册，跳过GPS距离检查")
                        Logger.debug("   Building: \(building.name)")
                        Logger.debug("   Building ID: \(building.id)")
                        Logger.debug("   直接保存数据...")
                        
                        saveCheckInData(for: building)
                        closeCheckInModal()
                    } else {
                        // 已有记录，需要进行GPS验证
                        Logger.debug("📋 该建筑已有 \(existingCheckIns.count) 条历史记录，需要进行GPS验证")
                        
                        // 检查GPS坐标匹配
                        if let nfcCoord = nfcCoordinate {
                            let distance = calculateDistance(from: nfcCoord, to: building.coordinate)
                            Logger.location("GPS Coordinate Check for Check-out:")
                            Logger.debug("   Target Building: \(building.name)")
                            Logger.debug("   Building Coordinate: \(building.coordinate)")
                            Logger.debug("   NFC Tag Coordinate: \(nfcCoord)")
                            Logger.debug("   Distance: \(String(format: "%.2f", distance)) meters")
                            Logger.debug("   Threshold: 40.0 meters")
                            
                            if distance < 40.0 {
                                // GPS坐标匹配，保存check-in数据
                                Logger.success("GPS coordinates MATCH! Distance \(String(format: "%.2f", distance))m < 40m")
                                Logger.success("Proceeding to save check-in data...")
                                saveCheckInData(for: building)
                                closeCheckInModal()
                            } else {
                                // GPS坐标不匹配，显示错误提示
                                Logger.error("GPS coordinates MISMATCH! Distance \(String(format: "%.2f", distance))m >= 40m")
                                Logger.error("Showing GPS mismatch error modal...")
                                showGPSErrorModal()
                            }
                        } else {
                            Logger.warning("NFC coordinate not available, proceeding without GPS check...")
                            // 如果没有NFC坐标信息，直接保存数据
                            saveCheckInData(for: building)
                            closeCheckInModal()
                        }
                    }
                }
            } catch {
                // 如果检查失败，记录错误并继续（默认跳过GPS检查）
                Logger.error("❌ 检查建筑历史记录失败: \(error.localizedDescription)")
                Logger.warning("⚠️ 由于检查失败，跳过GPS验证直接保存")
                
                await MainActor.run {
                    saveCheckInData(for: building)
                    closeCheckInModal()
                }
            }
        }
    }
    
    // 关闭Check-in模态框
    private func closeCheckInModal() {
        Logger.info("Auto-clicking close button to close input modal...")
        withAnimation(.easeInOut(duration: 0.3)) {
            showCheckInInputModal = false
        }
        nfcManager.reset()
        Logger.success("Check-in completed and input modal auto-closed!")
    }
    
    // 显示GPS错误模态框
    private func showGPSErrorModal() {
        Logger.error("🚨 显示GPS错误模态框")
        Logger.debug("当前状态 - showCheckInInputModal: \(showCheckInInputModal), showNavigation: \(showNavigation)")
        Logger.debug("showGPSError当前值: \(showGPSError)")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showCheckInInputModal = false
        }
        
        // 使用DispatchQueue确保状态更新
        DispatchQueue.main.async {
            self.showGPSError = true
            Logger.success("✅ showGPSError已设置为true")
            Logger.debug("showGPSError设置后值: \(self.showGPSError)")
        }
        
        nfcManager.reset()
    }

    // 保存Check-in数据
    private func saveCheckInData(for building: Treasure) {
        Logger.database("Saving check-in data for building: \(building.name)")
        
        // ⚠️ 重要：立即保存这些值，因为 nfcManager.reset() 可能在 Task 完成前被调用
        let displayUsername = username.isEmpty ? "Guest" : username
        
        // ✅ 修复：优先使用 currentNfcUuid，因为 nfcManager.assetUUID 可能已被 reset() 清空
        let savedNfcUuid: String? = {
            if let uuid = currentNfcUuid, !uuid.isEmpty {
                return uuid
            } else if !nfcManager.assetUUID.isEmpty {
                return nfcManager.assetUUID
            } else {
                return nil
            }
        }()
        
        let savedAssetName = ovalOfficeVM.assetName.isEmpty ? nil : ovalOfficeVM.assetName
        let savedDescription = ovalOfficeVM.assetDescription
        let savedImage = ovalOfficeVM.assetImage
        let savedLatitude = locationManager.location?.coordinate.latitude
        let savedLongitude = locationManager.location?.coordinate.longitude
        
        // 调试：打印 NFC UUID 信息
        Logger.debug("📍 NFC UUID 调试信息:")
        Logger.debug("   currentNfcUuid = '\(currentNfcUuid ?? "nil")'")
        Logger.debug("   nfcManager.assetUUID = '\(nfcManager.assetUUID)'")
        Logger.debug("   保存的 NFC UUID 值: \(savedNfcUuid ?? "nil")")
        
        // 保存到 Supabase
        Task {
            do {
                let checkIn = try await BuildingCheckInManager.shared.saveCheckIn(
                    buildingId: building.id,
                    username: displayUsername,
                    assetName: savedAssetName,
                    description: savedDescription,
                    image: savedImage,
                    nfcUuid: savedNfcUuid,
                    latitude: savedLatitude,
                    longitude: savedLongitude
                )
                
                Logger.success("✅ Check-in saved successfully!")
                Logger.debug("   - Building: \(building.name)")
                Logger.debug("   - Username: \(displayUsername)")
                Logger.debug("   - Asset Name: \(savedAssetName ?? "nil")")
                Logger.debug("   - NFC UUID: \(savedNfcUuid ?? "nil")")
                Logger.debug("   - Check-in ID: \(checkIn.id)")
                
                // 关闭输入框和历史记录，保持导航模式和地图比例
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showCheckInInputModal = false
                    self.showBuildingHistory = false
                    self.showOvalOfficeHistory = false
                    // ⚠️ 不关闭 showNavigation，保持导航模式
                    // ⚠️ 不重置 currentRegion，保持地图比例
                }
                
                // 清空输入
                self.ovalOfficeVM.resetAssetInput()
                
                // 重置NFC状态
                self.nfcManager.reset()
                self.nfcCoordinate = nil
                self.currentNfcUuid = nil  // ✅ 保存成功后清空 currentNfcUuid
                
                Logger.success("🔙 已返回导航界面（保持地图比例）")
            } catch {
                Logger.error("❌ Failed to save check-in: \(error.localizedDescription)")
                // 可以在这里显示错误提示给用户
            }
        }
    }
    
    // 指南针功能 - 定位到用户位置
    private func centerOnUserLocation() {
        Logger.location("Centering on user location...")
        
        guard let userLocation = locationManager.location else {
            Logger.warning("User location not available")
            // 如果没有用户位置，请求位置权限
            locationManager.requestLocation()
            return
        }
        
        let userCoordinate = userLocation.coordinate
        Logger.location("User location: (\(userCoordinate.latitude), \(userCoordinate.longitude))")
        
        // 1km半径对应的经纬度跨度
        // 1度纬度约等于111km，所以1km ≈ 0.009度
        let spanFor1km: Double = 0.009
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentRegion = MKCoordinateRegion(
                center: userCoordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: spanFor1km,
                    longitudeDelta: spanFor1km
                )
            )
            cameraPosition = .region(currentRegion)
            
            // 更新聚合
            currentZoomLevel = spanFor1km
            if !treasures.isEmpty {
                updateClusters(debounce: false)
            }
        }
        
        Logger.success("Centered map on user location with 1km radius")
    }

    private func generateTreasureLocations(count: Int) {
        // 从Supabase加载历史建筑数据
        Task {
            await loadHistoricBuildings()
        }
    }

    // 欢迎页触发的预加载逻辑（只执行一次，避免重复）
    private func preloadMapIfNeeded() {
        if hasPreloadedMap || isMapPreloading { return }
        if !treasures.isEmpty { hasPreloadedMap = true; return }
        isMapPreloading = true
        Task { @MainActor in
            await loadHistoricBuildings()
            hasPreloadedMap = true
            isMapPreloading = false
        }
    }
    
    // 加载历史建筑数据
    @MainActor
    private func loadHistoricBuildings() async {
        Logger.database("Loading historic buildings...")
        
        do {
            // 加载所有历史建筑数据
            let buildings = try await HistoricBuildingsManager.shared.loadAllBuildings()
            
            Logger.success("Loaded \(buildings.count) historic buildings")
            
            // 转换为Treasure格式
            treasures = buildings.map { building in
                Treasure(
                    id: building.id,
                    coordinate: building.location,
                    name: building.displayName,
                    district: building.district,
                    address: building.address
                )
            }
            
            Logger.success("Converted to \(treasures.count) treasure markers")
            
            // 检查是否包含Oval Office (ID 900)
            if let ovalOffice = treasures.first(where: { $0.id == "900" }) {
                Logger.database("Found Oval Office: \(ovalOffice.name) at (\(ovalOffice.coordinate.latitude), \(ovalOffice.coordinate.longitude))")
            } else {
                Logger.warning("Oval Office (ID 900) not found in loaded buildings")
            }
            
            // 计算包含所有建筑的初始区域
            if !treasures.isEmpty {
                let latitudes = treasures.map { $0.coordinate.latitude }
                let longitudes = treasures.map { $0.coordinate.longitude }
                
                let minLat = latitudes.min() ?? 22.2
                let maxLat = latitudes.max() ?? 22.5
                let minLon = longitudes.min() ?? 114.0
                let maxLon = longitudes.max() ?? 114.3
                
                let centerLat = (minLat + maxLat) / 2
                let centerLon = (minLon + maxLon) / 2
                let latDelta = (maxLat - minLat) * 1.2  // 添加20%边距
                let lonDelta = (maxLon - minLon) * 1.2
                
                currentRegion = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                    span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
                )
                cameraPosition = .region(currentRegion)
                
                // 保存初始地图状态（用于恢复按钮）
                initialRegion = currentRegion
                
                Logger.location("Initial region: center=(\(String(format: "%.4f", centerLat)), \(String(format: "%.4f", centerLon))), span=(\(String(format: "%.4f", latDelta)), \(String(format: "%.4f", lonDelta)))")
            }
            
            // 初始聚合（不使用防抖，立即显示）
            updateClusters(debounce: false)
            
        } catch {
            Logger.error("Failed to load historic buildings: \(error)")
            // 如果加载失败，使用空列表
            treasures = []
            buildingClusters = []
        }
    }
    
    // 更新建筑聚合（带防抖）
    private func updateClusters(debounce: Bool = true) {
        // 取消之前的更新任务
        clusterUpdateWorkItem?.cancel()
        
        if debounce {
            // 使用防抖，避免频繁更新
            let workItem = DispatchWorkItem {
                self.performClusterUpdate()
            }
            clusterUpdateWorkItem = workItem
            // 延迟150ms执行，等待用户停止缩放
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
        } else {
            // 立即更新（用于初始加载或展开操作）
            performClusterUpdate()
        }
    }
    
    // 执行实际的聚合更新（后台线程优化）
    private func performClusterUpdate() {
        let newZoomLevel = currentRegion.span.latitudeDelta
        let oldZoomLevel = currentZoomLevel
        let region = currentRegion
        let searchMode = isSearchMode
        let searchResults = self.searchResults
        
        // 计算缩放变化百分比
        let zoomChangePercent = oldZoomLevel > 0 ? abs(newZoomLevel - oldZoomLevel) / oldZoomLevel : 0
        
        // 设置阈值：只有缩放变化超过5%时才认为是真正的缩放操作
        // 小于5%的变化认为是平移或地图内部调整，保持当前聚合状态
        let zoomThreshold = 0.05
        
        // 判断是否是真正的缩放操作
        let isSignificantZoom = zoomChangePercent > zoomThreshold
        
        // 判断是放大还是缩小
        let isZoomingIn = isSignificantZoom && (newZoomLevel < oldZoomLevel)  // span变小 = 放大
        let isZoomingOut = isSignificantZoom && (newZoomLevel > oldZoomLevel)  // span变大 = 缩小
        
        // 注释掉频繁的调试日志
        // if isZoomingIn {
        //     Logger.debug("🔍 Zooming IN detected (span: \(String(format: "%.4f", oldZoomLevel)) → \(String(format: "%.4f", newZoomLevel)), change: \(String(format: "%.1f%%", zoomChangePercent * 100)))")
        // } else if isZoomingOut {
        //     Logger.debug("🔎 Zooming OUT detected (span: \(String(format: "%.4f", oldZoomLevel)) → \(String(format: "%.4f", newZoomLevel)), change: \(String(format: "%.1f%%", zoomChangePercent * 100)))")
        // } else {
        //     Logger.debug("📍 Panning detected (span change: \(String(format: "%.1f%%", zoomChangePercent * 100)) < \(String(format: "%.1f%%", zoomThreshold * 100)))")
        // }
        
        // 在后台线程执行聚合计算，避免阻塞UI
        DispatchQueue.global(qos: .userInitiated).async {
            var targetBuildings: [Treasure]
            
            if searchMode && !searchResults.isEmpty {
                // 搜索模式：只处理搜索结果
                targetBuildings = searchResults
                // Logger.debug("Search mode: Processing \(searchResults.count) search results")
            } else {
                // 正常模式：处理当前可视区域内的建筑（扩展20%边界）
                targetBuildings = self.filterBuildingsInRegion(region, expandBy: 1.2)
                // Logger.debug("Normal mode: Total buildings: \(self.treasures.count), Visible: \(targetBuildings.count)")
            }
            
            // 在后台计算聚合
            // 只有在真正的放大操作时才强制展开
            // 平移操作时保持正常聚合逻辑，确保稳定性
            let newClusters = BuildingClusteringManager.shared.clusterBuildings(
                targetBuildings,
                zoomLevel: newZoomLevel,
                forceExpand: isZoomingIn
            )
            
            if isZoomingIn {
                Logger.info("🔍 Zoom IN: Clustered into \(newClusters.count) groups (zoom: \(String(format: "%.4f", newZoomLevel)))")
            } else if isZoomingOut {
                Logger.info("🔎 Zoom OUT: Clustered into \(newClusters.count) groups (zoom: \(String(format: "%.4f", newZoomLevel)))")
            } else {
                Logger.info("📍 Pan: Clustered into \(newClusters.count) groups (zoom: \(String(format: "%.4f", newZoomLevel)))")
            }
            
            // 回到主线程更新UI
            DispatchQueue.main.async {
                self.currentZoomLevel = newZoomLevel
                
                // 使用更平滑的spring动画，持续时间0.35秒
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.buildingClusters = newClusters
                }
            }
        }
    }
    
    // 过滤可视区域内的建筑
    private func filterBuildingsInRegion(_ region: MKCoordinateRegion, expandBy factor: Double = 1.0) -> [Treasure] {
        let latDelta = region.span.latitudeDelta * factor
        let lonDelta = region.span.longitudeDelta * factor
        
        let minLat = region.center.latitude - latDelta / 2
        let maxLat = region.center.latitude + latDelta / 2
        let minLon = region.center.longitude - lonDelta / 2
        let maxLon = region.center.longitude + lonDelta / 2
        
        // 过滤建筑，但始终包含Oval Office (ID 900)
        let filtered = treasures.filter { treasure in
            let lat = treasure.coordinate.latitude
            let lon = treasure.coordinate.longitude
            let inRegion = lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
            let isOvalOffice = treasure.id == "900"
            return inRegion || isOvalOffice  // 在区域内或是Oval Office
        }
        
        return filtered
    }
    
    // 展开聚合点
    private func expandCluster(_ cluster: BuildingCluster) {
        Logger.location("Expanding cluster with \(cluster.count) buildings")
        
        // 设置标志，防止 onMapCameraChange 干扰
        isExpandingCluster = true
        
        // 定义大型聚合点的阈值
        let largeClusterThreshold = 50
        
        // 如果是大型聚合点，放大一级地图并重新聚合
        if cluster.count >= largeClusterThreshold {
            Logger.debug("Large cluster detected, zooming in one level")
            
            // 计算包含所有建筑的区域
            let coordinates = cluster.buildings.map { $0.coordinate }
            let minLat = coordinates.map { $0.latitude }.min() ?? cluster.centerCoordinate.latitude
            let maxLat = coordinates.map { $0.latitude }.max() ?? cluster.centerCoordinate.latitude
            let minLon = coordinates.map { $0.longitude }.min() ?? cluster.centerCoordinate.longitude
            let maxLon = coordinates.map { $0.longitude }.max() ?? cluster.centerCoordinate.longitude
            
            // 计算中心点
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            
            // 计算范围
            let latRange = maxLat - minLat
            let lonRange = maxLon - minLon
            
            // 添加边距确保所有点都能看到，且与屏幕边缘保持距离
            let minFixedPadding = 0.001  // 最小固定边距（约100米）
            let latPadding = max(latRange * 0.5, minFixedPadding)
            let lonPadding = max(lonRange * 0.5, minFixedPadding)
            
            // 计算span，确保包含所有建筑
            let newLatDelta = latRange + latPadding
            let newLonDelta = lonRange + lonPadding
            
            Logger.debug("Large cluster range: lat=\(String(format: "%.6f", latRange)), lon=\(String(format: "%.6f", lonRange))")
            Logger.debug("Final span: lat=\(String(format: "%.6f", newLatDelta)), lon=\(String(format: "%.6f", newLonDelta))")
            
            // 使用平滑spring动画放大（0.4秒）
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                currentRegion = MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: newLatDelta, longitudeDelta: newLonDelta)
                )
                cameraPosition = .region(currentRegion)
                
                // 使用新的缩放级别重新聚合所有建筑
                currentZoomLevel = currentRegion.span.latitudeDelta
                Logger.debug("Large cluster contains \(cluster.buildings.count) buildings, zooming to level \(String(format: "%.6f", currentZoomLevel))")
                
                // 关键：使用一个更小的"虚拟缩放级别"来强制展开
                // 即使实际span可能很大（为了包含所有建筑），但聚合时按更小的级别计算
                let effectiveZoomLevel = min(currentZoomLevel, 0.03)  // 强制使用至少0.03的缩放级别，对应聚合距离0.005
                Logger.debug("Using effective zoom level \(String(format: "%.6f", effectiveZoomLevel)) for clustering (actual: \(String(format: "%.6f", currentZoomLevel)))")
                
                buildingClusters = BuildingClusteringManager.shared.clusterBuildings(
                    treasures,  // 使用所有建筑，这样地图上其他区域的建筑也能显示
                    zoomLevel: effectiveZoomLevel,  // 使用更小的虚拟级别
                    forceExpand: false  // 正常聚合
                )
                
                Logger.info("After clustering: \(buildingClusters.count) groups total")
            }
            
            Logger.success("Large cluster expanded: \(cluster.count) buildings → \(buildingClusters.count) groups")
        } else {
            // 小型聚合点，展开所有点
            Logger.debug("Small cluster, expanding all points")
            
            // 计算包含所有建筑的区域
            let coordinates = cluster.buildings.map { $0.coordinate }
            let minLat = coordinates.map { $0.latitude }.min() ?? cluster.centerCoordinate.latitude
            let maxLat = coordinates.map { $0.latitude }.max() ?? cluster.centerCoordinate.latitude
            let minLon = coordinates.map { $0.longitude }.min() ?? cluster.centerCoordinate.longitude
            let maxLon = coordinates.map { $0.longitude }.max() ?? cluster.centerCoordinate.longitude
            
            // 计算范围
            let latRange = maxLat - minLat
            let lonRange = maxLon - minLon
            
            // 添加边距确保所有点都可见且不紧贴边缘
            // 如果建筑分布范围很小，使用固定边距；否则使用比例边距
            let minFixedPadding = 0.0005  // 最小固定边距（约50米）
            let latPadding = max(latRange * 0.6, minFixedPadding)  // 60%边距或最小固定边距
            let lonPadding = max(lonRange * 0.6, minFixedPadding)
            
            // 计算最终span，确保包含所有建筑
            let latDelta = latRange + latPadding
            let lonDelta = lonRange + lonPadding
            
            Logger.debug("Small cluster range: lat=\(String(format: "%.6f", latRange)), lon=\(String(format: "%.6f", lonRange))")
            Logger.debug("Final span: lat=\(String(format: "%.6f", latDelta)), lon=\(String(format: "%.6f", lonDelta))")
            
            // 创建新区域，确保能完整显示所有点
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            let newRegion = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            )
            
            // 使用平滑spring动画同时进行居中和展开（0.4秒）
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                // 更新地图区域（居中并缩放）
                currentRegion = newRegion
                cameraPosition = .region(newRegion)
                
                // 同时更新聚合（展开点）
                currentZoomLevel = newRegion.span.latitudeDelta
                buildingClusters = BuildingClusteringManager.shared.clusterBuildings(
                    treasures,
                    zoomLevel: currentZoomLevel,
                    forceExpand: true  // 强制展开，使用极小聚合距离
                )
            }
            
            Logger.info("Expanded to \(buildingClusters.count) groups (zoom: \(String(format: "%.4f", currentZoomLevel)))")
        }
    }

    private func formatCoordinate(_ coord: CLLocationCoordinate2D) -> String {
        String(format: "%.6f, %.6f", coord.latitude, coord.longitude)
    }

    private func startHunt(to destination: CLLocationCoordinate2D) {
        // 尝试使用用户当前位置；若无权限或未知，则用当前地图中心作为起点
        let start = getUserCoordinate() ?? currentRegion.center
        calculateRoute(from: start, to: destination)
    }

    private func getUserCoordinate() -> CLLocationCoordinate2D? {
        // 返回用户当前位置，如果位置管理器有位置信息的话
        if let userLocation = locationManager.location {
            Logger.location("getUserCoordinate: Using user location: \(userLocation.coordinate)")
            return userLocation.coordinate
        } else {
            Logger.location("getUserCoordinate: No user location available, using map center")
            return currentRegion.center
        }
    }

    private func calculateRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        // 计算直线距离
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let straightLineDistance = fromLocation.distance(from: toLocation)
        
        Logger.location("Calculating route - straight line distance: \(String(format: "%.2f", straightLineDistance))m")
        
        // 如果距离小于100米，不显示路径
        if straightLineDistance < 100.0 {
            Logger.info("🚶 Distance < 100m, skipping route calculation (too close)")
            self.routePolyline = nil
            self.routeDistanceMeters = nil
            self.isRouting = false
            return
        }
        
        let request = MKDirections.Request()
        request.transportType = .walking
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        isRouting = true
        MKDirections(request: request).calculate { response, _ in
            guard let route = response?.routes.first else { return }
            self.routePolyline = route.polyline
            self.routeDistanceMeters = route.distance
            
            // 总是自动缩放以完整包含：用户蓝点 + 选中宝藏 + 路径
            var fitRect = route.polyline.boundingMapRect
            
            // 计算边距
            // 左右边距：20%
            let dx = fitRect.size.width * 0.3
            // 顶部边距：20%
            let topPadding = fitRect.size.height * 0.3
            // 底部边距：60%（更大，以避免被底部信息框遮挡）
            let bottomPadding = fitRect.size.height * 0.8
            
            // 应用不对称边距
            fitRect.origin.x -= dx
            fitRect.size.width += dx * 2
            fitRect.origin.y -= bottomPadding
            fitRect.size.height += topPadding + bottomPadding
            
            let region = MKCoordinateRegion(fitRect)
            self.currentRegion = region
            self.cameraPosition = .region(region)
            Logger.debug("Auto-zoom to fit user, treasure and route (with bottom padding for info panel)")
        }
    }

    private func randomClueDescription() -> String {
        let options = [
            "Follow the sound of birds and flowing water, you'll find it under the shade of trees.",
            "Walk 50 meters east from the fountain, look for a hidden corner near the stone steps.",
            "Near the bird watching area, close to the red guardrail on the path.",
            "Along the winding path, behind the bench at the second intersection.",
            "Next to a bamboo grove, where sunlight filters through the gaps.",
            "Opposite the sculpture by the pond, look down to discover the clue."
        ]
        return options.randomElement() ?? "Follow the map's guidance and explore forward!"
    }
    
    private func generateClueForTreasure(at coordinate: CLLocationCoordinate2D) -> String {
        // 基于坐标生成更具体的线索
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        // 根据坐标范围生成不同的线索
        if lat > 22.278 {
            return "📍 HIGH AREA: You're looking for a treasure in the elevated section of the park. Look for a spot with a panoramic view of the surrounding area. The treasure might be near a lookout point or high ground."
        } else if lat < 22.276 {
            return "🌊 WATER AREA: This treasure is located in the lower section near water features. Listen for the sound of flowing water or fountains. Check around ponds, streams, or water displays."
        } else if lon > 114.1605 {
            return "🌸 EASTERN GARDEN: Head towards the eastern side of the park where the gardens are located. Look for colorful flowers, plants, and landscaped areas. The treasure might be hidden among the vegetation."
        } else if lon < 114.1595 {
            return "🚶 WESTERN PATH: This treasure is on the western side near the main pathways. Check along the walking trails, near benches, or close to the main entrance areas."
        } else {
            return "🌳 CENTRAL PARK: You're in the heart of the park, surrounded by nature. Look for a peaceful spot away from the main paths, perhaps near trees, shrubs, or natural features."
        }
    }
    
    private func generateStreetViewImage(for coordinate: CLLocationCoordinate2D) {
        // Google Street View Static API URL
        let apiKey = "AIzaSyCJKnpovh922gt2outyvjO7LL8wNRZi30M"
        let size = "400x300" // Image size
        let fov = "90" // Field of view
        
        // 根据坐标位置确定最佳视角
        let heading = getOptimalHeading(for: coordinate)
        let pitch = getOptimalPitch(for: coordinate)
        
        let urlString = "https://maps.googleapis.com/maps/api/streetview?size=\(size)&location=\(coordinate.latitude),\(coordinate.longitude)&fov=\(fov)&heading=\(heading)&pitch=\(pitch)&key=\(apiKey)"
        
        if let url = URL(string: urlString) {
            clueImageURL = url
        } else {
            // Fallback to a default image if URL creation fails
            clueImageURL = URL(string: "https://maps.gstatic.com/tactile/omnibox/streetview.png")
        }
    }
    
    private func getOptimalHeading(for coordinate: CLLocationCoordinate2D) -> Int {
        // 根据坐标位置确定最佳朝向
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        // 根据位置特征确定朝向
        if lat > 22.278 {
            // 高地区域 - 朝向公园中心
            return 180
        } else if lat < 22.276 {
            // 低地区域 - 朝向水景
            return 45
        } else if lon > 114.1605 {
            // 东侧区域 - 朝向花园
            return 270
        } else if lon < 114.1595 {
            // 西侧区域 - 朝向步道
            return 90
        } else {
            // 中央区域 - 随机朝向
            return Int.random(in: 0...360)
        }
    }
    
    private func getOptimalPitch(for coordinate: CLLocationCoordinate2D) -> Int {
        // 根据坐标位置确定最佳俯仰角
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        // 根据位置特征确定俯仰角
        if lat > 22.278 {
            // 高地区域 - 稍微向下看
            return -5
        } else if lat < 22.276 {
            // 低地区域 - 平视
            return 0
        } else if lon > 114.1605 {
            // 东侧区域 - 稍微向上看
            return 5
        } else if lon < 114.1595 {
            // 西侧区域 - 平视
            return 0
        } else {
            // 中央区域 - 轻微变化
            return Int.random(in: -5...5)
        }
    }
    
    // Oval Office 平面图视图
    private var ovalOfficeView: some View {
        ZStack(alignment: .topLeading) {
            // 白色背景
            Color.white
                .ignoresSafeArea()
            
            // 地图层
            ovalOfficeMapLayer
            
            // 显示已注册的资产标记和处理点击事件
            GeometryReader { geometry in
                ZStack {
                    // 透明的点击处理层 - 只处理地图拖拽和注册
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            // 拖拽移动地图
                            DragGesture(minimumDistance: 20)
                                .onChanged { value in
                                    // 只有在非注册模式下才允许拖拽
                                    if !ovalOfficeVM.isRegisteringAsset {
                                        ovalOfficeVM.ovalOfficeOffset = CGSize(
                                            width: ovalOfficeVM.ovalOfficeDragStartOffset.width + value.translation.width,
                                            height: ovalOfficeVM.ovalOfficeDragStartOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { value in
                                    // 保存拖拽结束时的偏移量
                                    ovalOfficeVM.ovalOfficeDragStartOffset = ovalOfficeVM.ovalOfficeOffset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                ovalOfficeVM.ovalOfficeScale = ovalOfficeVM.ovalOfficeScale == 1.0 ? 2.0 : 1.0
                                ovalOfficeVM.ovalOfficeOffset = .zero
                                ovalOfficeVM.ovalOfficeDragStartOffset = .zero
                            }
                        }
                    
                    // 注册模式下的点击处理层
                    if ovalOfficeVM.isRegisteringAsset {
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        // 获取点击位置
                                        let clickPoint = CGPoint(
                                            x: value.location.x,
                                            y: value.location.y
                                        )
                                        
                                        // 将屏幕坐标转换为网格坐标，使用相同的视图尺寸
                                        if let gridCoord = screenToGridCoordinate(clickPoint, viewSize: geometry.size) {
                                            // 添加资产位置（使用网格坐标和NFC UUID）
                                            var newAsset = AssetInfo(
                                                coordinate: gridCoord,
                                                nfcUUID: nfcManager.assetUUID
                                            )
                                            
                                            // 自动获取GPS坐标
                                            if let location = locationManager.location {
                                                newAsset.latitude = location.coordinate.latitude
                                                newAsset.longitude = location.coordinate.longitude
                                                Logger.location("GPS坐标已获取: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                                            } else {
                                                Logger.warning("GPS坐标未获取，请求定位...")
                                                locationManager.requestLocation()
                                            }
                                            
                                            ovalOfficeVM.officeAssets.append(newAsset)
                                            Logger.success("Asset registered at grid coordinate: (\(gridCoord.x), \(gridCoord.y)) with NFC UUID: \(nfcManager.assetUUID)")
                                            
                                            // 设置新添加的资产为选中状态，准备输入信息
                                            ovalOfficeVM.selectedAssetIndex = ovalOfficeVM.officeAssets.count - 1
                                            ovalOfficeVM.assetName = ""
                                            ovalOfficeVM.assetImage = nil
                                            ovalOfficeVM.assetDescription = ""
                                            ovalOfficeVM.isNewAsset = true
                                            
                                            // 退出注册模式并显示输入框
                                            ovalOfficeVM.isRegisteringAsset = false
                                            ovalOfficeVM.showAssetInputModal = true
                                        } else {
                                            // 点击位置不在PNG图片范围内，忽略注册动作
                                            Logger.debug("Click outside image bounds - asset registration ignored")
                                        }
                                    }
                            )
                    }
                    
                    // 显示资产标记 - 使用更大的点击区域和简单的手势
                    ForEach(Array(ovalOfficeVM.officeAssets.enumerated()), id: \.offset) { index, asset in
                        let screenPoint = gridToScreenCoordinate(asset.coordinate, viewSize: geometry.size)
                        
                        VStack(spacing: 2) {
                            // 资产标记
                            RoundedRectangle(cornerRadius: 1)
                                .fill(appGreen)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 1)
                                        .stroke(Color.white, lineWidth: 0.5)
                                )
                                .shadow(color: Color.gray.opacity(0.3), radius: 1, x: 0, y: 1)
                            
                            // 资产名称文字
                            Text(asset.name.isEmpty ? "INPUT" : asset.name)
                                .font(.caption2)
                                .foregroundColor(.black)
                                .padding(2)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(3)
                                .shadow(color: Color.gray.opacity(0.3), radius: 1, x: 0, y: 1)
                        }
                        .frame(width: 50, height: 50) // 设置固定的点击区域大小
                        .contentShape(Rectangle()) // 确保整个区域都可以点击
                        .onTapGesture {
                            if asset.name.isEmpty {
                                // 如果资产未注册，显示输入框
                                ovalOfficeVM.selectedAssetIndex = index
                                ovalOfficeVM.assetName = asset.name
                                ovalOfficeVM.assetImage = asset.image
                                ovalOfficeVM.assetDescription = asset.description
                                ovalOfficeVM.isNewAsset = false
                                ovalOfficeVM.showAssetInputModal = true
                            } else {
                                // 如果资产已注册，显示用户互动记录
                                ovalOfficeVM.selectedAssetInfo = asset
                                ovalOfficeVM.showAssetInfoModal = true
                            }
                        }
                        .position(screenPoint)
                    }
                }
            }
            
            // 左上角返回按钮 - 返回到Hong Kong地图
            Button(action: {
                Logger.debug("🔙 从 Oval Office 返回主地图")
                
                // 关闭 Oval Office
                ovalOfficeVM.showOvalOffice = false
                
                // 清除导航相关状态，避免显示导航界面
                showNavigation = false
                selectedTreasure = nil
                showOvalOfficeHistory = false
                routePolyline = nil
                routeDistanceMeters = nil
                isRouting = false
                
                // 打开主地图
                showMap = true
                
                Logger.success("✅ 已返回主地图，状态已清除")
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.9), in: Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 8)
            .padding(.leading, 8)
            
            // 右下角缩放按钮 - 与treasure map完全一致
            VStack(spacing: 10) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        ovalOfficeVM.ovalOfficeScale = min(ovalOfficeVM.ovalOfficeScale * 1.5, 4.0)
                    }
                }) {
                    ZStack {
                        Circle().fill(Color.white)
                        Text("+")
                            .font(.headline)
                            .foregroundStyle(.black)
                    }
                    .frame(width: 36, height: 36)
                    .shadow(radius: 1)
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        ovalOfficeVM.ovalOfficeScale = max(ovalOfficeVM.ovalOfficeScale / 1.5, 0.5)
                    }
                }) {
                    ZStack {
                        Circle().fill(Color.white)
                        Text("-")
                            .font(.headline)
                            .foregroundStyle(.black)
                    }
                    .frame(width: 36, height: 36)
                    .shadow(radius: 1)
                }
            }
            .padding(.trailing, 12)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            
            // 底部Register Asset按钮 - 向右居中显示
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // 点击按钮启动第一次NFC扫描
                        nfcManager.startFirstScan()
                    }) {
                        Text("TAP your Asset's NFC to Register")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(appGreen)
                            .frame(width: 240, height: 35)
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
                    }
                    .disabled(nfcManager.currentPhase == .firstScan || nfcManager.currentPhase == .secondScan)
                    Spacer()
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $ovalOfficeVM.showAssetInputModal) {
            AssetInputModal(
                assetName: $ovalOfficeVM.assetName,
                assetImage: $ovalOfficeVM.assetImage,
                assetDescription: $ovalOfficeVM.assetDescription,
                appGreen: appGreen,
                nfcManager: nfcManager,
                onCancel: {
                    // 根据资产是否为新注册来决定关闭行为
                    if ovalOfficeVM.isNewAsset {
                        // 如果是新注册的资产，删除它
                        if let index = ovalOfficeVM.selectedAssetIndex {
                            ovalOfficeVM.officeAssets.remove(at: index)
                        }
                    }
                    // 如果是已存在的资产，保持原有信息不变
                    ovalOfficeVM.showAssetInputModal = false
                    // 重置NFC管理器和注册状态
                    nfcManager.reset()
                    ovalOfficeVM.isRegisteringAsset = false
                }
            )
        }
        .overlay(
            // 资产信息框
            ovalOfficeVM.showAssetInfoModal ? AssetInfoModalView(
                viewModel: ovalOfficeVM,
                currentInteractionIndex: $currentInteractionIndex,
                selectedUserInteraction: $selectedUserInteraction,
                showUserDetailModal: $showUserDetailModal,
                nfcManager: nfcManager,
                appGreen: appGreen,
                username: username
            ) : nil
        )
        .overlay(
            // 用户详细信息框
            showUserDetailModal ? UserDetailModalView(
                viewModel: ovalOfficeVM,
                showUserDetailModal: $showUserDetailModal,
                currentInteractionIndex: $currentInteractionIndex,
                selectedUserInteraction: $selectedUserInteraction,
                appGreen: appGreen
            ) : nil
        )
        .overlay(
            // NFC已注册提示弹窗
            showNFCAlreadyRegisteredAlert ? nfcAlreadyRegisteredAlert : nil
        )
        .onAppear {
            // 从磁盘加载保存的Asset
            loadAssetsFromDisk()
            
            // 进入Oval Office页面时，设置NFC回调
            nfcManager.onNFCDetected = {
                DispatchQueue.main.async {
                    // 根据NFC扫描阶段执行不同的操作
                    switch self.nfcManager.currentPhase {
                    case .awaitingInput:
                        // 第一次NFC扫描完成，启用地图点击注册模式
                        self.ovalOfficeVM.isRegisteringAsset = true
                    case .completed:
                        // 第二次NFC扫描完成，保存资产信息
                        if let index = self.ovalOfficeVM.selectedAssetIndex {
                            // 更新Asset信息
                            self.ovalOfficeVM.officeAssets[index].name = self.ovalOfficeVM.assetName
                            self.ovalOfficeVM.officeAssets[index].image = self.ovalOfficeVM.assetImage
                            self.ovalOfficeVM.officeAssets[index].description = self.ovalOfficeVM.assetDescription
                            
                            // 保存到磁盘
                            self.quickSaveAsset(self.ovalOfficeVM.officeAssets[index])
                            
                            // 创建初始历史记录（保存到云端）
                            let displayUsername = self.username.isEmpty ? "Guest" : self.username
                            let asset = self.ovalOfficeVM.officeAssets[index]
                            let assetId = "asset_\(asset.coordinate.x)_\(asset.coordinate.y)"
                            
                            Task {
                                do {
                                    let _ = try await OvalOfficeCheckInManager.shared.saveCheckIn(
                                        assetId: assetId,
                                        gridX: asset.coordinate.x,
                                        gridY: asset.coordinate.y,
                                        username: displayUsername,
                                        assetName: self.ovalOfficeVM.assetName,
                                        description: self.ovalOfficeVM.assetDescription,
                                        image: self.ovalOfficeVM.assetImage,
                                        nfcUuid: asset.nfcUUID,
                                        latitude: asset.latitude,
                                        longitude: asset.longitude
                                    )
                                    Logger.success("✅ Initial check-in saved to cloud")
                                } catch {
                                    Logger.error("❌ Failed to save initial check-in: \(error.localizedDescription)")
                                }
                            }
                        }
                        // 关闭输入框
                        self.ovalOfficeVM.showAssetInputModal = false
                        // 重置NFC管理器和注册状态
                        self.nfcManager.reset()
                        self.ovalOfficeVM.isRegisteringAsset = false
                    case .checkInInput:
                        // Check-in第一次NFC验证成功，显示输入框让用户添加描述
                        Logger.success("Check-in first NFC verified, showing input modal")
                        
                        // 预填充当前Asset的名称（允许用户修改）
                        if let index = self.ovalOfficeVM.selectedAssetIndex {
                            self.ovalOfficeVM.assetName = self.ovalOfficeVM.officeAssets[index].name
                            Logger.debug("Pre-filled Asset name: \(self.ovalOfficeVM.assetName)")
                        }
                        
                        // 清空照片和描述（用于新的check-in记录）
                        self.ovalOfficeVM.assetImage = nil
                        self.ovalOfficeVM.assetDescription = ""
                        self.ovalOfficeVM.isNewAsset = false
                        
                        // 显示输入框
                        self.ovalOfficeVM.showAssetInputModal = true
                    case .checkInCompleted:
                        // Check-in第二次NFC验证成功，保存check-in数据
                        Logger.success("Check-in second NFC verified, saving data...")
                        
                        // 保存check-in数据并更新Asset信息
                        if let index = self.ovalOfficeVM.selectedAssetIndex {
                            Logger.database("Check-in for Asset at index \(index)")
                            
                            // 保存当前的Asset名称（用于历史记录）
                            let currentAssetName = self.ovalOfficeVM.assetName
                            let displayUsername = self.username.isEmpty ? "Guest" : self.username
                            
                            // 如果用户输入了新的Asset名称，更新地图上的Asset名称
                            if !self.ovalOfficeVM.assetName.isEmpty {
                                self.ovalOfficeVM.officeAssets[index].name = self.ovalOfficeVM.assetName
                                Logger.success("Asset name updated to: \(self.ovalOfficeVM.assetName)")
                            }
                            
                            // 更新GPS坐标（每次check-in时更新当前位置）
                            var currentLatitude: Double? = self.ovalOfficeVM.officeAssets[index].latitude
                            var currentLongitude: Double? = self.ovalOfficeVM.officeAssets[index].longitude
                            
                            if let location = self.locationManager.location {
                                self.ovalOfficeVM.officeAssets[index].latitude = location.coordinate.latitude
                                self.ovalOfficeVM.officeAssets[index].longitude = location.coordinate.longitude
                                currentLatitude = location.coordinate.latitude
                                currentLongitude = location.coordinate.longitude
                                Logger.location("GPS坐标已更新: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                            } else {
                                Logger.warning("Unable to get current GPS location")
                            }
                            
                            // 保存到磁盘
                            self.quickSaveAsset(self.ovalOfficeVM.officeAssets[index])
                            
                            // 保存 Check-in 到云端
                            let asset = self.ovalOfficeVM.officeAssets[index]
                            let assetId = "asset_\(asset.coordinate.x)_\(asset.coordinate.y)"
                            
                            Task {
                                do {
                                    let _ = try await OvalOfficeCheckInManager.shared.saveCheckIn(
                                        assetId: assetId,
                                        gridX: asset.coordinate.x,
                                        gridY: asset.coordinate.y,
                                        username: displayUsername,
                                        assetName: currentAssetName,
                                        description: self.ovalOfficeVM.assetDescription,
                                        image: self.ovalOfficeVM.assetImage,
                                        nfcUuid: asset.nfcUUID,
                                        latitude: currentLatitude,
                                        longitude: currentLongitude
                                    )
                                    Logger.success("✅ Check-in saved to cloud")
                                    Logger.debug("   - Username: \(displayUsername)")
                                    Logger.debug("   - Asset Name: \(currentAssetName)")
                                    Logger.debug("   - Description: \(self.ovalOfficeVM.assetDescription)")
                                    Logger.debug("   - Has Image: \(self.ovalOfficeVM.assetImage != nil)")
                                } catch {
                                    Logger.error("❌ Failed to save check-in: \(error.localizedDescription)")
                                }
                            }
                        }
                        
                        // 关闭输入框
                        self.ovalOfficeVM.showAssetInputModal = false
                        // 重置NFC管理器
                        self.nfcManager.reset()
                        
                        Logger.success("Check-in completed successfully!")
                    default:
                        break
                    }
                }
            }
            
            // 设置NFC已注册回调
            nfcManager.onNFCAlreadyRegistered = { assetInfo in
                DispatchQueue.main.async {
                    Logger.warning("NFC已被注册，显示提示")
                    self.alreadyRegisteredNFCUUID = self.nfcManager.assetUUID
                    
                    // 查找该NFC对应的Asset
                    if let existingAsset = self.ovalOfficeVM.officeAssets.first(where: { $0.nfcUUID == self.nfcManager.assetUUID }) {
                        self.ovalOfficeVM.selectedAssetInfo = existingAsset
                    }
                    
                    // 显示提示弹窗
                    self.showNFCAlreadyRegisteredAlert = true
                    
                    // 重置注册状态
                    self.ovalOfficeVM.isRegisteringAsset = false
                }
            }
        }
        .onDisappear {
            // 离开Oval Office页面时，重置NFC状态和注册状态
            nfcManager.reset()
            nfcManager.onNFCDetected = nil
            nfcManager.onNFCAlreadyRegistered = nil
            ovalOfficeVM.isRegisteringAsset = false
        }
    }
    
    // 地图图层
    private var ovalOfficeMapLayer: some View {
        GeometryReader { geometry in
            Image("OvalOfficePlan")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(ovalOfficeVM.ovalOfficeScale)
                .offset(ovalOfficeVM.ovalOfficeOffset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    GridOverlayView(scale: ovalOfficeVM.ovalOfficeScale, offset: ovalOfficeVM.ovalOfficeOffset)
                )
        }
    }
    
    // AssetInfoModalView, UserInteractionRow, UserDetailModalView 已移到 Views/OvalOffice/AssetInfoModalView.swift
    
    // NFC已注册提示弹窗
    private var nfcAlreadyRegisteredAlert: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // 提示框
            VStack(spacing: 20) {
                // 图标
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(appGreen)
                    .padding(.top, 20)
                
                // 标题
                Text("NFC Already Registered")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // 说明文字
                VStack(spacing: 12) {
                    Text("This NFC tag has already been registered")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if !alreadyRegisteredNFCUUID.isEmpty {
                        Text("UUID: \(alreadyRegisteredNFCUUID)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                
                Divider()
                    .padding(.horizontal, 20)
                
                // 按钮组
                VStack(spacing: 12) {
                    // 查看Asset History按钮
                    Button(action: {
                        showNFCAlreadyRegisteredAlert = false
                        
                        // 查找该NFC对应的Asset
                        if let asset = ovalOfficeVM.officeAssets.first(where: { $0.nfcUUID == alreadyRegisteredNFCUUID }) {
                            ovalOfficeVM.selectedAssetInfo = asset
                            ovalOfficeVM.showAssetInfoModal = true
                        } else {
                            Logger.warning("未找到对应的Asset")
                        }
                        
                        // 重置NFC管理器
                        nfcManager.reset()
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("View Asset History")
                        }
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(appGreen)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background {
                            ZStack {
                                Color.clear.background(.ultraThinMaterial)
                                appGreen.opacity(0.1)
                            }
                        }
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(appGreen.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // 取消按钮
                    Button(action: {
                        showNFCAlreadyRegisteredAlert = false
                        nfcManager.reset()
                        ovalOfficeVM.isRegisteringAsset = false
                    }) {
                        Text("Cancel")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(width: 320)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }
    
    // 我的历史记录全屏视图
    private var myHistoryFullScreenView: some View {
        MyHistoryFullScreenView(
            username: username,
            appGreen: appGreen,
            onClose: {
                Logger.debug("MyHistory close button tapped")
                showMyHistory = false
                // 关闭历史记录后重新打开地图
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showMap = true
                }
            },
            onNavigateToBuilding: { latitude, longitude in
                Logger.debug("📍 导航到GPS坐标: (\(latitude), \(longitude))")
                
                // 根据GPS坐标查找最近的建筑
                if let building = findNearestBuilding(latitude: latitude, longitude: longitude) {
                    Logger.success("✅ 找到建筑: \(building.name)")
                    
                    // 关闭历史记录界面
                    showMyHistory = false
                    
                    // 延迟打开地图并启动导航
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedTreasure = building
                        showMap = true
                        showNavigation = true
                    }
                } else {
                    Logger.warning("⚠️ 未找到对应的建筑")
                }
            },
            onNavigateToOvalOffice: {
                Logger.debug("📍 导航到Oval Office（从My Assets）")
                
                // 关闭历史记录界面
                showMyHistory = false
                
                // 延迟打开Oval Office
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    ovalOfficeVM.showOvalOffice = true
                }
            },
            treasures: treasures,
            nfcManager: nfcManager
        )
        .onAppear {
            Logger.debug("✅ MyHistoryFullScreenView appeared!")
        }
    }
    
    // MARK: - Body
    var body: some View {
        contentWithModifiers
            .fullScreenCover(isPresented: $ovalOfficeVM.showOvalOffice) {
                ovalOfficeView
            }
            .fullScreenCover(isPresented: $showMap) {
                fullScreenMapView
            }
            .fullScreenCover(isPresented: $showMyHistory) {
                myHistoryFullScreenView
            }
            .fullScreenCover(isPresented: $showMarket) {
                MarketView(
                    appGreen: appGreen,
                    treasures: treasures,
                    onClose: {
                        showMarket = false
                        showMap = true
                    },
                    onNavigateToBuilding: { buildingId in
                        // 关闭Market，打开地图并定位到建筑
                        showMarket = false
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showMap = true
                            
                            // 查找并选中建筑
                            if let building = treasures.first(where: { $0.id == buildingId }) {
                                selectedTreasure = building
                                
                                // 放大到建筑位置
                                let region = MKCoordinateRegion(
                                    center: building.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentRegion = region
                                    cameraPosition = .region(region)
                                }
                            }
                        }
                    },
                    currentUsername: username,
                    onBidCountUpdate: { count in
                        unreadBidCount = count
                    }
                )
            }
    }
}

// AssetInputModal 已移到 Views/OvalOffice/AssetInputModalView.swift

// 图片选择器组件
// 交通方式选择视图
// 辅助扩展
extension MKDirectionsTransportType {
    var appleMapsDirectionMode: String {
        switch self {
        case .automobile:
            return MKLaunchOptionsDirectionsModeDriving
        case .walking:
            return MKLaunchOptionsDirectionsModeWalking
        case .transit:
            return MKLaunchOptionsDirectionsModeTransit
        default:
            return MKLaunchOptionsDirectionsModeDefault
        }
    }
    
    var description: String {
        switch self {
        case .automobile:
            return "Driving"
        case .walking:
            return "Walking"
        case .transit:
            return "Transit"
        default:
            return "Default"
        }
    }
}

// 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Apple Sign In Coordinator
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let onSuccess: (ASAuthorization) -> Void
    private let onError: (Error) -> Void
    
    init(onSuccess: @escaping (ASAuthorization) -> Void, onError: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onError = onError
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onSuccess(authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onError(error)
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

