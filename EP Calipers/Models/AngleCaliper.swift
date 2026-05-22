//
//  AngleCaliper.swift
//  EP Calipers
//
//  Created by David Mann on 1/7/17.
//  Copyright © 2017 EP Studios. All rights reserved.
//

import Cocoa

class AngleCaliper: Caliper {
    var angleBar1 = CGFloat(0.5 * Double.pi)
    var angleBar2 = CGFloat(0.25 * Double.pi)
    var verticalCalibration: Calibration? = nil
    let angleDelta = 0.15
    var triangleBaseTextPosition: TextPosition = .centerAbove

    override var textPosition: TextPosition {
        get {
            return super.textPosition
        }
        set (newValue) {
            triangleBaseTextPosition = newValue
        }
    }
    
    init() {
        super.init(direction: .horizontal, bar1Position: 100.0, bar2Position: 100.0, crossBarPosition: 100.0, calibration: Calibration(), viewport: CalipersViewport(magnification: 1.0, offset: .zero))
        requiresCalibration = false
        isAngleCaliper = true
        triangleBaseTextPosition = textPosition
    }
    
    override func setInitialPositionInRect(_ rect: CGRect, in viewport: CalipersViewport) {
        struct Holder {
            static var differential: CGFloat = 0
        }
        setBar1Position((rect.size.width / 2) + Holder.differential, in: viewport)
        setBar2Position(bar1Position(in: viewport), in: viewport)
        setCrossBarPosition((rect.size.height / 1.5) + Holder.differential * 1.5, in: viewport)
        Holder.differential += 20
        if Holder.differential > 100 {
            Holder.differential = 0
        }
    }
    
    override func drawWithContext(_ context: CGContext, inRect rect:CGRect, viewport: CalipersViewport) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)

        // Ensure caliper always extends past the screen edges
        let length = CGFloat(fmax(Double(rect.size.height), Double(rect.size.width)) * 2.0)
        
        setBar2Position(bar1Position(in: viewport), in: viewport)

        let endPointBar1 = endPointForPosition(p: CGPoint(x: bar1Position(in: viewport), y: crossBarPosition(in: viewport)), angle: angleBar1, length: length)
        context.move(to: CGPoint(x: bar1Position(in: viewport), y: crossBarPosition(in: viewport)))
        context.addLine(to: CGPoint(x: endPointBar1.x, y: endPointBar1.y))
        
        let endPointBar2 = endPointForPosition(p: CGPoint(x: bar2Position(in: viewport), y: crossBarPosition(in: viewport)), angle: angleBar2, length: length)
        context.move(to: CGPoint(x: bar2Position(in: viewport), y: crossBarPosition(in: viewport)))
        context.addLine(to: CGPoint(x: endPointBar2.x, y: endPointBar2.y))
        
        context.strokePath()
        caliperText(rect: rect, textPosition: .centerAbove, viewport: viewport, optimizeTextPosition: false)

        if let verticalCalibration = verticalCalibration {
            if verticalCalibration.calibrated
                && verticalCalibration.unitsAreMM
                && Preferences.shared.showBrugadaTriangle {
                if angleInSouthernHemisphere(angleBar1) && angleInSouthernHemisphere(angleBar2) {
                    let pointsPerMM = 1.0 / verticalCalibration.multiplier(currentMagnification: viewport.magnification)
                    drawTriangleBase(context, forHeight: 5 * pointsPerMM, rect: rect, viewport: viewport)
                }
            }
        }
        drawChosenComponent(context, inRect: rect, endPointBar1: endPointBar1, endPointBar2: endPointBar2, viewport: viewport)
    }

    func drawChosenComponent(_ context: CGContext, inRect rect: CGRect, endPointBar1: CGPoint, endPointBar2: CGPoint, viewport: CalipersViewport) {
        guard chosenComponent != .noComponent, isTweaking else { return }
        context.setStrokeColor(getChosenComponentColor())
        switch chosenComponent {
        case .leftBar:
            context.move(to: CGPoint(x: bar1Position(in: viewport), y: crossBarPosition(in: viewport)))
            context.addLine(to: CGPoint(x: endPointBar1.x, y: endPointBar1.y))
        case .rightBar:
            context.move(to: CGPoint(x: bar2Position(in: viewport), y: crossBarPosition(in: viewport)))
            context.addLine(to: CGPoint(x: endPointBar2.x, y: endPointBar2.y))
        case .apex:
            context.move(to: CGPoint(x: bar1Position(in: viewport), y: crossBarPosition(in: viewport)))
            context.addLine(to: CGPoint(x: endPointBar1.x, y: endPointBar1.y))
            context.move(to: CGPoint(x: bar2Position(in: viewport), y: crossBarPosition(in: viewport)))
            context.addLine(to: CGPoint(x: endPointBar2.x, y: endPointBar2.y))
        default:
            break
        }

        context.strokePath()
    }

    func endPointForPosition(p: CGPoint, angle: CGFloat, length: CGFloat) -> CGPoint {
        let endX = cos(angle) * length + p.x
        let endY = p.y - sin(angle) * length
        let endPoint = CGPoint(x: endX, y: endY)
        return endPoint
    }
    
    func pointNearBar(point p: CGPoint, forBarAngle barAngle: CGFloat, in viewport: CalipersViewport) -> Bool {
        let theta = relativeTheta(point: p, viewport: viewport)
        return theta < Double(barAngle) + angleDelta && theta > Double(barAngle) - angleDelta
    }
    
    func relativeTheta(point p: CGPoint, viewport: CalipersViewport) -> Double {
        let x = p.x - bar1Position(in: viewport)
        let y = crossBarPosition(in: viewport) - p.y
        return atan2(Double(y), Double(x))
    }
    
    override func pointNearBar1(p: CGPoint, in viewport: CalipersViewport) -> Bool {
        return pointNearBar(point: p, forBarAngle: angleBar1, in: viewport)
    }
    
    override func pointNearBar2(p: CGPoint, in viewport: CalipersViewport) -> Bool {
        return pointNearBar(point: p, forBarAngle: angleBar2, in: viewport)
    }
    
    override func pointNearCrossBar(_ p: CGPoint, in viewport: CalipersViewport) -> Bool {
        let delta: CGFloat = 40.0
        return (p.x > bar1Position(in: viewport) - delta && p.x < bar1Position(in: viewport) + delta
                && p.y > crossBarPosition(in: viewport) - delta && p.y < crossBarPosition(in: viewport) + delta)
    }
    
    override func measurement(in viewport: CalipersViewport) -> String {
        let angle = angleBar1 - angleBar2
        let degrees = radiansToDegrees(radians: Double(angle))
        let text = NSString.localizedStringWithFormat("%.1f°", degrees) as String
        return text
    }
    
    func radiansToDegrees(radians: Double) -> Double {
        return radians * 180.0 / Double.pi
    }
    
    func degreesToRadians(degrees: Double) -> Double {
        return (degrees * Double.pi) / 180.0
    }

    override func intervalResult(in viewport: CalipersViewport) -> Double {
        let result = Double(angleBar1 - angleBar2)
        if (allowNegativeValues) {
            return result
        }
        return abs(result)
    }
    
    override func moveBar1(delta: CGPoint, forLocation location: CGPoint, in viewport: CalipersViewport) {
        angleBar1 = CGFloat(moveBarAngle(delta: delta, forLocation: location, in: viewport))
    }
    
    override func moveBar2(delta: CGPoint, forLocation location: CGPoint, in viewport: CalipersViewport) {
        angleBar2 = CGFloat(moveBarAngle(delta: delta, forLocation: location, in: viewport))
    }
    
    func moveBarAngle(delta: CGPoint, forLocation location: CGPoint, in viewport: CalipersViewport) -> Double {
        let newPosition = CGPoint(x: location.x + delta.x, y: location.y + delta.y)
        return relativeTheta(point: newPosition, viewport: viewport)
    }
    
    
    override func moveBarInDirection(movementDirection: MovementDirection, distance: CGFloat, forComponent component: CaliperComponent, in viewport: CalipersViewport) {
        let adjustedComponent = moveCrossbarInsteadOfSideBar(movementDirection: movementDirection, component: component) ? .apex : component
        if adjustedComponent == .apex {
            super.moveBarInDirection(movementDirection: movementDirection, distance: distance, forComponent: .crossBar, in: viewport)
            return
        }
        // we use smaller increments for angle calipers, otherwise the movement is too large
        var delta = distance / 2.0
        if movementDirection == .left {
            delta = -delta
        }
        switch (adjustedComponent) {
        case .leftBar:
            angleBar1 -= CGFloat(degreesToRadians(degrees: Double(delta)))
        case .rightBar:
            angleBar2 -= CGFloat(degreesToRadians(degrees: Double(delta)))
        default:
            break
        }
    }
    
    func drawTriangleBase(_ context: CGContext, forHeight height:Double, rect: CGRect, viewport: CalipersViewport) {
        let point1 = getBasePoint1ForHeight(height, viewport: viewport)
        let point2 = getBasePoint2ForHeight(height, viewport: viewport)
        let lengthInPoints = Double(point2.x - point1.x)
        context.move(to: point1)
        context.addLine(to: point2)
        context.strokePath()
        
        let text = baseMeasurement(lengthInPoints, viewport: viewport)
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = (direction == .horizontal ? .center : .left)
        var attributes = [NSAttributedString.Key: Any]()
        attributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: color
            ]
        let size = text.size(withAttributes: attributes)
        let textRect = caliperTextPosition(left: fmin(point1.x, point2.x), right: fmax(point1.x, point2.x), center: point1.y, size: size, rect: rect, textPosition: triangleBaseTextPosition, optimizeTextPosition: true)
        text.draw(in: textRect,  withAttributes:attributes)
    }

    func baseMeasurement(_ lengthInPoints: Double, viewport: CalipersViewport) -> String {
        var s: String
        var format: NSString
        if (calibration.unitsAreMsec) {
            switch rounding {
            case .ToInteger:
                format = roundToIntString
            case .ToFourPlaces:
                format = roundToFourPlacesString
            case .ToTenths:
                format = roundToTenthsString
            case .ToHundredths:
                format = roundToHundredthsString
            case .None:
                format = noRoundingString
            }
            if rounding == .ToInteger {
                s = NSString.localizedStringWithFormat(format, Int(calibratedBaseResult(lengthInPoints, viewport: viewport)), calibration.rawUnits) as String
            }
            else {
                s = NSString.localizedStringWithFormat(format, calibratedBaseResult(lengthInPoints, viewport: viewport), calibration.rawUnits) as String
            }
        }
        else {
            s = NSString.localizedStringWithFormat(roundToFourPlacesString, calibratedBaseResult(lengthInPoints, viewport: viewport), calibration.units) as String
        }
        return s
    }
    
    func calibratedBaseResult(_ lengthInPoints: Double, viewport: CalipersViewport) -> Double {
        var length = lengthInPoints * calibration.multiplier(currentMagnification: viewport.magnification)
        if rounding == .ToInteger && calibration.unitsAreMsec {
           length = round(length)
        }
        return length
    }
    
    func getBasePoint1ForHeight(_ height: Double, viewport: CalipersViewport) -> CGPoint {
        let pointY = Double(crossBarPosition(in: viewport)) - height
        var pointX = height * (sin(Double(angleBar1) - (Double.pi / 2)) / sin(Double.pi - Double(angleBar1)))
        pointX = Double(bar1Position(in: viewport)) - pointX
        return CGPoint(x: pointX, y: pointY)
    }
    
    func getBasePoint2ForHeight(_ height: Double, viewport: CalipersViewport) -> CGPoint {
        let pointY = Double(crossBarPosition(in: viewport)) - height
        var pointX = height * (sin((Double.pi / 2) - Double(angleBar2)) / sin(Double(angleBar2)))
        pointX += Double(bar1Position(in: viewport))
        return CGPoint(x: pointX, y: pointY)
    }
    
    func angleInSouthernHemisphere(_ angle:CGFloat) -> Bool {
        return (0 < Double(angle) && Double(angle) < Double.pi)
    }
  
    
}
