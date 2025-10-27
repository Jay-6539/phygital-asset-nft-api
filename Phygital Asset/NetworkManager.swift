//
//  NetworkManager.swift
//  Phygital Asset
//
//  统一网络请求管理器 - 支持重试、超时、取消
//

import Foundation

// MARK: - 网络错误类型
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, Data?)
    case timeout
    case cancelled
    case noData
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code, _):
            return "HTTP Error: \(code)"
        case .timeout:
            return "Request timeout"
        case .cancelled:
            return "Request cancelled"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - 网络管理器
class NetworkManager {
    static let shared = NetworkManager()
    
    private var activeTasks: [String: URLSessionTask] = [:]
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    /// 发起网络请求（支持重试、超时、取消）
    /// - Parameters:
    ///   - url: 请求URL
    ///   - method: HTTP方法（GET/POST/DELETE等）
    ///   - headers: HTTP头部
    ///   - body: 请求体数据
    ///   - timeout: 超时时间（秒）
    ///   - retries: 重试次数
    ///   - taskId: 任务ID，用于取消（可选）
    /// - Returns: 响应数据
    func request(
        url: URL,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval = 30,
        retries: Int = 3,
        taskId: String? = nil
    ) async throws -> Data {
        var lastError: Error?
        
        for attempt in 0...retries {
            do {
                let data = try await performRequest(
                    url: url,
                    method: method,
                    headers: headers,
                    body: body,
                    timeout: timeout,
                    taskId: taskId
                )
                
                // 请求成功，返回数据
                if attempt > 0 {
                    Logger.network("Request succeeded after \(attempt) retries")
                }
                return data
                
            } catch NetworkError.cancelled {
                // 用户取消，不重试
                throw NetworkError.cancelled
                
            } catch {
                lastError = error
                
                if attempt < retries {
                    // 计算重试延迟（指数退避）
                    let delay = pow(2.0, Double(attempt)) * 0.5
                    Logger.warning("Request failed (attempt \(attempt + 1)/\(retries + 1)), retrying in \(delay)s...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    Logger.error("Request failed after \(retries + 1) attempts")
                }
            }
        }
        
        throw lastError ?? NetworkError.invalidResponse
    }
    
    /// 执行单次请求
    private func performRequest(
        url: URL,
        method: String,
        headers: [String: String],
        body: Data?,
        timeout: TimeInterval,
        taskId: String?
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout
        
        // 设置headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 设置body
        if let body = body {
            request.httpBody = body
        }
        
        // 创建任务
        let task = session.dataTask(with: request)
        
        // 保存任务以便取消
        if let taskId = taskId {
            activeTasks[taskId] = task
        }
        
        // 执行请求
        let (data, response) = try await session.data(for: request)
        
        // 移除已完成的任务
        if let taskId = taskId {
            activeTasks.removeValue(forKey: taskId)
        }
        
        // 验证响应
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // 检查HTTP状态码
        guard (200...299).contains(httpResponse.statusCode) else {
            Logger.error("HTTP Error \(httpResponse.statusCode): \(url.absoluteString)")
            throw NetworkError.httpError(httpResponse.statusCode, data)
        }
        
        return data
    }
    
    /// 取消指定请求
    func cancel(taskId: String) {
        if let task = activeTasks[taskId] {
            task.cancel()
            activeTasks.removeValue(forKey: taskId)
            Logger.debug("Cancelled task: \(taskId)")
        }
    }
    
    /// 取消所有请求
    func cancelAll() {
        activeTasks.forEach { $0.value.cancel() }
        activeTasks.removeAll()
        Logger.debug("Cancelled all \(activeTasks.count) active tasks")
    }
    
    /// 便捷方法：GET请求
    func get(
        url: URL,
        headers: [String: String] = [:],
        timeout: TimeInterval = 30,
        retries: Int = 3,
        taskId: String? = nil
    ) async throws -> Data {
        try await request(
            url: url,
            method: "GET",
            headers: headers,
            timeout: timeout,
            retries: retries,
            taskId: taskId
        )
    }
    
    /// 便捷方法：POST请求
    func post(
        url: URL,
        headers: [String: String] = [:],
        body: Data,
        timeout: TimeInterval = 30,
        retries: Int = 3,
        taskId: String? = nil
    ) async throws -> Data {
        try await request(
            url: url,
            method: "POST",
            headers: headers,
            body: body,
            timeout: timeout,
            retries: retries,
            taskId: taskId
        )
    }
    
    /// 便捷方法：DELETE请求
    func delete(
        url: URL,
        headers: [String: String] = [:],
        timeout: TimeInterval = 30,
        retries: Int = 1,  // DELETE通常不需要多次重试
        taskId: String? = nil
    ) async throws -> Data {
        try await request(
            url: url,
            method: "DELETE",
            headers: headers,
            timeout: timeout,
            retries: retries,
            taskId: taskId
        )
    }
}

