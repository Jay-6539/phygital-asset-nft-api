//
//  ThreadRecord.swift
//  Phygital Asset
//
//  Created by refactoring on 21/10/2025.
//

import Foundation
import UIKit

// Thread记录结构体（用户在NFC上留下的记录）
struct ThreadRecord {
    let username: String
    let timestamp: Date
    let assetName: String
    let description: String
    let image: UIImage?
}

