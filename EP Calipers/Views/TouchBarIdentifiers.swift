//
//  TouchBarIdentifiers.swift
//  EP Calipers
//
//  Created by David Mann on 2/1/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import AppKit

@available(OSX 10.12.2, *)
extension NSTouchBarItem.Identifier {
    static let zoom = NSTouchBarItem.Identifier("org.epstudios.epcalipers.zoom")
    static let addCalipers = NSTouchBarItem.Identifier("org.epstudios.epcalipers.addCalipers")
    static let calibration = NSTouchBarItem.Identifier("org.epstudios.epcalipers.calibration")
    static let openFile = NSTouchBarItem.Identifier("org.epstudios.epcalipers.openFile")
    static let tweak = NSTouchBarItem.Identifier("org.epstudios.epcalipers.tweak")
    static let cancel = NSTouchBarItem.Identifier("org.epstudios.epcalipers.cancel")
}

@available(OSX 10.12.2, *)
extension NSTouchBar.CustomizationIdentifier {
    static let epcalipersBar = NSTouchBar.CustomizationIdentifier("org.epstudios.epcalipers.TouchBar")
}

