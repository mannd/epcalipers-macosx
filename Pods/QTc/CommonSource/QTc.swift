//
//  QTc.swift
//  QTc
//
//  Created by David Mann on 9/2/17.
//  Copyright © 2017, 2018 EP Studios. All rights reserved.
//

import Foundation

/** QTc and QTp formulas.  These are identifiers for the many
    different formulas.

    Nomenclature from [Rabkin and Cheng, 2015](https://www.wjgnet.com/1949-8462/full/v7/i6/315.htm#B17).

    QTc formulas labeled as qtcXXX, QTp as qtpXXX.
 */
public enum Formula: String {
    // QTc formulas
    case qtcBzt  // Bazett
    case qtcFrd  // Fridericia
    case qtcFrm  // Framingham
    case qtcHdg  // Hodges
    case qtcRtha // Rautaharju (2014) QTcMod
    case qtcRthb // Rautaharju (2014) QTcLogLin
    case qtcMyd  // Mayeda
    case qtcArr  // Arrowood
    case qtcKwt  // Kawataki
    case qtcDmt  // Dimitrienko
    case qtcYos  // Yoshinaga
    case qtcAdm  // Adams
    case qtcGot  // Goto
    case qtcRbk  // Rabkin
    case qtcTest // for testing only
    
    // QTp formulas
    case qtpBzt  // Bazett
    case qtpFrd  // Fridericia
    case qtpArr  // Arrowood
    case qtpBdl  // Boudoulas (note Rabkin has qtcBRL -- typo?)
    case qtpAsh  // Ashman
    case qtpHdg  // Hodges
    case qtpMyd  // Mayeda
    case qtpKrj  // Karjalainen
    case qtpSch  // Schlamowitz
    case qtpAdm  // Adams
    case qtpSmn  // Simonson
    case qtpKwt  // Kawataki
    case qtpScl  // Schlomka
    case qtpMrr  // Merri
    case qtpHgg  // Hegglin
    case qtpGot  // Goto
    case qtpKlg  // Kligfield
    case qtpShp  // Shipley
    case qtpWhl  // Wohlfart
    case qtpSrm  // Sarma
    case qtpLcc  // Lecocq
    case qtpRbk  // Rablin

    /// A formula is either a QTc or QTp
    /// - returns: a FormulaType (QTc or QTp)
    public func formulaType() -> FormulaType {
        let qtcFormulas: Set<Formula> = [.qtcBzt, .qtcFrd, .qtcFrm, .qtcHdg, .qtcRtha, .qtcRthb, .qtcMyd, .qtcArr, .qtcKwt, .qtcDmt, .qtcYos, .qtcAdm, .qtcGot, .qtcRbk]
        let qtpFormulas: Set<Formula> = [.qtpBzt, .qtpFrd, .qtpArr, .qtpBdl, .qtpAsh, .qtpHdg, .qtpMyd, .qtpKrj, .qtpSch, .qtpAdm, .qtpSmn, .qtpKwt, .qtpScl, .qtpMrr, .qtpHgg, .qtpGot, .qtpKlg, .qtpShp, .qtpWhl, .qtpSrm, .qtpLcc, .qtpRbk]
        if qtcFormulas.contains(self) {
            return .qtc
        } else if qtpFormulas.contains(self) {
            return .qtp
        } else {
            fatalError("Undefined formula")
        }
    }
}

/// indicates whether a Formula is a QTc or QTp
public enum FormulaType {
    case qtc
    case qtp
}


// TODO: localize strings, and ensure localization works when used as a Pod
// See https://medium.com/@shenghuawu/localization-cocoapods-5d1e9f34f6e6 and
// http://yannickloriot.com/2014/02/cocoapods-and-the-localized-string-files/

/// Mathematical classification of formula
/// Defined in [Rabkin and Cheng, 2015](https://www.wjgnet.com/1949-8462/full/v7/i6/315.htm#B17)
public enum FormulaClassification {
    case linear
    case rational
    case power
    case logarithmic
    case exponential
    case other
}

/// Can be male, female, or unspecified.
/// Sex.unspecified indicates you are not providing specific Sex to a formula.
public enum Sex {
    case male
    case female
    case unspecified
}

/// Error codes that can be thrown by certain formulas when necessary parameters are lacking or out of range.
public enum CalculationError: Error {
    case heartRateOutOfRange
    case ageOutOfRange
    case ageRequired
    case sexRequired
    case wrongSex
    case qtOutOfRange
    case qtMissing
    case unspecified
    case undefinedFormula
}

/// Age in all formulas must be rounded to years, or nil if unspecified
public typealias Age = Int?

/// Used only for return type when unclear if returned Double
/// is Msec or Sec
public typealias Msec = Double
/// Used only for return type when unclear if returned Double
/// is Msec or Sec
public typealias Sec = Double

typealias QTcEquation = (_ qt: Double, _ rr: Double, _ sex: Sex, _ age: Age) throws -> Double
typealias QTpEquation = (_ rr: Double, Sex, Age) throws -> Double

/// For backward compatibility
public typealias BaseCalculator = Calculator

/**
 This class is meant to be overriden.  Do not instantiate a Calculator, just its subclasses, QTcCalculator and QTpCalculator.  Factory methods are used to generator Calculators.

 Calculators are distinct from Formulas.  A Formula is an identifier for a specific Calculator.  The Calculator classes contain detailed information such as the name, reference, publication date, etc.  The *equation* is the mathematical equation presented as a string.  The *baseEquation* (defined in the subclasses of Calculator) is the actual equation presented as a closure.
*/
public class Calculator {
    public var formula: Formula
    public let longName: String
    public let shortName: String
    public let reference: String
    public let equation: String
    public let classification: FormulaClassification
    // potentially add notes to certain formulas
    public let notes: String
    public var numberOfSubjects: Int?
    public var publicationDate: String? { get {
        if let date = date {
            return formatter.string(from: date)
        }
        return nil
        }}
    private let date: Date?
    private let formatter = DateFormatter()

    /// base class init, not to be directly used.
    fileprivate init(longName: String, shortName: String, reference: String, equation: String,
         classification: FormulaClassification, notes: String,
         publicationDate: String?, numberOfSubjects: Int?) {
        
        self.formula = .qtcBzt  // arbitrary initiation, always overriden,
                                // but can avoid formula as optional
        self.longName = longName
        self.shortName = shortName
        self.reference = reference
        self.equation = equation
        self.classification = classification
        self.notes = notes
        formatter.dateFormat = "yyyy"
        if let publicationDate = publicationDate {
            date = formatter.date(from: publicationDate)
        }
        else {
            date = nil
        }
        self.numberOfSubjects = numberOfSubjects
    }
    
    /// base class func, meant to be overriden
    public func calculate(qtMeasurement: QtMeasurement) throws -> Double {
        assertionFailure("Base class Calculator.calculate() must be overriden.")
        return 0
    }
}

/// Class containing all aspects of a QTc calculator.
public class QTcCalculator: Calculator {
    let baseEquation: QTcEquation

    /**
     Construct a QTcCalculator.

     - Parameters:
         - formula: one of enum Formula
         - longName: generally first author's name
         - shortName: name in form QTcXXX
         - reference: literature reference in AMA format
         - equation: equation in String form, usually in original format as presented in reference or normalized for sec units
         - baseEquation: a closure in the form of QTcEquation, the mathematic formula normalized for units of sec
         - classification: one of FormulaClassification
         - forAdults: the study population was not pediatric only.  Probably will be deprecated.  Defaults to true.
         - notes: information from the reference on the formula.  Defaults to nil.
         - publicationDate: year of publication as String.  Defaults to nil.
         - numberOfSubjects: number of subjects in the study population. Defaults to nil.
     */
    init(formula: Formula, longName: String, shortName: String,
         reference: String, equation: String, baseEquation: @escaping QTcEquation,
         classification: FormulaClassification, forAdults: Bool = true, notes: String = "",
         publicationDate: String? = nil, numberOfSubjects: Int? = nil) {
        
        self.baseEquation = baseEquation
        super.init(longName: longName, shortName: shortName,
                   reference: reference, equation: equation,
                   classification: classification,
                   notes: notes, publicationDate: publicationDate,
                   numberOfSubjects: numberOfSubjects)
        self.formula = formula
    }
    
    /**
     Calculate QTc using parameters in sec

     - Parameters:
         - qtInSec: QT interval in sec
         - rrInSec: RR interval in sec
         - sex: Sex defaults to .unspecified
         - age: as Int? defaults to nil
     - Returns: QTc in sec
     - Throws: a CalculationError
     */
    public func calculate(qtInSec: Double, rrInSec: Double, sex: Sex = .unspecified, age: Age = nil) throws -> Sec {
        return try baseEquation(qtInSec, rrInSec, sex, age)
    }
    
    /**
     Calculate QTc using parameters in msec

     - Parameters:
         - qtInMsec: QT interval in msec
         - rrInMsec: RR interval in msec
         - sex: Sex defaults to .unspecified
         - age: as Int? defaults to nil
     - Returns: QTc in msec
     - Throws: a CalculationError
     */
    public func calculate(qtInMsec: Double, rrInMsec: Double, sex: Sex = .unspecified, age: Age = nil) throws -> Msec {
        return try QTc.qtcConvert(baseEquation, qtInMsec: qtInMsec, rrInMsec: rrInMsec, sex: sex, age: age)
    }
    
    /**
     Calculate QTc using QT in sec and heart rate

     - Parameters:
         - qtInSec: QT interval in sec
         - rate: heart rate in beats per min
         - sex: Sex defaults to .unspecified
         - age: as Int? defaults to nil
     - Returns: QTc in sec
     - Throws: a CalculationError
     */
    public func calculate(qtInSec: Double, rate: Double, sex: Sex = .unspecified, age: Age = nil) throws -> Sec {
        return try QTc.qtcConvert(baseEquation, qtInSec: qtInSec, rate: rate, sex: sex, age: age)
    }
    
    /**
     Calculate QTc using QT in msec and heart rate

     - Parameters:
         - qtInMsec: QT interval in msec
         - rate: heart rate in beats per min
         - sex: Sex defaults to .unspecified
         - age: as Int? defaults to nil
     - Returns: QTc in msec
     - Throws: a CalculationError
     */
    public func calculate(qtInMsec: Double, rate: Double, sex: Sex = .unspecified, age: Age = nil) throws -> Msec {
        return try QTc.qtcConvert(baseEquation, qtInMsec: qtInMsec, rate: rate, sex: sex, age: age)
    }
    
    /**
     Calculate QTc using a QtMeasurement

     - Parameters:
         - qtMeasurement: the intervals being measured
     - Returns: QTc in msec or sec, depending on QTMeasurement paramters
     - Throws: a CalculationError

     */
    override public func calculate(qtMeasurement: QtMeasurement) throws -> Double {
        return try calculate(qt: qtMeasurement.qt, intervalRate: qtMeasurement.intervalRate,
                             intervalRateType: qtMeasurement.intervalRateType, sex: qtMeasurement.sex,
                             age: qtMeasurement.age, units: qtMeasurement.units)
    }

    public func calculate(qt: Double?, intervalRate: Double, intervalRateType: IntervalRateType,
                   sex: Sex, age: Age, units: Units) throws -> Double {
        guard let qt = qt else { throw CalculationError.qtMissing }
        var result: Double
        switch units {
        case .msec:
            if intervalRateType == .interval {
                result = try calculate(qtInMsec: qt, rrInMsec: intervalRate, sex: sex, age: age)
            }
            else {
                result = try calculate(qtInMsec: qt, rate: intervalRate, sex: sex, age: age)
            }
        case .sec:
            if intervalRateType == .interval {
                result = try calculate(qtInSec: qt, rrInSec: intervalRate, sex: sex, age: age)
            }
            else {
                result = try calculate(qtInSec: qt, rate: intervalRate, sex: sex, age: age)
            }
        }
        return result
    }
    
}

/// Class containing all aspects of a QTp calculator.
public class QTpCalculator: Calculator {
    let baseEquation: QTpEquation
    
    /**
     Construct a QTpCalculator.

     - Parameters:
         - formula: one of enum Formula
         - longName: generally first author's name
         - shortName: name in form QTpXXX
         - reference: literature reference in AMA format
         - equation: equation in String form, usually in original format as presented in reference or normalized for sec units
         - baseEquation: a closure in the form of QTpEquation, the mathematic formula normalized for units of sec
         - classification: one of FormulaClassification
         - forAdults: the study population was not pediatric only.  Probably will be deprecated.  Defaults to true.
         - notes: information from the reference on the formula.  Defaults to nil.
         - publicationDate: year of publication as String.  Defaults to nil.
         - numberOfSubjects: number of subjects in the study population. Defaults to nil.
     */
    init(formula: Formula, longName: String, shortName: String,
                  reference: String, equation: String, baseEquation: @escaping QTpEquation,
                  classification: FormulaClassification, forAdults: Bool = true, notes: String = "", publicationDate: String?  = nil, numberOfSubjects: Int? = nil) {
        self.baseEquation = baseEquation
        super.init(longName: longName, shortName: shortName,
                   reference: reference, equation: equation,
                   classification: classification,
                   notes: notes, publicationDate: publicationDate,
                   numberOfSubjects: numberOfSubjects)
        self.formula = formula
    }
    
    /**
     Calculate QTp using RR interval in sec

     - Parameters:
         - rrInSec: RR interval in sec
         - sex: Sex defaults to .unspecified
         - age: as Int? defaults to nil
     - Returns: QTp in sec
     - Throws: a CalculationError
     */
    public func calculate(rrInSec: Double, sex: Sex = .unspecified, age: Age = nil) throws -> Sec {
        return try baseEquation(rrInSec, sex, age)
    }
    
    /**
     Calculate QTp using RR interval in msec

     - Parameters:
         - rrInMsec: RR interval in msec
         - sex: Sex defaults to .unspecified
         - age: as Int? defaults to nil
     - Returns: QTp in msec
     - Throws: a CalculationError
     */
    public func calculate(rrInMsec: Double, sex: Sex = .unspecified, age: Age = nil) throws -> Msec {
        return try QTc.qtpConvert(baseEquation, rrInMsec: rrInMsec, sex: sex, age: age)
    }
    
    /**
     Calculate QTp using heart rate

     - Parameters:
     - rate: heart rate in beats per min
     - sex: Sex defaults to .unspecified
     - age: as Int? defaults to nil
     - Returns: QTp in sec
     - Throws: a CalculationError
     */
    public func calculate(rate: Double, sex: Sex = .unspecified, age: Age = nil) throws -> Sec {
        return try QTc.qtpConvert(baseEquation, rate: rate, sex: sex, age: age)
    }
    
    /**
     Calculate QTc using a QtMeasurement

     - Parameters:
     - qtMeasurement: the intervals being measured
     - Returns: QTp in msec or sec, depending on QTMeasurement paramters
     - Throws: a CalculationError

     */
    override public func calculate(qtMeasurement: QtMeasurement) throws -> Double {
        return try calculate(intervalRate: qtMeasurement.intervalRate,
                             intervalRateType: qtMeasurement.intervalRateType, sex: qtMeasurement.sex,
                             age: qtMeasurement.age, units: qtMeasurement.units)
    }
    
    func calculate(intervalRate: Double, intervalRateType: IntervalRateType,
                   sex: Sex, age: Age, units: Units) throws -> Double {
        var result: Double
        switch units {
        case .msec:
            if intervalRateType == .interval {
                result = try calculate(rrInMsec: intervalRate, sex: sex, age: age)
            }
            else {
                result = try calculate(rate: intervalRate, sex: sex, age: age)
                // be true to the units passed, and return result in msec
                result = QTc.secToMsec(result)
            }
        case .sec:
            if intervalRateType == .interval {
                result = try calculate(rrInSec: intervalRate, sex: sex, age: age)
            }
            else {
                result = try calculate(rate: intervalRate, sex: sex, age: age)
            }
        }
        return result
    }
}

// These are protocols that the formula source must adhere to.
protocol QTcFormulaSource {
    static func qtcCalculator(formula: Formula) -> QTcCalculator
}

protocol QTpFormulaSource {
    static func qtpCalculator(formula: Formula) -> QTpCalculator
}

/// The QTc class provides static functions:
///  conversion functions such as secToMsec(sec:) and factory
///  methods to generate QTc and QTp calculator classes
public class QTc {
    // QTc class is not to be instantiated.
    private init() {}
    
    // Static conversion functions convering all possible conversions

    /// convert sec to msec
    public static func secToMsec(_ sec: Double) -> Double {
        return sec * 1000
    }

    /// convert msec to sec
    public static func msecToSec(_ msec: Double) -> Double {
        return msec / 1000
    }

    /// convert bpm to sec
    public static func bpmToSec(_ bpm: Double) -> Double {
        return 60 / bpm
    }

    /// convert sec to bpm
    public static func secToBpm(_ sec: Double) -> Double {
        return 60 / sec
    }

    /// convert bpm to msec
    public static func bpmToMsec(_ bpm: Double) -> Double {
        return 60_000 / bpm
    }

    /// convert msec to bpm
    public static func msecToBpm(_ msec: Double) -> Double {
        return 60_000 / msec
    }
    
    
    // These functions allow mocking the Formula source
    static func qtcCalculator<T: QTcFormulaSource>(formulaSource: T.Type, formula: Formula) -> QTcCalculator {
        return T.qtcCalculator(formula: formula)
    }
    
    static func qtpCalculator<T: QTpFormulaSource>(formulaSource: T.Type, formula: Formula) -> QTpCalculator {
        return T.qtpCalculator(formula: formula)
    }
    

    /**
     QTc Factory.

     These are used like this:

         let qtcBztCalculator = QTc.qtcCalculator(formula: .qtcBzt)
         let qtc = qtcBztCalculator.calculate(qtInSec: qt, rrInSec: rr)

     - Parameters:
         - formula: a QTc Formula
     - Returns: a QTcCalculator
     */
    public static func qtcCalculator(formula: Formula) -> QTcCalculator {
        return qtcCalculator(formulaSource: Formulas.self, formula: formula)
    }
    
    /**
     QTp Factory.

     These are used like this:

         let qtpBztCalculator = QTc.qtpCalculator(formula: .qtpBzt)
         let qtp = qtpBztCalculator.calculate(rrInSec: rr)

     - Parameters:
         - formula: a QTp Formula
     - Returns: a QTpCalculator
     */
    public static func qtpCalculator(formula: Formula) -> QTpCalculator {
        return qtpCalculator(formulaSource: Formulas.self, formula: formula)
    }
    
    
    /**
     Calculator Factory.  Will return a QTcCalculator or QTpCalculator
     depending on the parameters.

     - Parameters:
         - formula: a QTc Formula or QTp Formula
         - formulaType: whether it is a QTc or QTp Formula
     - Returns: a QTcCalculator or QTpCalculator, depending on formulaType
     */
    public static func calculator(formula: Formula, formulaType: FormulaType) -> Calculator {
        switch formulaType {
        case .qtc:
            return qtcCalculator(formula: formula)
        case .qtp:
            return qtpCalculator(formula: formula)
        }
    }
    
    /**
     Calculator Factory.  Will return a QTcCalculator or QTpCalculator
     depending on the formula parameter.  Infers correct Calculator to
     return from the formula.  This is the easiest way to generate
     a QTcCalculator or QTpCalculator.

     Example:

          let calculator = QTc.calculator(formula: .qtcBzt)
          let measurement = QtMeasurement(.....)  // init a QtMeasurement struct
          let result = calculator.calculate(measurement: measurement)


     - Parameters:
         - formula: a QTc Formula or QTp Formula
     - Returns: a QTcCalculator or QTpCalculator, depending on formula
     */
    public static func calculator(formula: Formula) -> Calculator {
        return calculator(formula: formula, formulaType: formula.formulaType())
    }
    
    // Convert from one set of units to another
    // QTc conversion
    fileprivate static func qtcConvert(_ qtcEquation: QTcEquation,
                                       qtInMsec: Double, rrInMsec: Double, sex: Sex, age: Age) throws -> Msec {
        return secToMsec(try qtcEquation(msecToSec(qtInMsec), msecToSec(rrInMsec), sex, age))
    }
    
    fileprivate static func qtcConvert(_ qtcEquation: QTcEquation,
                                       qtInSec: Double, rate: Double, sex: Sex, age: Age) throws -> Sec {
        return try qtcEquation(qtInSec, bpmToSec(rate), sex, age)
    }
    
    fileprivate static func qtcConvert(_ qtcEquation: QTcEquation,
                                       qtInMsec: Double, rate: Double, sex: Sex, age: Age) throws -> Msec {
        return secToMsec(try qtcEquation(msecToSec(qtInMsec), bpmToSec(rate), sex, age))
    }
   
    // QTp conversion
    fileprivate static func qtpConvert(_ qtpEquation: QTpEquation, rrInMsec: Double, sex: Sex, age: Age) throws -> Msec {
        return secToMsec(try qtpEquation(msecToSec(rrInMsec), sex, age))
    }
    
    fileprivate static func qtpConvert(_ qtpEquation: QTpEquation, rate: Double, sex: Sex, age: Age) throws -> Sec {
        return try qtpEquation(bpmToSec(rate), sex, age)
    }
}

