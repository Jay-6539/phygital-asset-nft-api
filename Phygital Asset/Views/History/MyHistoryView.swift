//
//  MyHistoryView.swift
//  Phygital Asset
//
//  Created by AI Assistant on 2024
//

import SwiftUI

// MARK: - Date Decoding Extension
extension JSONDecoder {
    static func supabaseDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // 尝试多种日期格式
            let formatters = [
                // Supabase格式：2025-10-27T09:55:23.349771+00:00
                ISO8601DateFormatter().also { $0.formatOptions = [.withInternetDateTime, .withFractionalSeconds] },
                // 标准ISO8601格式
                ISO8601DateFormatter().also { $0.formatOptions = [.withInternetDateTime] },
                // 简单格式
                ISO8601DateFormatter().also { $0.formatOptions = [.withDate, .withTime] }
            ]
            
            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // 如果所有格式都失败，抛出错误
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected date string to be ISO8601-formatted, but got: \(dateString)"
                )
            )
        }
        return decoder
    }
}

extension ISO8601DateFormatter {
    func also(_ configure: (ISO8601DateFormatter) -> Void) -> ISO8601DateFormatter {
        configure(self)
        return self
    }
}

struct MyHistoryView: View {
    let username: String
    let appGreen: Color
    let onClose: () -> Void
    
    @State private var myCheckIns: [BuildingCheckIn] = []
    @State private var ovalCheckIns: [OvalOfficeCheckIn] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab: HistoryTab = .threads
    @State private var showNFTTransfer = false
    @State private var showNFTTransferHistory = false
    @State private var selectedNFT: NFTInfo?
    
    enum HistoryTab: String, CaseIterable {
        case threads = "Threads"
        case nfts = "NFTs"
        
        var icon: String {
            switch self {
            case .threads: return "clock.arrow.circlepath"
            case .nfts: return "photo"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }
            
            // 内容框
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text("My Thread History")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // 用户信息
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(appGreen)
                    
                    Text(username)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                Divider()
                    .padding(.horizontal, 20)
                
                // 标签页选择器
                HStack(spacing: 0) {
                    ForEach(HistoryTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 16))
                                Text(tab.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(selectedTab == tab ? appGreen : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                selectedTab == tab ? 
                                appGreen.opacity(0.1) : Color.clear
                            )
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                Divider()
                    .padding(.horizontal, 20)
                
                // 内容区域
                if selectedTab == .threads {
                    threadsContent
                } else {
                    nftsContent
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
            .frame(maxHeight: 700)
        }
        .onAppear {
            loadMyHistory()
        }
        .sheet(isPresented: $showNFTTransfer) {
            if let nft = selectedNFT {
                NFTTransferView(nft: nft)
            }
        }
        .sheet(isPresented: $showNFTTransferHistory) {
            NFTTransferHistoryView()
        }
    }
    
    // MARK: - Threads内容
    private var threadsContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .padding(.vertical, 40)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(appGreen.opacity(0.5))
                        Text("Failed to load history")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Retry") {
                            loadMyHistory()
                        }
                        .foregroundColor(appGreen)
                    }
                    .padding(.vertical, 40)
                } else if myCheckIns.isEmpty && ovalCheckIns.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No thread history yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Start creating threads to see your history!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 40)
                } else {
                    // 显示历史建筑Check-ins
                    if !myCheckIns.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Historic Buildings (\(myCheckIns.count))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                            
                            ForEach(myCheckIns) { checkIn in
                                BuildingCheckInRow(checkIn: checkIn)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 16)
                    }
                    
                    // 显示Oval Office Check-ins
                    if !ovalCheckIns.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Oval Office (\(ovalCheckIns.count))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                            
                            ForEach(ovalCheckIns) { checkIn in
                                OvalOfficeCheckInRow(checkIn: checkIn, appGreen: appGreen)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - NFTs内容
    private var nftsContent: some View {
        VStack(spacing: 16) {
            // NFT操作按钮
            HStack(spacing: 12) {
                Button(action: {
                    showNFTTransferHistory = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.arrow.left")
                        Text("Transfer History")
                    }
                    .font(.subheadline)
                    .foregroundColor(appGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(appGreen.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // NFT列表
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    // 模拟NFT数据
                    ForEach(0..<4, id: \.self) { index in
                        NFTCardView(nft: NFTInfo(
                            threadId: UUID(),
                            tokenId: "NFT-\(index + 1)",
                            contractAddress: "0xA0fA27fC547D544528e9BE0cb6569E9B925e533E",
                            buildingId: "Building \(index + 1)",
                            timestamp: "2025-10-27T15:00:00.000Z"
                        ))
                        .onTapGesture {
                            selectedNFT = NFTInfo(
                                threadId: UUID(),
                                tokenId: "NFT-\(index + 1)",
                                contractAddress: "0xA0fA27fC547D544528e9BE0cb6569E9B925e533E",
                                buildingId: "Building \(index + 1)",
                                timestamp: "2025-10-27T15:00:00.000Z"
                            )
                            showNFTTransfer = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func loadMyHistory() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 加载历史建筑的Check-ins
                async let buildingCheckIns = loadBuildingCheckIns()
                
                // 加载Oval Office的Check-ins
                async let ovalOfficeCheckIns = loadOvalOfficeCheckIns()
                
                let (buildings, ovals) = try await (buildingCheckIns, ovalOfficeCheckIns)
                
                await MainActor.run {
                    self.myCheckIns = buildings
                    self.ovalCheckIns = ovals
                    self.isLoading = false
                    Logger.success("✅ Loaded \(buildings.count) building threads, \(ovals.count) oval office threads")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    Logger.error("❌ Failed to load history: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadBuildingCheckIns() async throws -> [BuildingCheckIn] {
        let endpoint = "building_checkins?username=eq.\(username)&select=*&order=created_at.desc"
        let url = URL(string: "\(SupabaseConfig.url)/rest/v1/\(endpoint)")!
        
        var request = URLRequest(url: url)
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "FetchFailed", code: -1)
        }
        
        let decoder = JSONDecoder.supabaseDecoder()
        return try decoder.decode([BuildingCheckIn].self, from: data)
    }
    
    private func loadOvalOfficeCheckIns() async throws -> [OvalOfficeCheckIn] {
        let endpoint = "oval_office_checkins?username=eq.\(username)&select=*&order=created_at.desc"
        let url = URL(string: "\(SupabaseConfig.url)/rest/v1/\(endpoint)")!
        
        var request = URLRequest(url: url)
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "FetchFailed", code: -1)
        }
        
        let decoder = JSONDecoder.supabaseDecoder()
        return try decoder.decode([OvalOfficeCheckIn].self, from: data)
    }
}