//
//  OutlinedText.swift
//  Phygital Asset
//
//  描边文本视图 - 显示带有边框效果的文本
//

import SwiftUI

struct OutlinedText: View {
    let text: String
    let font: Font
    let strokeColor: Color
    let lineWidth: CGFloat
    let fillColor: Color

    var body: some View {
        ZStack {
            Text(text)
                .font(font)
                .foregroundStyle(fillColor)
            Text(text)
                .font(font)
                .foregroundStyle(strokeColor)
                .offset(x: lineWidth, y: 0)
            Text(text)
                .font(font)
                .foregroundStyle(strokeColor)
                .offset(x: -lineWidth, y: 0)
            Text(text)
                .font(font)
                .foregroundStyle(strokeColor)
                .offset(x: 0, y: lineWidth)
            Text(text)
                .font(font)
                .foregroundStyle(strokeColor)
                .offset(x: 0, y: -lineWidth)
        }
    }
}

