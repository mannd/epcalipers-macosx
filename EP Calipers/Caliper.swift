//
//  Caliper.swift
//  EP Calipers
//
//  Created by David Mann on 1/7/16.
//  Copyright © 2016 EP Studios. All rights reserved.
//

import Cocoa

enum CaliperDirection {
    case horizontal
    case vertical
}

class Caliper: NSObject {

    let delta: Double = 20.0
    var bar1Position: CGFloat
    var bar2Position: CGFloat
    var crossBarPosition: CGFloat
    var direction: CaliperDirection
    var color: NSColor
    var unselectedColor: NSColor
    var selectedColor: NSColor
    var lineWidth: CGFloat
    var selected: Bool
    var textFont: NSFont
    var paragraphStyle: NSMutableParagraphStyle
    var calibration: Calibration = Calibration()
    var roundMsecRate: Bool
    
    init(direction: CaliperDirection, bar1Position: CGFloat, bar2Position: CGFloat,
        crossBarPosition: CGFloat) {

            self.direction = direction
            self.bar1Position = bar1Position
            self.bar2Position = bar2Position
            self.crossBarPosition = crossBarPosition
            self.color = NSColor.blue()
            self.unselectedColor = NSColor.blue()
            self.selectedColor = NSColor.red()
            self.lineWidth = 2
            self.selected = false
            self.textFont = NSFont(name: "Helvetica", size: 18.0)!
            self.paragraphStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
            self.roundMsecRate = true
            super.init()
    }
    
    convenience override init() {
        self.init(direction: .horizontal, bar1Position: 0.0, bar2Position: 0.0,
            crossBarPosition: 100)
    }
    
    // set slightly different position for each new caliper
    func setInitialPositionInRect(_ rect: CGRect) {
        // no static func variables in Swift :(
        struct Holder {
            static var differential: CGFloat = 0
        }
        if direction == .horizontal {
            bar1Position = (rect.size.width / 3) + Holder.differential
            bar2Position = ((2 * rect.size.width) / 3) + Holder.differential
            crossBarPosition = (rect.size.height / 2) + Holder.differential
        }
        else {
            bar1Position = (rect.size.height / 3) + Holder.differential
            bar2Position = ((2 * rect.size.height) / 3) + Holder.differential
            crossBarPosition = (rect.size.width / 3) + Holder.differential
        }
        Holder.differential += 15
        if Holder.differential > 80 {
            Holder.differential = 0
        }
    }
    
    func drawWithContext(_ context: CGContext, inRect rect:CGRect) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        
        if self.direction == .horizontal {
            crossBarPosition = CGFloat(fmin(Double(crossBarPosition), Double(rect.size.height) - delta));
            crossBarPosition = CGFloat(fmax(Double(crossBarPosition), delta));
            bar1Position = CGFloat(fmin(Double(bar1Position), Double(rect.size.width) - delta));
            bar2Position = CGFloat(fmax(Double(bar2Position), delta));
            context.moveTo(x: bar1Position, y: 0);
            context.addLineTo(x: bar1Position, y: rect.size.height);
            context.moveTo(x: bar2Position, y: 0);
            context.addLineTo(x: bar2Position, y: rect.size.height);
            context.moveTo(x: bar2Position, y: crossBarPosition);
            context.addLineTo(x: bar1Position, y: crossBarPosition);
            
        } else {    // vertical caliper
            crossBarPosition = CGFloat(fmin(Double(crossBarPosition), Double(rect.size.width) - delta));
            crossBarPosition = CGFloat(fmax(Double(crossBarPosition), delta));
            bar1Position = CGFloat(fmin(Double(bar1Position), Double(rect.size.height) - delta));
            bar2Position = CGFloat(fmax(Double(bar2Position), delta));
            context.moveTo(x: 0, y: bar1Position);
            context.addLineTo(x: rect.size.width, y: bar1Position);
            context.moveTo(x: 0, y: bar2Position);
            context.addLineTo(x: rect.size.width, y: bar2Position);
            context.moveTo(x: crossBarPosition, y: bar2Position);
            context.addLineTo(x: crossBarPosition, y: bar1Position);
        }
        context.strokePath()
        let text = measurement()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = (direction == .horizontal ? .center : .left)
        let attributes = [
            NSFontAttributeName: textFont,
            NSParagraphStyleAttributeName: paragraphStyle,
            NSForegroundColorAttributeName: color
        ]
        if direction == .horizontal {
            // the math here insures that the label doesn't get so small that it can't be read
            text.draw(in: CGRect(x: (bar2Position > bar1Position ? bar1Position - 25: bar2Position - 25), y: crossBarPosition - 20,  width: fmax(50.0, fabs(bar2Position - bar1Position) + 50), height: 20),  withAttributes:attributes);
        }
        else {
            text.draw(in: CGRect(x: crossBarPosition + 5, y: bar1Position + (bar2Position - bar1Position) / 2, width: 140, height: 20), withAttributes:attributes);
        }
 
    }
    
    func barCoord(_ p: CGPoint) -> CGFloat {
        return (direction == .horizontal ? p.x : p.y)
    }
    
    func rect(_ containerRect: CGRect) -> CGRect {
        if direction == .horizontal {
            return CGRect(x: bar1Position, y: containerRect.origin.y, width: self.bar2Position - bar1Position, height: containerRect.size.height)
        }
        else { // vertical caliper
            return CGRect(x: 0, y: bar1Position, width: containerRect.size.width, height: bar2Position - bar1Position)
        }
    }
    
    func measurement() -> String {
        var s: String
        if roundMsecRate && (calibration.displayRate || calibration.unitsAreMsec) {
            s = String(format: "%d %@", Int(round(calibratedResult())), calibration.units)
        }
        else {
            s = String(format: "%.4g %@", calibratedResult(), calibration.units)
        }
        return s
    }
    
    func calibratedResult() -> Double {
        var result = intervalResult()
        if result != 0 && calibration.displayRate && calibration.canDisplayRate {
            result = rateResult(result)
        }
        return result
    }
    
    func points() -> CGFloat {
        return bar2Position - bar1Position
    }
    
    func intervalResult() -> Double {
        return Double(points()) * calibration.multiplier()
    }
    
    func rateResult(_ interval: Double) -> Double {
        if interval != 0 {
            if calibration.unitsAreMsec {
                return 60000.0 / interval
            }
            if calibration.unitsAreSeconds {
                return 60.0 / interval
            }
        }
        return interval
    }
    
    func intervalInSecs(_ interval: Double) -> Double {
        if calibration.unitsAreSeconds {
            return interval
        }
        else {
            return interval / 1000
        }
    }
    
    func intervalInMsec(_ interval: Double) -> Double {
        if calibration.unitsAreMsec {
            return interval
        }
        else {
            return 1000 * interval
        }
    }
    
    func pointNearBar(_ p: CGPoint, forBarPosition barPosition: CGFloat) -> Bool {
        return (Double(barCoord(p)) > (Double(barPosition) - delta)) && (Double(barCoord(p)) < (Double(barPosition) + delta))
    }
    
    func pointNearCrossBar(_ p: CGPoint) -> Bool {
        var nearBar = false
        let adjustedDelta = delta + 5  // make crossbar delta a little larger
        if direction == .horizontal {
            nearBar = (Double(p.x) > fmin(Double(bar1Position), Double(bar2Position)) &&
            Double(p.x) < fmax(Double(bar2Position), Double(bar1Position)) &&
            Double(p.y) > Double(crossBarPosition) - adjustedDelta && Double(p.y) < Double(crossBarPosition) + adjustedDelta)
        }
        else {
            nearBar = (Double(p.y) > fmin(Double(bar1Position), Double(bar2Position)) &&
            Double(p.y) < fmax(Double(bar2Position), Double(bar1Position)) &&
            Double(p.x) > Double(crossBarPosition) - adjustedDelta && Double(p.x) < Double(crossBarPosition) + adjustedDelta)
        }
        return nearBar
    }
    
    func pointNearCaliper(_ p: CGPoint) -> Bool {
        return pointNearCrossBar(p) || pointNearBar(p, forBarPosition: bar1Position) || pointNearBar(p, forBarPosition: bar2Position)
    }
    
}
