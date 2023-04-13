//
//  Keyable.swift
//  Mobelux
//
//  Created by Jeremy Greenwood on 2/8/18.
//  Copyright © 2018 Mobelux. All rights reserved.
//

import Foundation

/// A class of types whose instances hold a hash key.
public protocol Keyable {
    /// The hash key associated with this instance.
    var key: String { get }
}

extension URL: Keyable {
    public var key: String {
        return absoluteString.md5
    }
}

extension String: Keyable {
    public var key: String {
        return md5
    }
}
