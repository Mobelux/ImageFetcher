//
//  CGSize+Hashable.swift
//  ImageFetcher
//
//  Created by Jeremy Greenwood on 4/1/19.
//  Copyright © 2019 Mobelux. All rights reserved.
//

import QuartzCore

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}
