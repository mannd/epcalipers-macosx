//
//  AngleCaliper.swift
//  EP Calipers
//
//  Created by David Mann on 1/7/17.
//  Copyright © 2017 EP Studios. All rights reserved.
//

import Cocoa

class AngleCaliper: Caliper {
    var angleBar1 = CGFloat(0.5 * M_PI)
    var angleBar2 = CGFloat(0.25 * M_PI)
    var verticalCalibration: Calibration? = nil
    let angleDelta = 0.15
    
    init() {
        super.init(direction: .horizontal, bar1Position: 100.0, bar2Position: 100.0, crossBarPosition: 100.0)
        requiresCalibration = false
        isAngleCaliper = true
    }
    
    override func setInitialPositionInRect(_ rect: CGRect) {
        struct Holder {
            static var differential: CGFloat = 0
        }
        bar1Position = (rect.size.width / 3) + Holder.differential
        bar2Position = bar1Position
        crossBarPosition = (rect.size.height / 3) + Holder.differential * 1.5
        Holder.differential += 20
        if Holder.differential > 100 {
            Holder.differential = 0
        }
    }
    
    override func drawWithContext(_ context: CGContext, inRect rect:CGRect) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        
        // Ensure caliper always extends past the screen edges
        let length = CGFloat(fmax(Double(rect.size.height), Double(rect.size.width)) * 2.0)
        
        crossBarPosition = CGFloat(fmin(Double(crossBarPosition), Double(rect.size.height) - delta))
        crossBarPosition = CGFloat(fmax(Double(crossBarPosition), delta))
        bar1Position = CGFloat(fmin(Double(bar1Position), Double(rect.size.width) - delta))
        bar2Position = bar1Position
        
        let endPointBar1 = endPointForPosition(p: CGPoint(x: bar1Position, y: crossBarPosition), angle: angleBar1, length: length)
        context.move(to: CGPoint(x: bar1Position, y: crossBarPosition))
        context.addLine(to: CGPoint(x: endPointBar1.x, y: endPointBar1.y))
        
        let endPointBar2 = endPointForPosition(p: CGPoint(x: bar2Position, y: crossBarPosition), angle: angleBar2, length: length)
        context.move(to: CGPoint(x: bar2Position, y: crossBarPosition))
        context.addLine(to: CGPoint(x: endPointBar2.x, y: endPointBar2.y))
        
        context.strokePath()
        caliperText()
    }
    
    func endPointForPosition(p: CGPoint, angle: CGFloat, length: CGFloat) -> CGPoint {
        let endX = cos(angle) * length + p.x
        let endY = p.y - sin(angle) * length
        let endPoint = CGPoint(x: endX, y: endY)
        return endPoint
    }
    
    func pointNearBar(point p: CGPoint, forBarAngle barAngle: CGFloat) -> Bool {
        let theta = relativeTheta(point: p)
        return theta < Double(barAngle) + angleDelta && theta > Double(barAngle) - angleDelta
    }
    
    func relativeTheta(point p: CGPoint) -> Double {
        let x = p.x - bar1Position
        let y = crossBarPosition - p.y
        return atan2(Double(y), Double(x))
    }
    
    override func pointNearBar1(p: CGPoint) -> Bool {
        return pointNearBar(point: p, forBarAngle: angleBar1)
    }
    
    override func pointNearBar2(p: CGPoint) -> Bool {
        return pointNearBar(point: p, forBarAngle: angleBar2)
    }
    
    override func pointNearCrossBar(_ p: CGPoint) -> Bool {
        let delta: CGFloat = 40.0
        return (p.x > bar1Position - delta && p.x < bar1Position + delta
        && p.y > crossBarPosition - delta && p.y < crossBarPosition + delta)
    }
    
    override func measurement() -> String {
        let angle = angleBar1 - angleBar2
        let degrees = radiansToDegrees(radians: Double(angle))
        let text = String(format: "%1.f°", degrees)
        return text
    }
    
    func radiansToDegrees(radians: Double) -> Double {
        return radians * 180.0 / M_PI
    }

    override func intervalResult() -> Double {
        return Double(angleBar1 - angleBar2)
    }
    
    override func moveBar1(delta: CGPoint, forLocation location: CGPoint) {
        angleBar1 = CGFloat(moveBarAngle(delta: delta, forLocation: location))
    }
    
    override func moveBar2(delta: CGPoint, forLocation location: CGPoint) {
        angleBar2 = CGFloat(moveBarAngle(delta: delta, forLocation: location))
    }
    
    func moveBarAngle(delta: CGPoint, forLocation location: CGPoint) -> Double {
        let newPosition = CGPoint(x: location.x + delta.x, y: location.y + delta.y)
        return relativeTheta(point: newPosition)
    }
    
  
    
}
