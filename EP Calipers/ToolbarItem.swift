//
//  ToolbarItem.swift
//  EP Calipers
//
//  Created by David Mann on 2/1/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import Cocoa

class ToolbarItem: NSToolbarItem {
    var valid = true

    override func validate() {
        super.validate()
        NSLog("validate")
        let code = self.itemIdentifier
        NSLog("code = \(code)")
        self.isEnabled = valid
    }
}
