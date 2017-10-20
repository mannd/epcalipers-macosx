//
//  QTcResult.swift
//  EP Calipers
//
//  Created by David Mann on 10/16/17.
//  Copyright © 2017 EP Studios. All rights reserved.
//

import Foundation
import QTc

class QTcResult: QTcResultProtocol {
    func calculate(qtInSec: Double, rrInSec: Double, formula: QTcFormulaPreference, convertToMsec: Bool, units: String) -> String {
        if rrInSec <= 0 {
            return NSLocalizedString("Invalid Result", comment:"")
        }
        let qtcFormulas: [QTcFormula]
        switch formula {
        case .Bazett:
            qtcFormulas = [.qtcBzt]
        case .Fridericia:
            qtcFormulas = [.qtcFrd]
        case .Framingham:
            qtcFormulas = [.qtcFrm]
        case .Hodges:
            qtcFormulas = [.qtcHdg]
        case .all:
            qtcFormulas = [.qtcBzt, .qtcFrd, .qtcFrm, .qtcHdg]
        }
        var meanRR = rrInSec
        var qt = qtInSec
        if convertToMsec {
            meanRR *= 1000
            qt *= 1000
        }
        var result = NSString.localizedStringWithFormat(NSLocalizedString("Mean RR = %.4g %@\nQT = %.4g %@", comment:"") as NSString, meanRR, units, qt, units) as String
        for qtcFormula in qtcFormulas {
            let qtcCalculator = QTc.qtcCalculator(formula: qtcFormula)
            var qtc = qtcCalculator.calculate(qtInSec: qtInSec, rrInSec: rrInSec)
            // switch to units that calibration uses
            if convertToMsec {
                qtc *= 1000
            }
            result += NSString.localizedStringWithFormat(NSLocalizedString("\nQTc = %.4g %@ (%@ formula)", comment:"") as NSString, qtc, units, qtcCalculator.longName) as String
        }
        return result
    }
    
    
}
