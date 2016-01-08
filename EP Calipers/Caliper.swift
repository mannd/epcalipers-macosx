//
//  Caliper.swift
//  EP Calipers
//
//  Created by David Mann on 1/7/16.
//  Copyright © 2016 EP Studios. All rights reserved.
//

import Cocoa

enum CaliperDirection {
    case Horizontal
    case Vertical
}

class Caliper: NSObject {

    let delta: Double = 20.0
    var bar1Position: Float
    var bar2Position: Float
    var crossBarPosition: Float
    var direction: CaliperDirection
    var color: NSColor
    var unselectedColor: NSColor
    var selectedColor: NSColor
    var lineWidth: Int
    var valueInPoints: Float = 0// readonly
    var selected: Bool
    var textFont: NSFont
    var paragraphStyle: NSMutableParagraphStyle
    var attributes: NSMutableDictionary
    
    init(direction: CaliperDirection, bar1Position: Float, bar2Position: Float,
        crossBarPosition: Float) {

            self.direction = direction
            self.bar1Position = bar1Position
            self.bar2Position = bar2Position
            self.crossBarPosition = crossBarPosition
            self.color = NSColor.blueColor()
            self.unselectedColor = NSColor.blueColor()
            self.selectedColor = NSColor.redColor()
            self.lineWidth = 2
            self.selected = false
            self.textFont = NSFont(name: "Helvetica", size: 18.0)!
            self.paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            self.attributes = NSMutableDictionary()
            
            super.init()
    }
}
