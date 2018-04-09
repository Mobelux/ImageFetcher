//
//  Keyable.swift
//  Mobelux
//
//  Created by Jeremy Greenwood on 2/8/18.
//  Copyright © 2018 Mobelux. All rights reserved.
//

import Foundation

public protocol Keyable {
    var key: String { get }
}

extension URL: Keyable {
    public var key: String {
        return String(hashValue)
    }
}

extension String: Keyable {
    public var key: String {
        return String(hashValue)
    }
}
