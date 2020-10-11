//
//  AbnormalQTc.swift
//  QTc
//
//  Created by David Mann on 4/13/18.
//  Copyright © 2018 EP Studios. All rights reserved.
//

import Foundation

/// These are tests for abnormal QTc values from the literature.
public enum Criterion: String {
    case schwartz1985 = "schwartz1985"
    case schwartz1993 = "schwartz1993"
    case fda2005 = "fda2005"
    case esc2005 = "esc2005"
    case goldenberg2006 = "goldenberg2006"
    case aha2009 = "aha2009"
    case gollob2011 = "gollob2011"
    case mazzanti2014 = "mazzanti2014"
}

/// Comparison operators to test QTc against literature Criterion.
/// Example: if Comparison.greaterThan, then QTc greater than the value is abnormal
public enum Comparison {
    case greaterThan
    case greaterThanOrEqual
    case lessThan
    case lessThanOrEqual
}

// TODO: Consider refactor name of Severity to Interpretation.
/// Different levels of Severity in the interpretation of the QTc/p interval
public struct Severity: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    public static let undefined = Severity([])
    public static let normal = Severity(rawValue: 1)
    public static let borderline = Severity(rawValue: 2)
    public static let abnormal = Severity(rawValue: 4)
    public static let mild = Severity(rawValue: 8)
    public static let moderate = Severity(rawValue: 16)
    public static let severe = Severity(rawValue: 32)
    public static let error = Severity(rawValue: 64)
    
    public func isAbnormal() -> Bool {
        return self.rawValue >= Severity.abnormal.rawValue
    }
}

/// A struct in which to wrap a QTc measurement so it can be interpreted.
public struct QTcMeasurement {
    let qtc: Double
    let units: Units
    let sex: Sex
    let age: Int?

    /**
     Create a QTcMeasurement that can be evaluated as normal or abnormal.

     - Parameters:
         - qtc: the calculated QTc
         - units: units of the QTc, msec or sec
         - sex: subject's sex.  Defaults to Sex.unspecified
         - age: subject's age.  Defaults to nil.
     */
    public init(qtc: Double, units: Units, sex: Sex = .unspecified, age: Int? = nil) {
        self.qtc = qtc
        self.units = units
        self.sex = sex
        self.age = age
    }
    
    /**
     Create a QTcMeasurement to be evaluated as normal or abnormal,
     retrieving subject parameters from a QtMeasurement struct.

     - Parameters:
         - qtc: the calculated QTc
         - qtMeasurement: a QtMeasurement struct used to generate the QTc.
     */
    public init(qtc: Double, qtMeasurement: QtMeasurement) {
        self.qtc = qtc
        self.units = qtMeasurement.units
        self.sex = qtMeasurement.sex
        self.age = qtMeasurement.age
    }
}

public typealias QTcTests = [QTcTest]
public typealias Cutoff = (value: Double, severity: Severity)
public typealias Cutoffs = [Cutoff]

/**
 QTcTest describes a test for an abnormal QTc value,

 Example, if a QTc > 470 msec in women is considered abnormal:

     let test = QTcTest(value: 470, units: .msec, sex: .female, valueLimitType: .upper, valueIntervalType: .open)
 */
public struct QTcTest {
    let value: Double
    let units: Units
    let valueComparison: Comparison
    let sex: Sex  // may be unspecified
    let age: Int?  // age cutoff is optional
    let ageComparison: Comparison
    public let severity: Severity
    
    /// Create a QTcTest
    ///
    /// - Parameters:
    ///   - value: the cutoff value for this QTcTest
    ///   - units: .msec or .sec
    ///   - valueComparison: the comparison operator that the cutoff value uses
    ///   - sex: if test is sex-specific, which sex?  Otherwise default is .unspecified.
    ///   - age: if test is age-specific what is cutoff age?  Default is nil.
    ///   - ageComparison: if test is age-specific, what comparison operator is used?
    ///   - severity: the severity value if the test is failed
    public init(value: Double, units: Units, valueComparison: Comparison, sex: Sex = .unspecified, age: Int? = nil, ageComparison: Comparison = .lessThan, severity: Severity = .abnormal) {
        self.value = value
        self.units = units
        self.valueComparison = valueComparison
        self.sex = sex
        self.age = age
        self.ageComparison = ageComparison
        self.severity = severity
    }
    
    /// Test a QTcMeasurement to see if it passes or fails this QTcTest.
    ///
    /// - Parameter qtcMeasurement: the QTcMeasurement to be tested
    /// - Returns: true if QTcMeasurement fails test, i.e. is abnormal
    func isAbnormal(qtcMeasurement: QTcMeasurement) -> Bool {
        var qtcValue = qtcMeasurement.qtc
        if units != qtcMeasurement.units {
            // Happily, this switch statement says what it does!
            switch units {
            case .sec:
                qtcValue = QTc.msecToSec(qtcValue)
            case .msec:
                qtcValue = QTc.secToMsec(qtcValue)
            }
        }
        var result = false
        // test sex
        if sex == .male || sex == .female {
            if sex != qtcMeasurement.sex {
                return result
            }
        }
        // test age -- it's complicated
        if let age = age {
            guard let measuredAge = qtcMeasurement.age else { return result }
            switch ageComparison {
            case .lessThan:
                if age < measuredAge { return result }
            case .lessThanOrEqual:
                if age <= measuredAge { return result }
            case .greaterThan:
                if age > measuredAge { return result }
            case .greaterThanOrEqual:
                if age >= measuredAge { return result }
            }
        }
        // At this point qtcMeasurement fits criteria to actually make the comparison
        switch valueComparison {
        case .greaterThan:
            if qtcValue > value { result = true }
        case .greaterThanOrEqual:
            if qtcValue >= value { result = true }
        case .lessThan:
            if qtcValue < value { result = true }
        case .lessThanOrEqual:
            if qtcValue <= value { result = true }
        }
        return result
    }
    
    /// Get the Cutoff for this test in the requested Units
    ///
    /// - Parameter units: desired Units for Cutoff
    /// - Returns: the Cutoff with value adjusted for Units
    func cutoff(units: Units) -> Cutoff {
        if units == self.units {
            return (value, severity)
        }
        else {
            switch(units) {
            case .msec:
                return (1000.0 * value, severity)
            case .sec:
                return (value / 1000.0, severity)
            }
        }
    }
}

/// Wrapper for a set of QTcTests, based on a literature reference
public struct QTcTestSuite {
    public let name: String
    let qtcTests: QTcTests
    public let requiresSex: Bool
    public let requiresAge: Bool
    public let reference: String
    public let description: String // the test described in prose
    let notes: String?  // optional notes about this test suite
    
    /// Create a QTcTestSuite from a literature reference
    ///
    /// - Parameters:
    ///   - name: short name for this suite. e.g. "Schwartz 1985"
    ///   - qtcTests: an array of QTcTests that the suite uses
    ///   - reference: reference in AMA format
    ///   - description: a description of the test suite
    ///   - notes: further notes on the the test suite
    ///   - requiresSex: test suite requires sex to be known
    ///   - requiresAge: test suite requires age to be known
    public init(name: String, qtcTests: QTcTests, reference: String, description: String, notes: String? = nil,
                requiresSex: Bool = false, requiresAge: Bool = false) {
        self.name = name
        self.qtcTests = qtcTests
        self.reference = reference
        self.description = description
        self.notes = notes
        self.requiresSex = requiresSex
        self.requiresAge = requiresAge
    }
    
    /// Test whether a QTcMeasurement has all the requirements for this test suite
    ///
    /// - Parameter qtcMeasurement: the QTcMeasurement
    /// - Returns: true if the results of the test suite will be undefined
    public func isUndefined(qtcMeasurement: QTcMeasurement) -> Bool {
        let missingSex = requiresSex && qtcMeasurement.sex == .unspecified
        let missingAge = requiresAge && qtcMeasurement.age == nil
        return missingAge || missingSex
    }
    
    // Returns an array of abnormal tests
    func abnormalQTcTests(qtcMeasurement: QTcMeasurement) -> [QTcTest] {
        var abnormalTests: [QTcTest] = []
        for qtcTest in qtcTests {
            if qtcTest.isAbnormal(qtcMeasurement: qtcMeasurement) {
                abnormalTests.append(qtcTest)
            }
        }
        return abnormalTests
    }

    // If more than one QTcTest fails, we need to know which gives the
    // result with the highest Severity.
    func mostSevereFailure(failingTests: [QTcTest]) -> QTcTest? {
        if failingTests.count < 1 { return nil }
        if failingTests.count == 1 { return failingTests[0] }
        var mostSevereResult: QTcTest?
        var severity: Severity = .normal
        for test in failingTests {
            if UInt8(test.severity.rawValue) > UInt8(severity.rawValue) {
                severity = test.severity
                mostSevereResult = test
            }
        }
        return mostSevereResult
    }

    // Return the QTcTest that was failed with the highest Severity
    func failingTest(measurement: QTcMeasurement) -> QTcTest? {
        return mostSevereFailure(failingTests: abnormalQTcTests(qtcMeasurement: measurement))
    }
    
    /// Run a QTcMeasurement through the test suite and get the Severity
    ///
    /// - Parameter measurement: the QTcMeasurement to be tested
    /// - Returns: the Severity returned by the test suite
    public func severity(measurement: QTcMeasurement) -> Severity {
        if isUndefined(qtcMeasurement: measurement) {
            return .undefined
        }
        let result = failingTest(measurement: measurement)
        if let result = result {
            return result.severity
        }
        else {
            return .normal
        }
    }
    
    /// Get an array of Cutoffs in appropriate units for this test suite
    ///
    /// - Parameter units: the Units for the Cutoffs, .msec or .sec
    /// - Returns: an array of Cutoffs in the appropriate Units
    public func cutoffs(units: Units) -> Cutoffs {
        var cutoffs: Cutoffs = []
        for test in qtcTests {
            cutoffs.append(test.cutoff(units: units))
        }
        return cutoffs
    }
    
}

/// Provides dictionary of QTcTestSuites
public struct AbnormalQTc {
    static let testSuiteDictionary: [Criterion: QTcTestSuite] =
        [.schwartz1985:
            QTcTestSuite(
                name: "Schwartz 1985",
                qtcTests: [QTcTest(value: 440, units: .msec, valueComparison: .greaterThan)],
                reference: "Schwartz PJ. Idiopathic long QT syndrome: Progress and questions. American Heart Journal. 1985;109(2):399-411. doi:10.1016/0002-8703(85)90626-X",
                description: "QTc > 440 msec",
                notes: "Simple but outdated criterion, from long QT syndrome data.  Overdiagnoses long QTc and no reckoning of sex difference in QT duration."),
         .fda2005:
            QTcTestSuite(
                name: "FDA 2005",
                qtcTests: [
                    QTcTest(value: 450, units: .msec, valueComparison: .greaterThan, severity: .mild),
                    QTcTest(value: 480, units: .msec, valueComparison: .greaterThan, severity: .moderate),
                    QTcTest(value: 500, units: .msec, valueComparison: .greaterThan, severity: .severe)],
                reference: "Guidance for Industry E14 Clinical Evaluation of QT/QTc Interval Prolongation and Proarrhythmic Potential for Non-Antiarrhythmic Drugs. :20.",
                description: """
                                QTc > 450 msec mild prolongation
                                QTc > 480 msec moderate prolongation
                                QTc > 500 msec severe prolongation
                                """,
                notes: "Used in FDA trials."),
         .aha2009:
            QTcTestSuite(
                name: "AHA 2009",
                qtcTests: [
                    QTcTest(value: 450, units: .msec, valueComparison: .greaterThanOrEqual, sex: .male),
                    QTcTest(value: 460, units: .msec, valueComparison: .greaterThanOrEqual, sex: .female),
                    QTcTest(value: 390, units: .msec, valueComparison: .lessThanOrEqual)],
                reference: "AHA/ACCF/HRS Recommendations for the Standardization and Interpretation of the Electrocardiogram: Part IV: The ST Segment, T and U Waves, and the QT Interval A Scientific Statement From the American Heart Association Electrocardiography and Arrhythmias Committee, Council on Clinical Cardiology; the American College of Cardiology Foundation; and the Heart Rhythm Society Endorsed by the International Society for Computerized Electrocardiology. Journal of the American College of Cardiology. 2009;53(11):982-991. doi:10.1016/j.jacc.2008.12.014",
                description: """
                                QTc ≥ 450 msec men
                                QTc ≥ 460 msec women
                                QTc ≤ 390 msec men and women
                                """,
                notes: "Includes both long and short QTc criteria.",
                requiresSex: true),
         .esc2005:
            QTcTestSuite(
                name: "ESC 2005",
                qtcTests: [
                    QTcTest(value: 440, units: .msec, valueComparison: .greaterThan, sex: .male),
                    QTcTest(value: 460, units: .msec, valueComparison: .greaterThan, sex: .female),
                    // include below when sex unspecified
                    QTcTest(value: 460, units: .msec, valueComparison: .greaterThan),
                    QTcTest(value: 300, units: .msec, valueComparison: .lessThan)],
                reference: "Corrado D, Pelliccia A, Bjørnstad HH, et al. Cardiovascular pre-participation screening of young competitive athletes for prevention of sudden death: proposal for a common European protocolConsensus Statement of the Study Group of Sport Cardiology of the Working Group of Cardiac Rehabilitation and Exercise Physiology and the Working Group of Myocardial and Pericardial Diseases of the European Society of Cardiology. Eur Heart J. 2005;26(5):516-524. doi:10.1093/eurheartj/ehi108",
                description: """
                                QTc > 440 msec men
                                QTc > 460 msec women
                                QTc < 300 msec men and women
                                """,
                notes: "Includes both long and short QTc criteria.",
                requiresSex: true),
         .goldenberg2006:
            QTcTestSuite(
                name: "Goldenberg 2006",
                qtcTests: [
                    QTcTest(value: 440, units: .msec, valueComparison: .greaterThanOrEqual, age: 15, ageComparison: .lessThanOrEqual, severity: .borderline),
                    QTcTest(value: 460, units: .msec, valueComparison: .greaterThan, age: 15, ageComparison: .lessThanOrEqual, severity: .abnormal),
                    QTcTest(value: 430, units: .msec, valueComparison: .greaterThanOrEqual, sex: .male, age: 15, ageComparison: .greaterThan, severity: .borderline),
                    QTcTest(value: 450, units: .msec, valueComparison: .greaterThan, sex: .male, age: 15, ageComparison: .greaterThan, severity: .abnormal),
                    QTcTest(value: 450, units: .msec, valueComparison: .greaterThanOrEqual, sex: .female, age: 15, ageComparison: .greaterThan, severity: .borderline),
                    QTcTest(value: 470, units: .msec, valueComparison: .greaterThan, sex: .female, age: 15, ageComparison: .greaterThan, severity: .abnormal)],
                reference: "Goldenberg Ilan, Moss Arthur J., Zareba Wojciech. QT Interval: How to Measure It and What Is \"Normal.\" Journal of Cardiovascular Electrophysiology. 2006;17(3):333-336. doi:10.1111/j.1540-8167.2006.00408.x",
                description: "Age 1-15 (M/F): borderline QTc 440-460 msec, abnormal QTc > 460 msec\nAge > 15 (M): borderline QTc 430-450 msec, abnormal > QTc 450 msec\nAge > 15 (F): borderline QTc 450-470 msec, abnormal QTc > 470 msec",
                notes: "Based on 581 healthy subjects: 158 children, 423 adults: 223 men, 200 women.  Used QTcBZT.",
                requiresSex: true,
                requiresAge: true),
         .schwartz1993:
            QTcTestSuite(
                name: "Schwartz 1993",
                qtcTests: [
                    QTcTest(value: 450, units: .msec, valueComparison: .greaterThanOrEqual, sex: .male, severity: .mild),
                    QTcTest(value: 460, units: .msec, valueComparison: .greaterThanOrEqual, severity: .moderate),
                    QTcTest(value: 480, units: .msec, valueComparison: .greaterThanOrEqual, severity: .severe)
                ],
                reference: "Schwartz PJ, Moss AJ, Vincent GM, Crampton RS. Diagnostic criteria for the long QT syndrome. An update. Circulation. 1993;88(2):782-784. doi:10.1161/01.CIR.88.2.782",
                description: """
                                QTc ≥ 450 msec (in males) mild (1 point)
                                QTc ≥ 460 msec moderate (2 points)
                                QTc ≥ 480 msec severe (3 points)
                                """,
                notes: "Revision of original Schwartz 1985 criteria.  Used in point system of 1993 LQTS Diagnostic criteria.",
                requiresSex: true,
                requiresAge: false),
         .gollob2011:
            QTcTestSuite(
                name: "Gollob 2011",
                qtcTests: [
                    QTcTest(value: 370, units: .msec, valueComparison: .lessThan, severity: .mild),
                    QTcTest(value: 350, units: .msec, valueComparison: .lessThan, severity: .moderate),
                    QTcTest(value: 330, units: .msec, valueComparison: .lessThan, severity: .severe)
                ],
                reference: "Gollob MH, Redpath CJ, Roberts JD. The Short QT Syndrome. Journal of the American College of Cardiology. 2011;57(7):802-812. doi:10.1016/j.jacc.2010.09.048",
                description: "QTc < 370 msec mild (1 point)\nQTc < 350 msec moderate (2 points)\nQTc < 330 msec severe (3 points)",
                notes:  "Based on 61 reported cases of Short QT Syndrome.  Used in point system for SQTS."),
         .mazzanti2014:
            QTcTestSuite(
                name: "Mazzanti 2014",
                qtcTests: [
                    QTcTest(value: 360, units: .msec, valueComparison: .lessThanOrEqual, severity: .borderline),
                    QTcTest(value: 340, units: .msec, valueComparison: .lessThanOrEqual, severity: .abnormal)
                ],
                reference: "Mazzanti A, Kanthan A, Monteforte N, et al. Novel Insight Into the Natural History of Short QT Syndrome. Journal of the American College of Cardiology. 2014;63(13):1300-1308. doi:10.1016/j.jacc.2013.09.078",
                description: """
                                QTc ≤ 360 msec borderline
                                QTc ≤ 340 msec abnormal
                                """,
                notes: "Based on 63 cases of suspected SQTS.")
    ]
    
    /// Returns a QTcTestSuite based on a test Criterion
    ///
    /// - Parameter criterion: the Criterion for the test suite
    /// - Returns: the QTcTestSuite for the Criterion, nil if not found
    public static func qtcTestSuite(criterion: Criterion) -> QTcTestSuite? {
        return testSuiteDictionary[criterion]
    }
    
}
