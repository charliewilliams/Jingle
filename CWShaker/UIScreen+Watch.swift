//
//  UIScreen+Watch.swift
//  Jingle
//
//  Created by Charlie Williams on 02/12/2022.
//  Copyright © 2022 Charlie Williams. All rights reserved.
//

import UIKit
import WatchKit

struct Screen {
#if os(watchOS)
    static let screenSize = WKInterfaceDevice.current().screenBounds.size
    static let screenWidth = screenSize.width
    static let screenHeight = screenSize.height
#elseif os(iOS) || os(tvOS)
    static let screenSize = UIScreen.main.nativeBounds.size
    static let screenWidth = screenSize.width
    static let screenHeight = screenSize.height
#elseif os(macOS)
    static let screenSize = NSScreen.main?.visibleFrame.size
    static let screenWidth = screenSize.width
    static let screenHeight = screenSize.height
#endif
    static let middleOfScreen = CGPoint(x: screenWidth / 2, y: screenHeight / 2)
}
