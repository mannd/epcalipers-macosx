//
//  Formulas.swift
//  Formulas
//
//  Created by David Mann on 9/18/17.
//  Copyright © 2017, 2018 EP Studios. All rights reserved.
//

import Foundation

/// Source for all QTc and QTp formulas
struct Formulas: QTcFormulaSource, QTpFormulaSource {
    
    static let errorMessage = "Formula not found!"
    
    // These functions are required by the protocols used by this class
    static func qtcCalculator(formula: Formula) -> QTcCalculator {
        guard let calculator = qtcDictionary[formula] else {
            fatalError(errorMessage)
        }
        return calculator
    }
    
    static func qtpCalculator(formula: Formula) -> QTpCalculator {
        guard let calculator = qtpDictionary[formula] else {
            fatalError(errorMessage)
        }
        return calculator
    }
    
    // Power QTc formula function
    // These have form QTc = QT / pow(RR, exp)
    private static func qtcExp(qtInSec: Double, rrInSec: Double, exp: Double) -> Sec {
        return qtInSec / pow(rrInSec, exp)
    }
    
    // Linear QTc formula function
    // These have form QTc = QT + α(1 - RR)
    private static func qtcLinear(qtInSec: Double, rrInSec: Double, alpha: Double) -> Sec {
        return qtInSec + alpha * (1 - rrInSec)
    }

    private static func qtpLinear(rrInSec: Double, alpha: Double, k: Double) -> Sec {
        return k + alpha * rrInSec
    }
    
    // Some complex formulae easier to present here than as closure
    private static func qtcAdm(qtInSec: Double, rrInSec: Double, sex: Sex, age: Age) -> Sec {
        let alpha: Double
        switch sex {
        case .unspecified:
            alpha = 0.1464
        case .male:
            alpha = 0.1536
        case .female:
            alpha = 0.1259
        }
        return qtcLinear(qtInSec: qtInSec, rrInSec: rrInSec, alpha: alpha)
    }
    
    private static func qtpAdm(rrInSec: Double, sex: Sex, age: Age) -> Sec {
        let alpha: Double
        let k: Double
        switch sex {
        case .unspecified:
            alpha = 0.1464
            k = 0.2572
        case .male:
            alpha = 0.1536
            k = 0.2462
        case .female:
            alpha = 0.1259
            k = 0.2789
        }
        return qtpLinear(rrInSec: rrInSec, alpha: alpha, k: k)
    }

    private static func qtpAsh(rrInSec: Double, sex: Sex, age: Age) throws -> Sec {
        // TODO: This formula has gaps in the paper's abstract, need full text of reference!
        // These gaps are "papered over" here.
        guard let age = age else { throw CalculationError.ageRequired }
        guard sex != .unspecified else { throw CalculationError.sexRequired }
        let k = 0.07
        var K: Double = 0
        if age < 15 {
            K = 0.375
        }
        else if sex == .male {
            if age < 33 {
                K = 0.373
            }
            else {
                K = 0.380
            }
        }
        else {  // female
            if age < 33 {
                K = 0.385
            }
            else if age < 45 {
                K = 0.388
            }
            else {
                K = 0.390
            }
        }
        return K * log10(10 * (rrInSec + k))
    }
    
    // This reference is extracted because it is used for two different QTc formulas
    static let rautaharju2014Reference = "Rautaharju PM, Mason JW, Akiyama T. New age- and sex-specific criteria for QT prolongation based on rate correction formulas that minimize bias at the upper normal limits. International Journal of Cardiology. 2014;174(3):535-540. doi:10.1016/j.ijcard.2014.04.133"
    static let rautaharju2014NumberOfSubjects = 57_595
    static let rautaharju2014Notes = "Healthy subjects: 57,595, aged 5-89 years, 54% women."

    // This is the data source for the formulas.  Potentially this could be a database, but there
    // aren't that many formulas, so for now the formulas are inlined here.
    static let qtcDictionary: [Formula: QTcCalculator] =
        [.qtcBzt:
            QTcCalculator(formula: .qtcBzt,
                          longName: "Bazett",
                          shortName: "QTcBZT",
                          reference: """
                                        original: Bazett HC. An analysis of the time-relations of electrocardiograms. Heart 1920;7:353–370.
                                        reprint: Bazett H. C. An analysis of the time‐relations of electrocardiograms. Annals of Noninvasive Electrocardiology. 2006;2(2):177-194. doi:10.1111/j.1542-474X.1997.tb00325.x
                                        """,
                          equation: "QT/\u{221A}RR",
                          baseEquation: {qtInSec, rrInSec, _, _ in qtcExp(qtInSec: qtInSec, rrInSec: rrInSec, exp: 0.5)},
                          classification: .power,
                          notes: "Oldest, most commonly used formula, but inaccurate at extremes of heart rate.  Healthy subjects: 20 men, age 14 - 40 (including one with age labeled \"Boy\"), 19 women, age 20 - 53.  Majority of subjects in their 20s.",
                          publicationDate: "1920",
                          numberOfSubjects: 39),
         .qtcFrd:
            QTcCalculator(formula: .qtcFrd,
                          longName: "Fridericia",
                          shortName: "QTcFRD",
                          reference: "Fridericia LS. Die Systolendauer im Elektrokardiogramm bei normalen Menschen und bei Herzkranken. Acta Medica Scandinavica. 1920;53(1):469-486. doi:10.1111/j.0954-6820.1920.tb18266.x",
                          equation: "QT/\u{221B}RR",
                          baseEquation: {qtInSec, rrInSec, _, _ in qtcExp(qtInSec: qtInSec, rrInSec: rrInSec, exp: 1 / 3.0)},
                          classification: .power,
                          notes: "50 normal subjects, 28 men, 22 women, ages 2 to 81, most (35) age 20 to 40.  HR range 51-135.",
                          publicationDate: "1920",
                          numberOfSubjects: 50),
         .qtcMyd:
            QTcCalculator(formula: .qtcMyd,
                          longName: "Mayeda",
                          shortName: "QTcMYD",
                          reference: "Mayeda I. On time relation between systolic duration of heart and pulse rate. Acta Scholae Med Univ Imp Kioto. 1934;17:53-55.",
                          equation: "QT/RR^0.604",
                          baseEquation: {qtInSec, rrInSec, _, _ in qtcExp(qtInSec: qtInSec, rrInSec: rrInSec, exp: 0.604)},
                          classification: .power,
                          notes: "200 normal subjects and patients without heart disease (135 M, 65 F; age 18-64; HR 54.5-115.8).",
                          publicationDate: "1934",
                          numberOfSubjects: 200),
         .qtcFrm:
            QTcCalculator(formula: .qtcFrm,
                          longName: "Framingham",
                          shortName: "QTcFRM",
                          reference: "Sagie A, Larson MG, Goldberg RJ, Bengtson JR, Levy D. An improved method for adjusting the QT interval for heart rate (the Framingham Heart Study). American Journal of Cardiology. 1992;70(7):797-801. doi:10.1016/0002-9149(92)90562-D",
                          equation: "QT + 0.154*(1-RR)",
                          baseEquation: {qtInSec, rrInSec, _, _ in qtcLinear(qtInSec: qtInSec, rrInSec: rrInSec, alpha: 0.154)},
                          classification: .linear,
                          notes: "5,018 subjects, 2,239 men and 2,779 women, from Framingham Heart Study.  Mean age 44 years (28-62). CAD, subjects on AADs or tricyclics or with extremes of HR excluded.",
                          publicationDate: "1992",
                          numberOfSubjects: 5018),
         .qtcHdg:
            QTcCalculator(formula: .qtcHdg,
                          longName: "Hodges",
                          shortName: "QTcHDG",
                          reference: "Hodges M, Salerno D, Erlien D. Bazett’s QT correction reviewed: Evidence that a linear QT correction for heart rate is better. J Am Coll Cardiol. 1983;1:1983.",
                          equation: "QT + 1.75*(HR-60)",
                          baseEquation: {qtInSec, rrInSec, _, _ in qtInSec + 0.00175 * (QTc.secToBpm(rrInSec) - 60)},
                          classification: .rational,
                          notes: "607 normal subjects, 303 men, 304 women, ages from 20s to 80s.",
                          publicationDate: "1983",
                          numberOfSubjects: 607),
         .qtcRtha:
            QTcCalculator(formula: .qtcRtha,
                          longName: "Rautaharju-a",
                          shortName: "QTcRTHa",
                          reference: rautaharju2014Reference,
                          equation: "QT * (120 + HR) / 180",
                          baseEquation: {qtInSec, rrInSec, _, _ in qtInSec * (120.0 + QTc.secToBpm(rrInSec)) / 180.0},
                          classification: .rational,
                          notes: rautaharju2014Notes,
                          publicationDate: "2014",
                          numberOfSubjects: rautaharju2014NumberOfSubjects),
         .qtcRthb:
            QTcCalculator(formula: .qtcRthb,
                          longName: "Rautaharju-b",
                          shortName: "QTcRTHb",
                          reference: rautaharju2014Reference,
                          equation: """
                                    QT + 387 * (1 - RR^0.37) for men
                                    QT + 409 * (1 - RR^0.39) for women
                                    RR in sec, QT and result in msec
                                    """,
                          baseEquation: {qtInSec, rrInSec, sex, _ in
                            let C: Double
                            let k: Double
                            switch(sex) {
                            case .male:
                                C = 387.0
                                k = 0.37
                            case .female:
                                C = 409.0
                                k = 0.39
                            case .unspecified:
                                throw CalculationError.sexRequired
                            }
                            return QTc.msecToSec(QTc.secToMsec(qtInSec) + C * (1 - pow(rrInSec, k)))},
                          classification: .power,
                          notes: rautaharju2014Notes,
                          publicationDate: "2014",
                          numberOfSubjects: rautaharju2014NumberOfSubjects),
         .qtcArr:
            QTcCalculator(formula: .qtcArr,
                          longName: "Arrowood",
                          shortName: "QTcARR",
                          reference: "Arrowood JA, Kline J, Simpson PM, et al. Modulation of the QT interval: effects of graded exercise and reflex cardiovascular stimulation. Journal of Applied Physiology. 1993;75(5):2217-2223. doi:10.1152/jappl.1993.75.5.2217",
                          equation: "QT + 0.304 - 0.492*e^(-0.008*HR)",
                          baseEquation: {qtInSec, rrInSec, _, _ in qtInSec + 0.304 - 0.492 * exp(-0.008 * QTc.secToBpm(rrInSec))},
                          classification: .exponential,
                          notes: "16 normal volunteers, age 21-62.  M/F ratio not given.  ECGs at rest and with exercise.",
                          publicationDate: "1993",
                          numberOfSubjects: 16),
         .qtcKwt:
            QTcCalculator(formula: .qtcKwt,
                          longName: "Kawataki",
                          shortName: "QTcKWT",
                          reference: "Kawataki M, Kashima T, Toda H, Tanaka H. Relation between QT interval and heart rate. applications and limitations of Bazett’s formula. J Electrocardiol. 1984;17(4):371-375. doi:10.1016/S0022-0736%2884%2980074-6",
                          equation: "QT/RR^0.25",
                          baseEquation: {qtInSec, rrInSec, _, _ in qtcExp(qtInSec: qtInSec, rrInSec: rrInSec, exp: 0.25)},
                          classification: .power,
                          notes: "9 healthy men, age 18-71",
                          publicationDate: "1984",
                          numberOfSubjects: 9),
         .qtcDmt:
            QTcCalculator(formula: .qtcDmt,
                          longName: "Dimitrienko",
                          shortName: "QTcDMT",
                          reference: "Dmitrienko AA, Sides GD, Winters KJ, et al. Electrocardiogram Reference Ranges Derived from a Standardized Clinical Trial Population. Drug Information Journal. 2005;39(4):395-405. doi:10.1177/009286150503900408",
                          // Note that the QTcDMT in Rabkin appears to use a formula with a typo: the exponent he uses in 0.473 rather than 0.413.  The exponent from the paper is clearly 0.413.
                          equation: "QT/RR^0.413",
                          baseEquation: {qtInSec, rrInSec, _, _ in qtcExp(qtInSec: qtInSec, rrInSec: rrInSec, exp: 0.413)},
                          classification: .power,
                          notes: "Healthy subjects: 13,039, aged 4-99 years, 51% women.",
                          publicationDate: "2005",
                          numberOfSubjects: 13_039),
         .qtcYos:
            QTcCalculator(formula: .qtcYos,
                          longName: "Yoshinaga",
                          shortName: "QTcYOS",
                          reference: "Yoshinaga M, Tomari T, Aihoshi S, et al. Exponential correction of QT interval to minimize the effect of the heart rate in children. Japanese Circulation Journal. 1993;57(2):102-108. doi:10.1253/jcj.57.102",
                          equation: "QT/RR^0.31",
                          baseEquation: {qtInSec, rrInSec, _, age in
                            guard let age = age else { throw CalculationError.ageRequired }
                            // We assume results apply to all pediatric population, though only ages 6 and 12 included
                            guard age <= 18 else { throw CalculationError.ageOutOfRange }
                            return qtcExp(qtInSec: qtInSec, rrInSec: rrInSec, exp: 0.31)},
                          classification: .power,
                          notes: "12,543 healthy children, ages 6-12.",
                          publicationDate: "1993",
                          numberOfSubjects: 12_543),
         .qtcAdm:
            QTcCalculator(formula: .qtcAdm,
                          longName: "Adams",
                          shortName: "QTcADM",
                          reference: "Adams W. The normal duration of the electrocardiographic ventricular complex. J Clin Invest. 1936;15(4):335-342.  doi:10.1172%2FJCI100784",
                          equation: """
                                    QT + 0.1464(1-RR) (all subjects)
                                    QT + 0.1536(1-RR) (males)
                                    QT + 0.1259(1-RR) (females)
                                    """,
                          baseEquation: qtcAdm,
                          classification: .linear,
                          notes: "104 healthy subjects, 50 men, 54 women, mean age 28.",
                          publicationDate: "1936",
                          numberOfSubjects: 104),
         .qtcGot:
            QTcCalculator(formula: .qtcGot,
                          longName: "Goto",
                          shortName: "QTcGOT",
                          reference: "Goto H, Mamorita N, Ikeda N, Miyahara H. Estimation of the upper limit of the reference value of the QT interval in rest electrocardiograms in healthy young Japanese men using the bootstrap method. J Electrocardiol. 2008;41(6):703.e1-10. doi:10.1016/j.jelectrocard.2008.08.001",
                          equation: "QT/RR^0.3409",
                          baseEquation: {qtInSec, rrInSec, _, _ in qtcExp(qtInSec: qtInSec, rrInSec: rrInSec, exp: 0.3409)},
                          classification: .power,
                          notes: "1276 healthy men, age 20-35.",
                          publicationDate: "2008",
                          numberOfSubjects: 1276),
         .qtcRbk:
            QTcCalculator(formula: .qtcRbk,
                          longName: "Rabkin",
                          shortName: "QTcRBK",
                          reference: "Rabkin SW, Szefer E, Thompson DJS. A New QT Interval Correction Formulae to Adjust for Increases in Heart Rate. JACC: Clinical Electrophysiology. 2017;3(7):756-766. doi:10.1016/j.jacep.2016.12.005",
                          equation: "Spline equation, see reference",
                          baseEquation: {qtInSec, rrInSec, sex, age in
                            // check for lack of sex and throw
                            guard sex != .unspecified else {
                                throw CalculationError.sexRequired
                            }
                            if let age = age {
                                return QTc.msecToSec(QtcRbk.qtcRbk(qt: QTc.secToMsec(qtInSec), hr: QTc.secToBpm(rrInSec), isFemale: sex == .female ? true : false, age: Double(age)))
                            }
                            else {
                                return QTc.msecToSec(QtcRbk.qtcRbk(qt: QTc.secToMsec(qtInSec), hr: QTc.secToBpm(rrInSec), isFemale: sex == .female ? true : false))
                            }},
                          classification: .other,
                          notes: "13,627 ECGs with rates 40-120 from NHANES database.",
                          publicationDate: "2017",
                          numberOfSubjects: 13627),
         // Add new equations above
         .qtcTest:
            QTcCalculator(formula: .qtcTest,
                          longName: "Test",
                          shortName: "QTcTEST",
                          reference: "TBD",
                          equation: "uses sex",
                          baseEquation: {qtInSec, rrInSec, _, _ in qtInSec + rrInSec},
                          classification: .power,
                          notes: "Children",
                          publicationDate: "1800")
    ]
    
    // We avoid duplicate fields in the QTp formulas by reusing some of the QTc equivalent fields
    static let qtpDictionary: [Formula: QTpCalculator] =
        [.qtpBzt:
            QTpCalculator(formula: .qtpBzt,
                          longName: QTc.qtcCalculator(formula: .qtcBzt).longName,
                          shortName: "QTpBZT",
                          reference: QTc.qtcCalculator(formula: .qtcBzt).reference,
                          equation: "K * \u{221A}RR | where K = 0.37 for men and 0.40 for women",
                          baseEquation: { rrInSec,sex, _  in
                            let k: Double
                            switch(sex) {
                            case .male:
                                k = 0.37
                            case .female:
                                k = 0.4
                            case .unspecified:
                                throw CalculationError.sexRequired
                            }
                            return k * pow(rrInSec, 0.5) },
                          classification: QTc.qtcCalculator(formula: .qtcBzt).classification,
                          notes: QTc.qtcCalculator(formula: .qtcBzt).notes,
                          publicationDate: QTc.qtcCalculator(formula: .qtcBzt).publicationDate,
                          numberOfSubjects: QTc.qtcCalculator(formula: .qtcBzt).numberOfSubjects),
         .qtpArr:
            QTpCalculator(formula: .qtpArr,
                          longName: QTc.qtcCalculator(formula: .qtcArr).longName,
                          shortName: "QTpARR",
                          reference: QTc.qtcCalculator(formula: .qtcArr).reference,
                          equation: "0.116 + 0.492e^(-0.008*HR)",
                          baseEquation: {rrInSec, _, _  in 0.116 + 0.492 * exp(-0.008 * QTc.secToBpm(rrInSec))},
                          classification: QTc.qtcCalculator(formula: .qtcArr).classification,
                          notes: "16 normal volunteers, age 21-62.  M/F ration not given.  ECGs at rest and with exercise.",
                          publicationDate: QTc.qtcCalculator(formula: .qtcArr).publicationDate,
                          numberOfSubjects: QTc.qtcCalculator(formula: .qtcArr).numberOfSubjects),
         .qtpBdl:
            QTpCalculator(formula: .qtpBdl,
                          longName: "Boudoulas",
                          shortName: "QTpBDL",
                          reference: "Boudoulas H, Geleris P, Lewis RP, Rittgers SE. Linear Relationship Between Electrical Systole, Mechanical Systole, and Heart Rate. CHEST. 1981;80(5):613-617. doi:10.1378/chest.80.5.613",
                          equation: """
                                    men: 521 - 2.0*HR
                                    women: 511 - 1.8*HR
                                    result in msec
                                    """,
                          baseEquation: {rrInSec, sex, _  in sex == .male ? QTc.msecToSec(521.0 - 2.0 * QTc.secToBpm(rrInSec)) : QTc.msecToSec(511.0 - 1.8 * QTc.secToBpm(rrInSec))},
                          classification: .rational,
                          notes: "200 patients without cardiovascular disease, 100 men, 100 women.",
                          publicationDate: "1981",
                          numberOfSubjects: 200),
         .qtpAsh:
            QTpCalculator(formula: .qtpAsh,
                          longName: "Ashman",
                          shortName: "QTpASH",
                          reference: "Ashman R. The normal duration of the Q-T interval. American Heart Journal. 1942;23(4):522-534. doi:10.1016/S0002-8703(42)90297-7",
                          equation: "K log[10(RR + 0.07)] | K sex and age dependent",
                          baseEquation: qtpAsh,
                          classification: .logarithmic,
                          notes: "1,083 subjects, 432 men, 425 women, 226 children (up to 14 years).  Normal subjects, or patients without evidence of heart disease.",
                          publicationDate: "1942",
                          numberOfSubjects: 1083),
         .qtpHdg:
            QTpCalculator(formula: .qtpHdg,
                          longName: QTc.qtcCalculator(formula: .qtcHdg).longName,
                          shortName: "QTpHDG",
                          reference: QTc.qtcCalculator(formula: .qtcHdg).reference,
                          equation: "496 - (1.75 * HR) | result in msec",
                          baseEquation: {rrInSec, _, _ in QTc.msecToSec(496 - (1.75 * QTc.secToBpm(rrInSec)))},
                          classification: QTc.qtcCalculator(formula: .qtcHdg).classification,
                          notes: QTc.qtcCalculator(formula: .qtcHdg).notes,
                          publicationDate: QTc.qtcCalculator(formula: .qtcHdg).publicationDate,
                          numberOfSubjects: QTc.qtcCalculator(formula: .qtcHdg).numberOfSubjects),
         .qtpFrd:
           QTpCalculator(formula: .qtpFrd,
                         longName: QTc.qtcCalculator(formula: .qtcFrd).longName,
                         shortName: "QTpFRD",
                         reference: QTc.qtcCalculator(formula: .qtcFrd).reference,
                         equation: "0.3815 * \u{221B}RR | units in 0.01 sec",
                         baseEquation: {rrInSec, _, _ in 0.0822 * pow(100.0 * rrInSec, 1/3)},
                         classification: QTc.qtcCalculator(formula: .qtcFrd).classification,
                         notes: QTc.qtcCalculator(formula: .qtcFrd).notes,
                         publicationDate: QTc.qtcCalculator(formula: .qtcFrd).publicationDate,
                         numberOfSubjects: QTc.qtcCalculator(formula: .qtcFrd).numberOfSubjects),
         .qtpMyd:
            QTpCalculator(formula: .qtpMyd,
                          longName: QTc.qtcCalculator(formula: .qtcMyd).longName,
                          shortName: "QTpMYD",
                          reference: QTc.qtcCalculator(formula: .qtcMyd).reference,
                          // equation modified from Simonson doi:10.1016/0002-8703(62)90059-5
                          equation: "0.02574 * (100 * RR)^0.604",
                          baseEquation: {rrInSec, _, _ in 0.02574 * pow(100.0 * rrInSec, 0.604)},
                          classification: QTc.qtcCalculator(formula: .qtcMyd).classification,
                          notes: "200 normal subjects and patients without heart disease (135 M, 65 F; age 18-64; HR 54.5-115.8).",
                          publicationDate: QTc.qtcCalculator(formula: .qtcMyd).publicationDate,
                          numberOfSubjects: 200),
         .qtpKrj:
           QTpCalculator(formula: .qtpKrj,
                         longName: "Karjalainen",
                         shortName: "QTpKRJ",
                         reference: "Karjalainen J, Viitasalo M, Mänttäri M, Manninen V. Relation between QT intervals and heart rates from 40 to 120 beats/min in rest electrocardiograms of men and a simple method to adjust QT interval values. Journal of the American College of Cardiology. 1994;23(7):1547-1553. doi:10.1016/0735-1097(94)90654-8",
                         equation: """
                                    HR < 60: 0.116*RR + 277
                                    HR 60 to 99: 0.156*RR + 236
                                    HR > 99: 0.384*RR + 99
                                    RR and QT in msec
                                    """,
                         baseEquation: {rrInSec, _, _ in
                             if rrInSec > 1.0 {
                                 return QTc.msecToSec(116.0 * rrInSec + 277.0)
                             }
                             else if rrInSec <= 0.6 {
                                 return QTc.msecToSec(384.0 * rrInSec + 99.0)
                             }
                             else {
                                 return QTc.msecToSec(156.0 * rrInSec + 236.0)
                             }
                         },
                         classification: .linear,
                         notes: "324 healthy young (age 18-28) men.",
                         publicationDate: "1994",
                         numberOfSubjects: 324),
         .qtpSch:
            QTpCalculator(formula: .qtpSch,
                          longName: "Schlamowitz",
                          shortName: "QTpSCH",
                          reference: "Schlamowitz I. An analysis of the time relationships within the cardiac cycle in electrocardiograms of normal men.  American Heart Journal.  1946;31(3):329-342.  doi:10.1016/0002-8703%2846%2990314-6",
                          equation: "0.205*RR + 0.167",
                          baseEquation: {rrInSec, _, _ in 0.205 * rrInSec + 0.167},
                          classification: .linear,
                          notes: "650 healthy male soldiers, age 18-44.",
                          publicationDate: "1946",
                          numberOfSubjects: 650),
         .qtpAdm:
           QTpCalculator(formula: .qtpAdm,
                         longName: QTc.calculator(formula: .qtcAdm).longName,
                         shortName: "QTpADM",
                         reference: QTc.calculator(formula: .qtcAdm).reference,
                         equation: """
                                    0.2462 + 0.1536*RR for men
                                    0.2789 + 0.1259*RR for women
                                    0.2572 + 0.1464*RR for combined sexes
                                    """,
                         baseEquation: qtpAdm,
                         classification: .linear,
                         notes: "104 healthy subjects, 50 men, 54 women, mean age 28.",
                         publicationDate: QTc.calculator(formula: .qtcAdm).publicationDate,
                         numberOfSubjects: QTc.calculator(formula: .qtcAdm).numberOfSubjects),
         .qtpSmn:
            QTpCalculator(formula: .qtpSmn,
                          longName: "Simonson",
                          shortName: "QTpSMN",
                          reference: "Simonson E, Cady LD, Woodbury M. The normal Q-T interval. American Heart Journal. 1962;63(6):747-753. doi:10.1016/0002-8703(62)90059-5",
                          equation: "0.2423 + 0.140 * RR + 0.0003 * age",
                          baseEquation: {rrInSec, _, age in
                            guard let age = age else { throw CalculationError.ageRequired }
                            return 0.2423 + 0.140 * rrInSec + 0.0003 * Double(age)},
                          classification: .linear,
                          notes: "649 men, 311 women, aged 20-59, healthy.",
                          publicationDate: "1962",
                          numberOfSubjects: 960),
         .qtpKwt:
            QTpCalculator(formula: .qtpKwt,
                          longName: QTc.calculator(formula: .qtcKwt).longName,
                          shortName: "QTpKWT",
                          reference: QTc.calculator(formula: .qtcKwt).reference,
                          equation: "0.45 * RR^0.25",
                          baseEquation: {rrInSec, _, _ in 0.45 * pow(rrInSec, 0.25)},
                          classification: .linear,
                          notes: QTc.calculator(formula: .qtcKwt).notes,
                          publicationDate: QTc.calculator(formula: .qtcKwt).publicationDate,
                          numberOfSubjects: QTc.calculator(formula: .qtcKwt).numberOfSubjects),
         .qtpScl:
            // NB: lacking definitive source we have added constants for decades 30s and 50s, since they aren't given in Simonson.
            // These constants work for the table in Simonson and the figures in Rabkin.
            QTpCalculator(formula: .qtpScl,
                          longName: "Schlomka",
                          shortName: "QTpSCL",
                          reference: "Schlomka VG, Raab W. Zur Bewertung der relativen systolendauer. Z Kreislaufforsch 1936;18:673-700.",
                          equation: "k * (100 * RR)^(1/3) | k is age dependent",
                          baseEquation: {rrInSec, _, age in
                            guard let age = age else {throw CalculationError.ageRequired}
                            guard age > 19 else {throw CalculationError.ageOutOfRange}
                            var k: Double
                            if age < 30 {
                                k = 0.0795
                            }
                            else if age < 40 {
                                k = 0.0799 // extrapolated constant
                            }
                            else if age < 50 {
                                k = 0.0802
                            }
                            else if age < 60 {
                                k = 0.0808  // extrpolated constant
                            }
                            else if age < 70 {
                                k = 0.0815
                            }
                            else {
                                k = 0.0826
                            }
                            return k * pow((100.0 * rrInSec), (1.0/3.0))},
                          classification: .power,
                          notes: "336 men and women.  Age dependent formula with minimum age 20.",
                          publicationDate: "1936",
                          numberOfSubjects: 336),
         .qtpMrr:
            QTpCalculator(formula: .qtpMrr,
                          longName: "Merri",
                          shortName: "QTpMRR",
                          reference: "Merri M, Benhorin J, Alberti M, Locati E, Moss AJ. Electrocardiographic quantitation of ventricular repolarization. Circulation. 1989;80(5):1301-1308. doi:10.1161/01.CIR.80.5.1301",
                          equation: """
                                10^(1.3 + 0.44 * log(RR)) for men
                                10^(1.43 + 0.4 * log(RR)) for women
                                10^(1.41 + 0.4 * log(RR)) for total population
                                RR in msec, log is base 10
                                """,
                          baseEquation: {rrInSec, sex, _ in
                            var k: Double
                            var a: Double
                            switch(sex) {
                            case .unspecified:
                                k = 1.41
                                a = 0.4
                            case .male:
                                k = 1.3
                                a = 0.44
                            case .female:
                                k = 1.43
                                a = 0.4
                            }
                            return QTc.msecToSec(pow(10.0, k + a * log10(QTc.secToMsec(rrInSec))))},
                          classification: .logarithmic,
                          notes: "364 healthy subjects, 191 men, 173 women, age 10-81.",
                          publicationDate: "1989",
                          numberOfSubjects: 364),
         .qtpHgg:
            QTpCalculator(formula: .qtpHgg,
                          longName: "Hegglin",
                          shortName: "QTpHGG",
                          reference: "Hegglin R, Holzmann M. Die klinische Bedeutung der verlangerten QT-Distanz (Systolendauer) im Elektrokardiogramm, Ztschr Klin Med. 1937;132:1.",
                          equation: "0.39 * \u{221A}RR",
                          baseEquation: {rrInSec, _, _ in 0.39 * pow(rrInSec, 0.5)},
                          classification: .power,
                          notes: "700 normal subjects and patients without heart disease.",
                          publicationDate: "1937",
                          numberOfSubjects: 700),

         .qtpGot:
            QTpCalculator(formula: .qtpGot,
                          longName: QTc.qtcCalculator(formula: .qtcGot).longName,
                          shortName: "QTpGOT",
                          reference: QTc.qtcCalculator(formula: .qtcGot).reference,
                          equation: "435 * RR^0.3409 | RR in sec, result in msec",
                          baseEquation: {rrInSec, _, _ in QTc.msecToSec(435.0 * pow(rrInSec, 0.3409))},
                          classification: .power,
                          notes: QTc.qtcCalculator(formula: .qtcGot).notes + "  QTp formula in this paper defines upper limit of normal QT.",
                          publicationDate: QTc.qtcCalculator(formula: .qtcGot).publicationDate,
                          numberOfSubjects: QTc.qtcCalculator(formula: .qtcGot).numberOfSubjects),
         .qtpKlg:
            QTpCalculator(formula: .qtpKlg,
                         longName: "Kligfield",
                         shortName: "QTpKLG",
                         reference: "Kligfield P, Lax KG, Okin PM. QTc behavior during treadmill exercise as a function of the underlying QT-heart rate relationship. Journal of Electrocardiology. 1995;28:206-210. doi:10.1016/S0022-0736(95)80058-1",
                         equation: "481 - 1.32*HR | result in msec",
                         baseEquation: {rrInSec, _, _ in QTc.msecToSec(481.0 - 1.32 * QTc.secToBpm(rrInSec))},
                         classification: .rational,
                         notes: "94 normal men, mean age 48 ± 10, evaluated at rest and during exercise.",
                         publicationDate: "1995",
                         numberOfSubjects: 94),
         .qtpShp:
           QTpCalculator(formula: .qtpShp,
                         longName: "Shipley",
                         shortName: "QTpSHP",
                         reference: "Shipley RA, Hallaran WR. The four-lead electrocardiogram in two hundred normal men and women. American Heart Journal. 1936;11(3):325-345. doi:10.1016/S0002-8703(36)90417-9",
                         equation: "K * RR^0.05, K = 0.397 men, K = 0.415 women",
                         baseEquation: {rrInSec, sex, _ in
                             var K: Double
                             switch sex {
                             case .unspecified:
                                 throw CalculationError.sexRequired
                             case .male:
                                 K = 0.397
                             case .female:
                                 K = 0.415
                             }
                             return K * pow(rrInSec, 0.5)},
                         classification: .power,
                         notes: "200 normal volunteers without evidence of disease, M/F ratio not given, age 20-35.",
                         publicationDate: "1936",
                         numberOfSubjects: 200),
         .qtpWhl:
           QTpCalculator(formula: .qtpWhl,
                         longName: "Wohlfart",
                         shortName: "QTpWHL",
                         reference: "Wohlfart B, Pahlm O. Normal values for QT intervals in ECG during ramp exercise on bicycle. Clinical Physiology. 2008;14(4):371-377. doi:10.1111/j.1475-097X.1994.tb00395.x",
                         equation: "459 - 1.23*HR | result in msec",
                         baseEquation: {rrInSec, _, _ in QTc.msecToSec(459.0 - 1.23 * QTc.secToBpm(rrInSec))},
                         classification: .rational,
                         notes: "37 healthy subjects, 16 men, 21 women, during rest and bicycle exercise.",
                         publicationDate: "2008",
                         numberOfSubjects: 37),
         .qtpSrm:
           QTpCalculator(formula: .qtpSrm,
                         longName: "Sarma",
                         shortName: "QTpSRM",
                         reference: "Sarma JSM, Sarma RJ, Bilitch M, Katz D, Song SL. An exponential formula for heart rate dependence of QT interval during exercise and cardiac pacing in humans: Reevaluation of Bazett’s formula. American Journal of Cardiology. 1984;54(1):103-108. doi:10.1016/0002-9149(84)90312-6",
                         equation: "508 - 664 * e^(-2.7*RR) | result in msec",
                         baseEquation: {rrInSec, _, _ in QTc.msecToSec(508 - 664 * exp(-2.7 * rrInSec))},
                         classification: .exponential,
                         notes: "10 healthy men, age 18-30, undergoing exercise ECG.",
                         publicationDate: "1984",
                         numberOfSubjects: 10),
         .qtpLcc:
           QTpCalculator(formula: .qtpLcc,
                         longName: "Lecocq",
                         shortName: "QTpLCC",
                         reference: "Lecocq B, Lecocq V, Jaillon P. Physiologic relation between cardiac cycle and QT duration in healthy volunteers. American Journal of Cardiology. 1989;64(8):481-486. doi:10.1016/0002-9149(89)90425-6",
                         equation: "425 - 676 * e^(-3.7 * RR) | RR in sec, result in msec",
                         baseEquation: {rrInSec, _, _ in QTc.msecToSec(425 - 676 * exp(-3.7 * rrInSec))},
                         classification: .exponential,
                         notes: "11 healthy subjects, 5 men, 6 women, age 22-26.  Rest and exercise ECGs.",
                         publicationDate: "1989",
                         numberOfSubjects: 11),
         .qtpRbk:
            QTpCalculator(formula: .qtpRbk,
                          longName: QTc.qtcCalculator(formula: .qtcRbk).longName,
                          shortName: "QTpRBK",
                          reference: QTc.qtcCalculator(formula: .qtcRbk).reference,
                          equation: QTc.qtcCalculator(formula: .qtcRbk).equation,
                          baseEquation: {rrInSec, sex, age in
                            // check for lack of sex and throw
                            guard sex != .unspecified else {
                                throw CalculationError.sexRequired
                            }
                            if let age = age {
                                return QTc.msecToSec(QtcRbk.qtpRbk(hr: QTc.secToBpm(rrInSec), isFemale: sex == .female ? true : false, age: Double(age)))
                            }
                            else {
                                return QTc.msecToSec(QtcRbk.qtpRbk(hr: QTc.secToBpm(rrInSec), isFemale: sex == .female ? true : false))
                            }},
                          classification: QTc.qtcCalculator(formula: .qtcRbk).classification,
                          notes: QTc.qtcCalculator(formula: .qtcRbk).notes,
                          publicationDate: QTc.qtcCalculator(formula: .qtcRbk).publicationDate,
                          numberOfSubjects: QTc.qtcCalculator(formula: .qtcRbk).numberOfSubjects)
    ]
}
