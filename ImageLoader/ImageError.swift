//
//  ImageError.swift
//  Mobelux
//
//  Created by Jeremy Greenwood on 2/8/18.
//  Copyright © 2018 Mobelux. All rights reserved.
//

import Foundation
import DataOperation

enum ImageError: LocalizedError {
    case cannotParse
    case noResult
    case unknown
    case custom(String)

    public var errorDescription: String {
        switch self {
        case .cannotParse: return NSLocalizedString("ImageLoader.cannotParse", comment: "")
        case .noResult: return NSLocalizedString("ImageLoader.noResult", comment: "")
        case .unknown: return NSLocalizedString("Generic.unknownError", comment: "")
        case .custom(let message): return message
        }
    }
}

extension ImageError {
    static func convertFrom(_ dataError: DataError) -> ImageError {
        switch dataError {
        case .unknown: return .unknown
        case .custom(let message): return .custom(message)
        }
    }
}
