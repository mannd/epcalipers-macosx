//
//  ToolbarItem.swift
//  EP Calipers
//
//  Created by David Mann on 2/6/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import Cocoa

class ToolbarItem: NSToolbarItem {

    // This beautiful idea is from https://stackoverflow.com/questions/42470645/nstoolbaritem-validation-in-relevant-controller.
    override func validate() {
        // validate content view
        if
            let control = self.view as? NSControl,
            let action = self.action,
            let validator = NSApp.target(forAction: action, to: self.target, from: self) as AnyObject?
        {
            switch validator {
            case let validator as NSUserInterfaceValidations:
                control.isEnabled = validator.validateUserInterfaceItem(self)
            default:
                control.isEnabled = validator.validateToolbarItem(self)
            }

        } else {
            super.validate()
        }
    }

}
