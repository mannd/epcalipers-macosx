//
//  EP_CalipersTests.swift
//  EP CalipersTests
//
//  Created by David Mann on 12/25/15.
//  Copyright © 2015 EP Studios. All rights reserved.
//

import XCTest
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
        XCTAssert(c.bar1Position == 0)
        XCTAssert(c.bar2Position == 0);
        XCTAssert(c.crossBarPosition == 100.0);
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
        cal.originalZoom = 1.0;
        cal.originalCalFactor = 0.5;
        cal.currentZoom = 1.0;
        XCTAssert(cal.currentCalFactor() == 0.5);
        cal.currentZoom = 2.0;
        XCTAssert(cal.currentCalFactor() == 0.25);
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


}
