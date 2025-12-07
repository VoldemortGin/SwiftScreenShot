//
//  ImageFormat.swift
//  SwiftScreenShot
//
//  Image format enumeration for screenshot saving
//

import Foundation

enum ImageFormat {
    case png
    case jpeg(quality: Double)  // 0.0 - 1.0

    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        }
    }
}

extension ImageFormat: RawRepresentable {
    var rawValue: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpeg"
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "png": self = .png
        case "jpeg": self = .jpeg(quality: 0.9)
        default: return nil
        }
    }
}
