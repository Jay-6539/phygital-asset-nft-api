//
//  CompactCheckInRow.swift
//  Phygital Asset
//
//  精简的Check-in记录行
//

import SwiftUI

struct CompactCheckInRow: View {
    let time: Date
    let assetName: String
    let description: String
    let appGreen: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 时间和名称
            HStack {
                Text(assetName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(time, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 描述
            if !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}





