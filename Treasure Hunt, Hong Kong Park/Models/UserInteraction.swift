//
//  UserInteraction.swift
//  Treasure Hunt, Hong Kong Park
//
//  Created by refactoring on 21/10/2025.
//

import Foundation
import UIKit

// 用户互动数据结构
struct UserInteraction: Identifiable {
    let id = UUID()
    let username: String
    let interactionTime: Date
    let image: UIImage?
    let assetName: String  // 记录当时的Asset名称
    let description: String
}

