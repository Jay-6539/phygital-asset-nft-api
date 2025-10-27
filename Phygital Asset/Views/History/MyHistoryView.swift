//
//  MyHistoryView.swift
//  Phygital Asset
//
//  Created by AI Assistant on 2024
//

import SwiftUI

struct MyHistoryView: View {
    let username: String
    let appGreen: Color
    let onClose: () -> Void
    
    @State private var myCheckIns: [BuildingCheckIn] = []
    @State private var ovalCheckIns: [OvalOfficeCheckIn] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
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
                
                // 历史记录列表
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
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
            .frame(maxHeight: 700)
        }
        .onAppear {
            loadMyHistory()
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
        let baseURL = SupabaseConfig.url
        let apiKey = SupabaseConfig.anonKey
        
        guard let url = URL(string: "\(baseURL)/rest/v1/threads?username=eq.\(username)&order=created_at.desc") else {
            throw NSError(domain: "InvalidURL", code: -1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "FetchFailed", code: -1)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([BuildingCheckIn].self, from: data)
    }
    
    private func loadOvalOfficeCheckIns() async throws -> [OvalOfficeCheckIn] {
        let baseURL = SupabaseConfig.url
        let apiKey = SupabaseConfig.anonKey
        
        guard let url = URL(string: "\(baseURL)/rest/v1/oval_office_threads?username=eq.\(username)&order=created_at.desc") else {
            throw NSError(domain: "InvalidURL", code: -1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "FetchFailed", code: -1)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([OvalOfficeCheckIn].self, from: data)
    }
}
