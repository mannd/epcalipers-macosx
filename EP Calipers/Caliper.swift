//
//  Caliper.swift
//  EP Calipers
//
//  Created by David Mann on 1/7/16.
//  Copyright © 2016 EP Studios. All rights reserved.
//

import Cocoa

enum CaliperDirection {
    case Horizontal
    case Vertical
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
    
    init(direction: CaliperDirection, bar1Position: CGFloat, bar2Position: CGFloat,
        crossBarPosition: CGFloat) {

            self.direction = direction
            self.bar1Position = bar1Position
            self.bar2Position = bar2Position
            self.crossBarPosition = crossBarPosition
            self.color = NSColor.blueColor()
            self.unselectedColor = NSColor.blueColor()
            self.selectedColor = NSColor.redColor()
            self.lineWidth = 2
            self.selected = false
            self.textFont = NSFont(name: "Helvetica", size: 18.0)!
            self.paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            super.init()
    }
    
    convenience override init() {
        self.init(direction: .Horizontal, bar1Position: 0.0, bar2Position: 0.0,
            crossBarPosition: 100)
    }
    
    // set slightly different position for each new caliper
    func setInitialPositionInRect(rect: CGRect) {
        // no static func variables in Swift :(
        struct Holder {
            static var differential: CGFloat = 0
        }
        if direction == .Horizontal {
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
    
    func drawWithContext(context: CGContextRef, inRect rect:CGRect) {
        CGContextSetStrokeColorWithColor(context, color.CGColor)
        CGContextSetLineWidth(context, lineWidth)
        
        if self.direction == .Horizontal {
            crossBarPosition = CGFloat(fmin(Double(crossBarPosition), Double(rect.size.height) - delta));
            crossBarPosition = CGFloat(fmax(Double(crossBarPosition), delta));
            bar1Position = CGFloat(fmin(Double(bar1Position), Double(rect.size.width) - delta));
            bar2Position = CGFloat(fmax(Double(bar2Position), delta));
            CGContextMoveToPoint(context, bar1Position, 0);
            CGContextAddLineToPoint(context, bar1Position, rect.size.height);
            CGContextMoveToPoint(context, bar2Position, 0);
            CGContextAddLineToPoint(context, bar2Position, rect.size.height);
            CGContextMoveToPoint(context, bar2Position, crossBarPosition);
            CGContextAddLineToPoint(context, bar1Position, crossBarPosition);
            
        } else {    // vertical caliper
            crossBarPosition = CGFloat(fmin(Double(crossBarPosition), Double(rect.size.width) - delta));
            crossBarPosition = CGFloat(fmax(Double(crossBarPosition), delta));
            bar1Position = CGFloat(fmin(Double(bar1Position), Double(rect.size.height) - delta));
            bar2Position = CGFloat(fmax(Double(bar2Position), delta));
            CGContextMoveToPoint(context, 0, bar1Position);
            CGContextAddLineToPoint(context, rect.size.width, bar1Position);
            CGContextMoveToPoint(context, 0, bar2Position);
            CGContextAddLineToPoint(context, rect.size.width, bar2Position);
            CGContextMoveToPoint(context, crossBarPosition, bar2Position);
            CGContextAddLineToPoint(context, crossBarPosition, bar1Position);
        }
        CGContextStrokePath(context)
        let text = measurement()
        paragraphStyle.lineBreakMode = .ByTruncatingTail
        paragraphStyle.alignment = (direction == .Horizontal ? .Center : .Left)
        let attributes = [
            NSFontAttributeName: textFont,
            NSParagraphStyleAttributeName: paragraphStyle,
            NSForegroundColorAttributeName: color
        ]
        if direction == .Horizontal {
            // the math here insures that the label doesn't get so small that it can't be read
            text.drawInRect(CGRectMake((bar2Position > bar1Position ? bar1Position - 25: bar2Position - 25), crossBarPosition - 20,  fmax(50.0, fabs(bar2Position - bar1Position) + 50), 20),  withAttributes:attributes);
        }
        else {
            text.drawInRect(CGRectMake(crossBarPosition + 5, bar1Position + (bar2Position - bar1Position) / 2, 140, 20), withAttributes:attributes);
        }
 
    }
    
    func barCoord(p: CGPoint) -> CGFloat {
        return (direction == .Horizontal ? p.x : p.y)
    }
    
    func rect(containerRect: CGRect) -> CGRect {
        if direction == .Horizontal {
            return CGRectMake(bar1Position, containerRect.origin.y, self.bar2Position - bar1Position, containerRect.size.height)
        }
        else { // vertical caliper
            return CGRectMake(0, bar1Position, containerRect.size.width, bar2Position - bar1Position)
        }
    }
    
    func measurement() -> String {
        let s = String(format: "%.4g %@", calibratedResult(), calibration.units)
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
    
    func rateResult(interval: Double) -> Double {
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
    
    func intervalInSecs(interval: Double) -> Double {
        if calibration.unitsAreSeconds {
            return interval
        }
        else {
            return interval / 1000
        }
    }
    
    func intervalInMsec(interval: Double) -> Double {
        if calibration.unitsAreMsec {
            return interval
        }
        else {
            return 1000 * interval
        }
    }
    
    func pointNearBar(p: CGPoint, forBarPosition barPosition: CGFloat) -> Bool {
        return (Double(barCoord(p)) > (Double(barPosition) - delta)) && (Double(barCoord(p)) < (Double(barPosition) + delta))
    }
    
    func pointNearCrossBar(p: CGPoint) -> Bool {
        var nearBar = false
        let adjustedDelta = delta + 5  // make crossbar delta a little larger
        if direction == .Horizontal {
            nearBar = (Double(p.x) > fmin(Double(bar1Position), Double(bar2Position)) + adjustedDelta &&
            Double(p.x) < fmax(Double(bar2Position), Double(bar1Position)) - adjustedDelta &&
            Double(p.y) > Double(crossBarPosition) - adjustedDelta && Double(p.y) < Double(crossBarPosition) + adjustedDelta)
        }
        else {
            nearBar = (Double(p.y) > fmin(Double(bar1Position), Double(bar2Position)) + adjustedDelta &&
            Double(p.y) < fmax(Double(bar2Position), Double(bar1Position)) - adjustedDelta &&
            Double(p.x) > Double(crossBarPosition) - adjustedDelta && Double(p.x) < Double(crossBarPosition) + adjustedDelta)
        }
        return nearBar
    }
    
    func pointNearCaliper(p: CGPoint) -> Bool {
        return pointNearCrossBar(p) || pointNearBar(p, forBarPosition: bar1Position) || pointNearBar(p, forBarPosition: bar2Position)
    }
    
}
