//
//  ResponseType.swift
//  Mobelux
//
//  Created by Jeremy Greenwood on 2/8/18.
//  Copyright © 2018 Mobelux. All rights reserved.
//

import Foundation

public enum ResultType<T> {
    case cached(T)
    case downloaded(T)

    public var value: T {
        switch self {
        case .cached(let value):
            return value
        case .downloaded(let value):
            return value
        }
    }
}
