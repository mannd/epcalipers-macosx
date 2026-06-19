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
    var magnificationAtCalibration: Double = 1.0
    var calibrationFactorAtCalibration: Double = 1.0
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
    
    func multiplier(currentMagnification: Double) -> Double {
        guard calibrated else { return 1.0 }
        return (magnificationAtCalibration * calibrationFactorAtCalibration) / currentMagnification

    }

    func reset() {
        rawUnits = "points"
        displayRate = false
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
            if rawUnits.isEmpty {
                return false
            }
            let units = rawUnits.uppercased()
            return units == "S" || units == "SEC"
            || units == "SECOND" || units == "SECS"
            || units == "SECONDS"
        }
    }
    
    var unitsAreMsec: Bool {
        if rawUnits.isEmpty {
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

    var unitsAreMsecOrRate: Bool {
        return unitsAreMsec || displayRate
    }
    
}
