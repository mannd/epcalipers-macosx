//
//  Calibration.swift
//  EP Calipers
//
//  Created by David Mann on 1/10/16.
//  Copyright © 2016 EP Studios. All rights reserved.
//

import Cocoa

class Calibration: NSObject {
    var direction: CaliperDirection
    var calibrationString: String = ""
    var displayRate: Bool = false
    var originalZoom: Double = 1.0
    var currentZoom: Double = 1.0
    var originalCalFactor: Double = 1.0
    var calibrated: Bool = false
    var rawUnits: String = "points"
    
    init(direction: CaliperDirection) {
        self.direction = direction
        super.init()
    }
    
    override convenience init() {
        self.init(direction: .horizontal)
    }
    
    var units: String {
        get {
            if calibrated {
                if displayRate {
                    return "bpm"
                }
                else {
                    return rawUnits
                }
            }
            else {
                return "points"
            }
        }
    }
    
    func currentCalFactor() -> Double {
        return (originalZoom * originalCalFactor) / currentZoom
    }
    
    func multiplier() -> Double {
        if calibrated {
            return currentCalFactor()
        }
        else {
            return 1.0
        }
    }
    
    func reset() {
        rawUnits = "points"
        displayRate = false
        originalZoom = 1.0
        currentZoom = 1.0
        calibrated = false
    }
    
    var canDisplayRate: Bool {
        get {
            if direction == .vertical {
                return false
            }
            else if !calibrated  {
                return false
            }
            return unitsAreMsec || unitsAreSeconds
        }
    }
    
    var unitsAreSeconds: Bool {
        get {
            if rawUnits.characters.count < 1 {
                return false
            }
            let units = rawUnits.uppercased()
            return units == "S" || units == "SEC"
            || units == "SECOND" || units == "SECS"
            || units == "SECONDS"
        }
    }
    
    var unitsAreMsec: Bool {
        if rawUnits.characters.count < 1 {
            return false
        }
        let units = rawUnits.uppercased()
        return units.contains("MSEC") || units == "MS"
        || units.contains("MILLIS")
    }
    
    var unitsAreMM: Bool {
        if units.isEmpty || direction != .vertical {
            return false
        }
        let upcasedUnits = units.uppercased()
        return upcasedUnits == "MM" || upcasedUnits.contains("MILLIM")
    }
    
}
