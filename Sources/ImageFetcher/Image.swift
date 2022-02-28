//
//  Image.swift
//  
//
//  Created by Jeremy Greenwood on 2/25/22.
//

#if os(macOS)
import AppKit

public typealias Image = NSImage
#else
import UIKit

public typealias Image = UIImage
#endif
