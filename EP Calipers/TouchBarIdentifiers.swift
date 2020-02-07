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
    static let infoLabelItem = NSTouchBarItem.Identifier("org.epstudios.epcalipers.InfoLabel")
}

@available(OSX 10.12.2, *)
extension NSTouchBar.CustomizationIdentifier {
    static let epcalipersBar = NSTouchBar.CustomizationIdentifier("org.epstudios.epcalipers.TravelBar")
}

