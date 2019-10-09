//
//  PanelView.swift
//  EP Calipers
//
//  Created by David Mann on 10/11/18.
//  Copyright © 2018 EP Studios. All rights reserved.
//

import Cocoa

class PanelView: NSView {

    override func viewWillDraw() {
        super.viewWillDraw()
        self.layer?.backgroundColor = NSColor.controlColor.cgColor
    }

}
