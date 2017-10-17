//
//  QTcResult.swift
//  EP Calipers
//
//  Created by David Mann on 10/16/17.
//  Copyright © 2017 EP Studios. All rights reserved.
//

import Foundation

class QTcResult: QTcResultProtocol {
    func calculate(qtInSec: Double, rrInSec: Double, formula: QTcFormula, convertToMsec: Bool, units: String) -> String {
        var result = NSLocalizedString("Invalid Result", comment:"")
        var meanRR = rrInSec
        var qt = qtInSec
        if meanRR > 0 {
            let sqrtRR = sqrt(meanRR)
            var qtc = qt / sqrtRR
            // switch to units that calibration uses
            if convertToMsec {
                meanRR *= 1000
                qt *= 1000
                qtc *= 1000
            }
            result = NSString.localizedStringWithFormat(NSLocalizedString("Mean RR = %.4g %@\nQT = %.4g %@\nQTc = %.4g %@ (Bazett's formula)", comment:"") as NSString, meanRR, units, qt, units, qtc, units) as String
        }
        return result
    }
    
    
}
