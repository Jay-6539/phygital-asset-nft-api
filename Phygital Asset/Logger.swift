//
//  Logger.swift
//  Phygital Asset
//
//  统一日志管理系统 - 仅在 Debug 模式下输出日志
//

import Foundation

/// 日志级别
enum LogLevel: String {
    case debug = "🔍 DEBUG"
    case info = "ℹ️ INFO"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
    case success = "✅ SUCCESS"
}

/// 统一日志管理器
struct Logger {
    
    /// 输出日志（仅在 Debug 模式）
    /// - Parameters:
    ///   - message: 日志消息
    ///   - level: 日志级别
    ///   - file: 文件名（自动填充）
    ///   - line: 行号（自动填充）
    ///   - function: 函数名（自动填充）
    static func log(
        _ message: String,
        level: LogLevel = .debug,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] [\(level.rawValue)] [\(filename):\(line)] \(message)")
        #endif
    }
    
    /// 便捷方法：Debug 日志
    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .debug, file: file, line: line)
    }
    
    /// 便捷方法：Info 日志
    static func info(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .info, file: file, line: line)
    }
    
    /// 便捷方法：Warning 日志
    static func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .warning, file: file, line: line)
    }
    
    /// 便捷方法：Error 日志
    static func error(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .error, file: file, line: line)
    }
    
    /// 便捷方法：Success 日志
    static func success(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .success, file: file, line: line)
    }
    
    /// 日期格式化器
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - 特定功能模块的 Logger 扩展

extension Logger {
    /// 网络请求日志
    static func network(_ message: String, file: String = #file, line: Int = #line) {
        log("🌐 \(message)", level: .info, file: file, line: line)
    }
    
    /// 数据库操作日志
    static func database(_ message: String, file: String = #file, line: Int = #line) {
        log("💾 \(message)", level: .info, file: file, line: line)
    }
    
    /// UI 事件日志
    static func ui(_ message: String, file: String = #file, line: Int = #line) {
        log("🖥️ \(message)", level: .debug, file: file, line: line)
    }
    
    /// 位置服务日志
    static func location(_ message: String, file: String = #file, line: Int = #line) {
        log("📍 \(message)", level: .info, file: file, line: line)
    }
    
    /// NFC 日志
    static func nfc(_ message: String, file: String = #file, line: Int = #line) {
        log("📱 \(message)", level: .info, file: file, line: line)
    }
    
    /// 认证日志
    static func auth(_ message: String, file: String = #file, line: Int = #line) {
        log("🔐 \(message)", level: .info, file: file, line: line)
    }
}

