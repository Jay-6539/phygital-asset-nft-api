//
//  NFTManager.swift
//  Phygital Asset
//
//  托管NFT铸造和管理 - 用户无感的Web3集成
//

import Foundation

class NFTManager {
    static let shared = NFTManager()
    private init() {}
    
    // 生产环境API服务地址 - 连接到Vercel部署
    private let apiURL: String = {
        #if DEBUG
        // 开发环境：本地API服务
        return "http://127.0.0.1:3000/api"
        #else
        // 生产环境：Vercel云端API服务
        return "https://phygital-asset-nft-k0l8bbict-jay-6539s-projects.vercel.app/api"
        #endif
    }()
    
    // 备用API地址
    private let backupAPIURL = "http://localhost:3000/api"
    
    // 网络配置信息
    private let networkConfig: [String: Any] = [
        "chainId": 80002,
        "networkName": "Amoy Testnet",
        "explorerUrl": "https://amoy.polygonscan.com/",
        "currency": "MATIC",
        "contractAddress": "0xA0fA27fC547D544528e9BE0cb6569E9B925e533E"
    ]
    
    // 是否启用NFT功能（可在设置中控制）
    private var isNFTEnabled: Bool {
        UserDefaults.standard.bool(forKey: "nft_enabled")
    }
    
    // MARK: - Thread创建后自动铸造NFT
    /// 在后台自动为Thread铸造NFT，用户完全无感
    func mintNFTForThread(
        threadId: UUID,
        username: String,
        buildingId: String?,
        description: String,
        imageUrl: String?
    ) async {
        // 检查是否启用NFT
        guard isNFTEnabled else {
            Logger.debug("🔇 NFT功能未启用，跳过铸造")
            return
        }
        
        // 后台异步执行，不阻塞用户操作
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            do {
                Logger.debug("🎨 开始后台铸造NFT for Thread: \(threadId)")
                Logger.debug("🌐 API URL: \(self.apiURL)")
                
                // 跳过健康检查，直接尝试铸造（失败时自动使用备用服务）
                
                let result = try await self.callMintAPI(
                    threadId: threadId,
                    username: username,
                    buildingId: buildingId,
                    description: description,
                    imageUrl: imageUrl
                )
                
                if result.alreadyMinted ?? false {
                    Logger.debug("ℹ️ NFT已存在，Token ID: \(result.tokenId)")
                } else {
                    Logger.success("✅ NFT铸造成功!")
                    Logger.debug("   Token ID: \(result.tokenId)")
                    Logger.debug("   Tx Hash: \(result.transactionHash ?? "N/A")")
                    Logger.debug("   耗时: \(result.elapsed ?? 0)ms")
                }
                
                // 发送通知（应用内其他模块可监听）
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .nftMinted,
                        object: nil,
                        userInfo: [
                            "threadId": threadId,
                            "tokenId": result.tokenId
                        ]
                    )
                }
                
            } catch {
                // 静默失败，不影响用户体验
                Logger.debug("🔇 NFT铸造失败（后台），用户无感: \(error.localizedDescription)")
                
                // 如果是网络错误，尝试使用备用方案
                if let urlError = error as? URLError {
                    Logger.debug("🌐 网络错误类型: \(urlError.code.rawValue)")
                    if urlError.code == .cannotConnectToHost || urlError.code == .networkConnectionLost {
                        Logger.debug("🔄 尝试使用备用NFT服务...")
                        await self.tryBackupMintService(threadId: threadId, username: username, buildingId: buildingId, description: description, imageUrl: imageUrl)
                    }
                }
            }
        }
    }
    
    // MARK: - Bid完成后转移NFT
    /// 在后台自动转移NFT所有权
    func transferNFT(
        threadId: UUID,
        from fromUsername: String,
        to toUsername: String
    ) async {
        guard isNFTEnabled else { return }
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            do {
                Logger.debug("🔄 开始后台转移NFT: \(threadId)")
                Logger.debug("   \(fromUsername) → \(toUsername)")
                
                let result = try await self.callTransferAPI(
                    threadId: threadId,
                    from: fromUsername,
                    to: toUsername
                )
                
                Logger.success("✅ NFT转移成功（应用层）")
                Logger.debug("   Token ID: \(result.tokenId)")
                
            } catch {
                Logger.debug("🔇 NFT转移失败（后台），用户无感: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 查询NFT信息（用户可选查看）
    /// 获取Thread对应的NFT信息
    func getNFTInfo(for threadId: UUID) async -> NFTInfo? {
        guard isNFTEnabled else { return nil }
        
        do {
            let endpoint = "\(apiURL)/nft/\(threadId.uuidString)"
            guard let url = URL(string: endpoint) else { return nil }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let result = try JSONDecoder().decode(NFTQueryResult.self, from: data)
            
            if result.exists {
                return NFTInfo(
                    threadId: threadId,
                    tokenId: result.tokenId ?? "",
                    contractAddress: result.contractAddress ?? "",
                    buildingId: result.buildingId,
                    timestamp: result.timestamp
                )
            }
            
            return nil
            
        } catch {
            Logger.debug("查询NFT信息失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 健康检查
    /// 检查NFT服务是否可用
    func checkServiceHealth() async -> Bool {
        do {
            let endpoint = "\(apiURL)/health"
            guard let url = URL(string: endpoint) else { return false }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 3
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let result = try JSONDecoder().decode(HealthCheckResult.self, from: data)
            
            Logger.debug("🏥 NFT服务健康检查: \(result.status)")
            Logger.debug("   已铸造: \(result.totalMinted ?? "0") NFTs")
            
            return result.status == "ok"
            
        } catch {
            Logger.debug("🔇 NFT服务不可用（正常，不影响应用）")
            return false
        }
    }
    
    // MARK: - 备用NFT服务
    /// 当主服务不可用时，使用本地模拟铸造
    private func tryBackupMintService(
        threadId: UUID,
        username: String,
        buildingId: String?,
        description: String,
        imageUrl: String?
    ) async {
        Logger.debug("🔄 使用备用NFT服务（本地模拟）")
        
        // 模拟铸造过程
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒延迟
        
        let tokenId = "LOCAL-NFT-\(Int.random(in: 1000...9999))"
        let transactionHash = "0x\(String.random(length: 64))"
        
        Logger.success("✅ 备用NFT铸造成功!")
        Logger.debug("   Token ID: \(tokenId)")
        Logger.debug("   Tx Hash: \(transactionHash)")
        Logger.debug("   ⚠️ 注意：这是本地模拟NFT")
        
        // 发送通知
        await MainActor.run {
            NotificationCenter.default.post(
                name: .nftMinted,
                object: nil,
                userInfo: [
                    "threadId": threadId,
                    "tokenId": tokenId,
                    "isLocalSimulation": true
                ]
            )
        }
    }
    
    // MARK: - 启用/禁用NFT功能
    func setNFTEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "nft_enabled")
        Logger.debug("🎚️ NFT功能: \(enabled ? "启用" : "禁用")")
    }
    
    // MARK: - 私有方法：API调用
    private func callMintAPI(
        threadId: UUID,
        username: String,
        buildingId: String?,
        description: String,
        imageUrl: String?
    ) async throws -> MintResult {
        // 尝试主API地址
        do {
            return try await performMintRequest(
                baseURL: apiURL,
                threadId: threadId,
                username: username,
                buildingId: buildingId,
                description: description,
                imageUrl: imageUrl
            )
        } catch {
            Logger.debug("🔄 主API失败，尝试备用API: \(error.localizedDescription)")
            // 尝试备用API地址
            return try await performMintRequest(
                baseURL: backupAPIURL,
                threadId: threadId,
                username: username,
                buildingId: buildingId,
                description: description,
                imageUrl: imageUrl
            )
        }
    }
    
    private func performMintRequest(
        baseURL: String,
        threadId: UUID,
        username: String,
        buildingId: String?,
        description: String,
        imageUrl: String?
    ) async throws -> MintResult {
        let endpoint = "\(baseURL)/mint-thread"
        guard let url = URL(string: endpoint) else {
            throw NFTError.invalidURL
        }
        
        let body: [String: Any] = [
            "threadId": threadId.uuidString,
            "username": username,
            "buildingId": buildingId ?? "",
            "description": description,
            "imageUrl": imageUrl ?? ""
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NFTError.serverError
        }
        
        return try JSONDecoder().decode(MintResult.self, from: data)
    }
    
    private func callTransferAPI(
        threadId: UUID,
        from: String,
        to: String
    ) async throws -> NFTTransferResult {
        let endpoint = "\(apiURL)/transfer-nft"
        guard let url = URL(string: endpoint) else {
            throw NFTError.invalidURL
        }
        
        let body: [String: Any] = [
            "threadId": threadId.uuidString,
            "fromUsername": from,
            "toUsername": to
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NFTError.serverError
        }
        
        return try JSONDecoder().decode(NFTTransferResult.self, from: data)
    }
    
    // MARK: - 查询用户NFT
    /// 获取用户拥有的所有NFT
    func getUserNFTs(username: String) async -> [NFTInfo]? {
        guard isNFTEnabled else { return nil }
        
        do {
            let endpoint = "\(apiURL)/user-nfts/\(username)"
            guard let url = URL(string: endpoint) else { return nil }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let result = try JSONDecoder().decode(UserNFTsResult.self, from: data)
            
            return result.nfts.map { nft in
                NFTInfo(
                    threadId: UUID(uuidString: nft.threadId) ?? UUID(),
                    tokenId: nft.tokenId,
                    contractAddress: nft.contractAddress,
                    buildingId: nft.buildingId,
                    timestamp: nft.timestamp
                )
            }
            
        } catch {
            Logger.debug("查询用户NFT失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 查询NFT详情
    /// 获取特定NFT的详细信息
    func getNFTDetail(tokenId: String) async -> NFTDetail? {
        guard isNFTEnabled else { return nil }
        
        do {
            let endpoint = "\(apiURL)/nft/\(tokenId)"
            guard let url = URL(string: endpoint) else { return nil }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let result = try JSONDecoder().decode(NFTDetailResult.self, from: data)
            
            return NFTDetail(
                tokenId: result.nft.tokenId,
                threadId: result.nft.threadId,
                buildingId: result.nft.buildingId,
                timestamp: result.nft.timestamp,
                contractAddress: result.nft.contractAddress,
                owner: result.nft.owner,
                metadata: result.nft.metadata
            )
            
        } catch {
            Logger.debug("查询NFT详情失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 查询所有NFT
    /// 获取所有NFT列表（分页）
    func getAllNFTs(page: Int = 1, limit: Int = 20) async -> AllNFTsResult? {
        guard isNFTEnabled else { return nil }
        
        do {
            let endpoint = "\(apiURL)/all-nfts?page=\(page)&limit=\(limit)"
            guard let url = URL(string: endpoint) else { return nil }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let result = try JSONDecoder().decode(AllNFTsResult.self, from: data)
            return result
            
        } catch {
            Logger.debug("查询所有NFT失败: \(error)")
            return nil
        }
    }
}

// MARK: - 数据模型
struct MintResult: Codable {
    let success: Bool
    let tokenId: String
    let transactionHash: String?
    let gasUsed: String?
    let alreadyMinted: Bool?
    let contractAddress: String?
    let elapsed: Int?
}

struct NFTTransferResult: Codable {
    let success: Bool
    let tokenId: String
    let message: String?
}

struct NFTQueryResult: Codable {
    let exists: Bool
    let tokenId: String?
    let buildingId: String?
    let message: String?
    let timestamp: String?
    let contractAddress: String?
}

struct HealthCheckResult: Codable {
    let status: String
    let contractAddress: String?
    let totalMinted: String?
}

struct NFTInfo {
    let threadId: UUID
    let tokenId: String
    let contractAddress: String
    let buildingId: String?
    let timestamp: String?
    
    var polygonscanURL: URL? {
        // Amoy测试网Polygonscan链接
        URL(string: "https://amoy.polygonscan.com/token/\(contractAddress)?a=\(tokenId)")
    }
    
    var openseaURL: URL? {
        // OpenSea测试网链接
        URL(string: "https://testnets.opensea.io/assets/amoy/\(contractAddress)/\(tokenId)")
    }
}

// MARK: - 新增数据模型
struct UserNFTsResult: Codable {
    let success: Bool
    let username: String
    let nfts: [UserNFT]
    let totalCount: Int
}

struct UserNFT: Codable {
    let tokenId: String
    let threadId: String
    let buildingId: String
    let timestamp: String
    let contractAddress: String
    let owner: String
}

struct NFTDetailResult: Codable {
    let success: Bool
    let nft: NFTDetailData
}

struct NFTDetailData: Codable {
    let tokenId: String
    let threadId: String
    let buildingId: String
    let timestamp: String
    let contractAddress: String
    let owner: String
    let metadata: NFTMetadata
}

struct NFTMetadata: Codable {
    let name: String
    let description: String
    let image: String
}

struct NFTDetail {
    let tokenId: String
    let threadId: String
    let buildingId: String
    let timestamp: String
    let contractAddress: String
    let owner: String
    let metadata: NFTMetadata
}

struct AllNFTsResult: Codable {
    let success: Bool
    let nfts: [UserNFT]
    let totalCount: Int
    let page: Int
    let limit: Int
}

enum NFTError: Error {
    case invalidURL
    case serverError
    case notFound
}

// MARK: - 通知
extension Notification.Name {
    static let nftMinted = Notification.Name("NFTMinted")
    static let nftTransferred = Notification.Name("NFTTransferred")
}

// MARK: - 字符串扩展
extension String {
    static func random(length: Int) -> String {
        let characters = "0123456789abcdef"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
}

