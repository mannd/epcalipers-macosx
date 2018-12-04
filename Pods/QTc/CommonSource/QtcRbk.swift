//
//  QtcRbk.swift
//  QTc_iOS
//
//  Created by David Mann on 9/22/18.
//  Copyright © 2018 EP Studios. All rights reserved.
//

import Foundation


/// QTcRBK is based on a complex cubic spline function.
///
/// We have split out the components to make the math as clear as possible.
enum QtcRbk {
    public static func qtpRbk(hr: Double, isFemale: Bool) -> Double {
        return 533.52 - 77.57 * b1(hr) - 102.51 * b2(hr) - 131.96 * b3(hr)
          - 146.35 * b4(hr) - 197.89 * b5(hr) - 233.7 * b6(hr)
          - 247.2 * b7(hr) + (isFemale ? 1.0 : 0) * 9.61
    }
    
    public static func qtpRbk(hr: Double, isFemale: Bool, age: Double) -> Double {
        return 523.29 - 76.94 * b1(hr) - 101.59 * b2(hr) - 130.81 * b3(hr)
          - 144.79 * b4(hr) - 196.76 * b5(hr) - 231.01 * b6(hr)
          - 247.84 * b7(hr) + (isFemale ? 1.0 : 0) * 9.35 + 0.18 * age
    }

    internal static func qtpRbkR(hr: Double, isFemale: Bool, age: Double) -> Double {
        return 523.29 - r(76.94 * b1(hr)) - r(101.59 * b2(hr)) - r(130.81 * b3(hr))
          - r(144.79 * b4(hr)) - r(196.76 * b5(hr)) - r(231.01 * b6(hr))
          - r(247.84 * b7(hr)) + (isFemale ? 1.0 : 0) * 9.35 + 0.18 * age
    }

    public static func qtcRbk(qt: Double, hr: Double, isFemale: Bool) -> Double {
        return qtpRbk(hr: 60, isFemale: false) + (qt - qtpRbk(hr: hr, isFemale: isFemale))
    }

    public static func qtcRbk(qt: Double, hr: Double, isFemale: Bool, age: Double) -> Double {
        return qtpRbk(hr: 60, isFemale: false, age: 50.3) + (qt - qtpRbk(hr: hr, isFemale: isFemale, age: age))
    }

    internal static func r(_ x: Double) -> Double {
        // round to nearest 10,000
        let y = round(10_000.0 * x) / 10_000
        return y
    }

    // Fundamental component of the basic functions b0 to b1.
    private static func f(_ x: Double, _ c0: Double, _ c1: Double) -> Double {
        return (x - c0) / (c1 - c0)
    }

    // returns f^2
    private static func f2(_ x: Double, _ c0: Double, _ c1: Double) -> Double {
        return pow(f(x, c0, c1), 2)
    }

    // returns f^3
    private static func f3(_ x: Double, _ c0: Double, _ c1: Double) -> Double {
        return pow(f(x, c0, c1), 3)
    }

    // g = 1 - f
    private static func g(_ x: Double, _ c0: Double, _ c1: Double) -> Double {
        return 1 - f(x, c0, c1)
    }

    // returns g^2
    private static func g2(_ x: Double, _ c0: Double, _ c1: Double) -> Double {
        return pow(g(x, c0, c1), 2)
    }

    // returns g^3
    private static func g3(_ x: Double, _ c0: Double, _ c1: Double) -> Double {
        return pow(g(x, c0, c1), 3)
    }

    private static func ind(_ x: Double, _ min: Double, _ max: Double) -> Double {
        if min <= x && x < max { return 1.0 }
        else { return 0 }
    }

    internal static func b0(_ x: Double) -> Double {
        return g3(x, 35, 61) * ind(x, 35, 61)
    }

    internal static func b1(_ x: Double) -> Double {
        return f(x, 35, 61) * (g2(x, 35, 61) + g(x, 35, 61) * g(x, 35, 67) + g2(x, 35, 67))
            * ind(x, 35, 61)
            +
            g2(x, 35, 67) * g(x, 61, 67) * ind(x, 61, 67)
    }

    internal static func b2(_ x: Double) -> Double {
        return f(x, 35, 61) * f(x, 35, 67) * (g(x, 35, 61) + g(x, 35, 67) + g(x, 35, 73))
            * ind(x, 35, 61)
            +
            f(x, 35, 67) * g(x, 61, 67) * (g(x, 35, 67) + g(x, 35, 73)) * ind(x, 61, 67)
            +
            f(x, 61, 67) * g(x, 35, 73) * g(x, 61, 73) * ind(x, 61, 67)
            +
            g(x, 35, 73) * g(x, 61, 73) * g(x, 67, 73) * ind(x, 67, 73)
    }

    internal static func b3(_ x: Double) -> Double {
        return f(x, 35, 61) * f(x, 35, 67) * f(x, 35, 73) * ind(x, 35, 61)
            +
            (f(x, 35, 73) * (f(x, 35, 67) * g(x, 61, 67) + f(x, 61, 67) * g(x, 61, 73)))
            * ind(x, 61, 67)
            +
            f(x, 61, 67) * f(x, 61, 73) * g(x, 61, 81) * ind(x, 61, 67)
            +
            (g(x, 67, 73) * (f(x, 35, 73) * g(x, 61, 73) + f(x, 61, 73) * g(x, 61, 81)))
            * ind(x, 67, 73)
            +
            f(x, 67, 73) * g(x, 61, 81) * g(x, 67, 81) * ind(x, 67, 73)
            +
            g(x, 61, 81) * g(x, 67, 81) * g(x, 73, 81) * ind(x, 73, 81)
    }

    internal static func b4(_ x: Double) -> Double {
        return f(x, 61, 67) * f(x, 61 ,73) * f(x, 61, 81) * ind(x, 61, 67)
          +
          f(x, 61, 81) * (f(x, 61, 73) * g(x, 67, 73) + f(x, 67, 73) * g(x, 67, 81))
          * ind(x, 67, 73)
          +
          f(x, 67, 73) * f(x, 67, 81) * g(x, 67, 156) * ind(x, 67, 73)
          +
          g(x, 73, 81) * (f(x, 61, 81) * g(x, 67, 81) + f(x, 67, 81) * g(x, 67, 156))
          * ind(x, 73, 81)
          +
          f(x, 73, 81) * g(x, 67, 156) * g(x, 73, 156) * ind(x, 73, 81)
          +
          g(x, 67, 156) * g(x, 73, 156) * g(x, 81, 156) * ind(x, 81, 156)
    }

    internal static func b5(_ x: Double) -> Double {
        return f(x, 67, 73) * f(x, 67, 81) * f(x, 67, 156) * ind(x, 67, 73)
          +
          f(x, 67, 156) * (f(x, 67, 81) * g(x, 73, 81) + f(x, 73, 81) * g(x, 73,156))
          * ind(x, 73, 81)
          +
          f(x, 73, 81) * f(x, 73, 156) * g(x, 73, 156) * ind(x, 73, 81)
          +
          g(x, 73, 156) * g(x, 81, 156) * (f(x, 67, 156) + f(x, 73, 156) + f(x, 81, 156))
          * ind(x, 81, 156)
    }

    internal static func b6(_ x: Double) -> Double {
        return f(x, 73, 81) * f2(x, 73, 156) * ind(x, 73, 81)
          +
          g(x, 81, 156) * (f2(x, 73, 156) + f(x, 73, 156) * f(x, 81, 156) + f2(x, 81, 156))
          * ind(x, 81, 156)
    }

    internal static func b7(_ x: Double) -> Double {
        return f3(x, 81, 156) * ind(x, 81, 156)
    }
}
