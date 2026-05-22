//
//  EP_CalipersTests.swift
//  EP CalipersTests
//
//  Created by David Mann on 12/25/15.
//  Copyright © 2015 EP Studios. All rights reserved.
//

import Cocoa
import XCTest
@testable import MiniQTc
@testable import EP_Calipers

class EP_CalipersTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testBarCoord() {
        let c = Caliper()
        let viewport = CalipersViewport(magnification: 1.0, offset: .zero)
        XCTAssert(c.bar1Position(in: viewport) == 0)
        XCTAssert(c.bar2Position(in: viewport) == 0);
        XCTAssert(c.crossBarPosition(in: viewport) == 0);
        let p = CGPoint(x: 100, y: 50);
        XCTAssert(c.barCoord(p) == 100);
        c.direction = .vertical;
        XCTAssert(c.barCoord(p) == 50);
    }
    
    func testCanDisplayRate() {
        let cal = Calibration()
        cal.calibrated = true
        cal.rawUnits = "msec"
        XCTAssert(cal.canDisplayRate)
        cal.rawUnits = "milliseconds";
        XCTAssert(cal.canDisplayRate)
        cal.rawUnits = "sec";
        XCTAssert(cal.canDisplayRate)
        cal.rawUnits = "secs";
        XCTAssert(cal.canDisplayRate)
        cal.rawUnits = "Msec";
        XCTAssert(cal.canDisplayRate)
        cal.rawUnits = "ms";
        XCTAssert(cal.canDisplayRate)
        cal.rawUnits = "mm";
        XCTAssert(!cal.canDisplayRate)
        cal.rawUnits = "mSecs";
        XCTAssert(cal.canDisplayRate)
        cal.direction = .vertical;
        XCTAssert(!cal.canDisplayRate)
    }
    
    func testCurrentHorizontalCalFactor() {
        let cal = Calibration()
        cal.magnificationAtCalibration = 1.0;
        cal.calibrationFactorAtCalibration = 0.5;
        cal.calibrated = true
        XCTAssert(cal.multiplier(currentMagnification: 1) == 0.5)
        XCTAssert(cal.multiplier(currentMagnification: 2) == 0.25)
        XCTAssert(cal.multiplier(currentMagnification: 0.5) == 1.0)
        XCTAssert(cal.multiplier(currentMagnification: 0.25) == 2.0)
    }
    
    func testUnits() {
        let c = Caliper()
        XCTAssert(c.calibration.units == "points")
        c.calibration.calibrated = true
        c.calibration.rawUnits = "msec"
        XCTAssert(c.calibration.units == "msec")
        c.calibration.displayRate = true
        XCTAssert(c.calibration.units == "bpm")
        c.calibration.displayRate = false
        XCTAssert(c.calibration.units == "msec")

    }
    
    func testUnitsAreMM() {
        let cal = Calibration()
        cal.calibrated = true
        cal.direction = .vertical
        cal.rawUnits = "mm"
        XCTAssert(cal.unitsAreMM);
        cal.rawUnits = "millimeters";
        XCTAssert(cal.unitsAreMM);
        cal.rawUnits = "Millimeter";
        XCTAssert(cal.unitsAreMM);
        cal.rawUnits = "MM";
        XCTAssert(cal.unitsAreMM);
        cal.rawUnits = "milliM";
        XCTAssert(cal.unitsAreMM);
        cal.rawUnits = "milliVolts";
        XCTAssert(!cal.unitsAreMM);
        cal.rawUnits = "mV";
        XCTAssert(!cal.unitsAreMM);
        cal.rawUnits = "msec";
        XCTAssert(!cal.unitsAreMM);
    }

    func testNoNegBPM() {
        let cal = Calibration()
        cal.calibrated = true
        cal.direction = .horizontal
        cal.magnificationAtCalibration = 1.0
        cal.calibrationFactorAtCalibration = 1.0
        cal.calibrationString = "1000 msec"
        cal.rawUnits = "msec"
        let viewport = CalipersViewport(magnification: 1.0, offset: .zero)
        let c = Caliper()
        c.calibration = cal
        c.setBar1Position(1000, in: viewport)
        c.setBar2Position(2000, in: viewport)
        var m = c.measurement(in: viewport)
        XCTAssertEqual(m, "1,000 msec")
        cal.displayRate = true
        m = c.measurement(in: viewport)
        XCTAssertEqual(m, "60 bpm")
        cal.displayRate = false
        c.setBar1Position(2000, in: viewport)
        c.setBar2Position(1000, in: viewport)
        m = c.measurement(in: viewport)
        XCTAssertEqual(m, "-1,000 msec")
        cal.displayRate = true
        m = c.measurement(in: viewport)
        XCTAssertEqual(m, "60 bpm")
    }
    
    func testIsAngleCaliper() {
        let caliper = Caliper()
        XCTAssert(caliper.requiresCalibration);
        XCTAssert(!caliper.isAngleCaliper);
        let angleCaliper = AngleCaliper()
        XCTAssert(!angleCaliper.requiresCalibration);
        XCTAssert(angleCaliper.isAngleCaliper);
    }
    
    func testQTc() {
        let qtcResult = QTcResult()
        var result = qtcResult.calculate(qtInSec: 0.4, rrInSec: 1.0, formula: .Bazett, convertToMsec: false, units: "sec")
        XCTAssertEqual(result, "Mean RR = 1 sec\nQT = 0.4 sec\nQTc = 0.4 sec (Bazett formula)")
        result = qtcResult.calculate(qtInSec: 0.4, rrInSec: 1.0, formula: .Hodges, convertToMsec: false, units: "sec")
        XCTAssertEqual(result, "Mean RR = 1 sec\nQT = 0.4 sec\nQTc = 0.4 sec (Hodges formula)")
    }

    func testNumberFormatting() {
        let x = 305.463
        let y = 1010.728
        XCTAssertEqual(String(format: "%d", Int(round(x))), "305")
        XCTAssertEqual(String(format: "%d", Int(round(y))), "1011")
        XCTAssertEqual(String(format: "%.4g", x), "305.5")
        XCTAssertEqual(String(format: "%.4g", y), "1011")
        XCTAssertEqual(String(format: "%.1f", x), "305.5")
        XCTAssertEqual(String(format: "%.1f", y), "1010.7")
        XCTAssertEqual(String(format: "%.2f", x), "305.46")
        XCTAssertEqual(String(format: "%.2f", y), "1010.73")

    }

}
