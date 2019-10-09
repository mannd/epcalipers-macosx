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
        print("PanelView viewWillDraw()")
        self.layer?.backgroundColor = NSColor.controlColor.cgColor
//        self.layer?.backgroundColor = NSColor.systemGray.cgColor
    }

    override func updateLayer() {
        print("PanelView updateLayer()")
        //self.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.

    }
    
}
