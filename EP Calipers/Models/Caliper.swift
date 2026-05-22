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

enum CaliperComponent {
    case leftBar
    case rightBar
    case crossBar
    case lowerBar
    case upperBar
    case apex
    case noComponent
}

enum MovementDirection {
    case up
    case down
    case left
    case right
    case stationary
}

enum TextPosition: Int {
    case centerAbove
    case centerBelow
    case left
    case right
    case top
    case bottom
}

class Caliper: NSObject {

    let delta: Double = 20.0   // TODO: need documentation, ? rename
    let minDistanceForMarch: CGFloat = 20
    static let maxMarchingComponents: Int = 20

    let roundToIntString: NSString = "%d %@"
    let roundToFourPlacesString: NSString = "%.4g %@"
    let roundToTenthsString: NSString = "%.1f %@"
    let roundToHundredthsString: NSString = "%.2f %@"
    let noRoundingString: NSString = "%f %@"

    // These variables store the "absolute" positions of the caliper bars
    var _bar1Position: CGFloat = 0
    var _bar2Position: CGFloat = 0
    var _crossBarPosition: CGFloat = 0

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
    var rounding: Rounding
    var requiresCalibration: Bool = true
    var isAngleCaliper:Bool = false
    var isMarching: Bool
    var isTweaking: Bool = false
    var autoPositionText: Bool
    var textPosition: TextPosition
    var chosenComponent: CaliperComponent = .noComponent
    var numberOfMarchingComponants = maxMarchingComponents
    var deemphasizeMarchingComponents = true
    var allowNegativeValues : Bool = true

    init(direction: CaliperDirection, bar1Position: CGFloat, bar2Position: CGFloat,
         crossBarPosition: CGFloat, calibration: Calibration, viewport: CalipersViewport) {

        self.direction = direction
        self.calibration = calibration
        self.color = NSColor.systemBlue
        self.unselectedColor = NSColor.systemBlue
        self.selectedColor = NSColor.systemRed
        self.lineWidth = 2
        self.selected = false
        self.textFont = NSFont(name: "Helvetica Neue Medium", size: 18.0) ?? NSFont.systemFont(ofSize: 18, weight: NSFont.Weight.medium)
        // We'll leave this forced unwrapped optional, if it fails text labels fail anyway.
        self.paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        self.roundMsecRate = true
        self.rounding = .ToInteger
        self.isMarching = false
        self.textPosition = .right
        self.autoPositionText = true
        super.init()

        // Must 'super.init()' before using member functions.
        setBar1Position(bar1Position, in: viewport)
        setBar2Position(bar2Position, in: viewport)
        setCrossBarPosition(crossBarPosition, in: viewport)
    }
    
    convenience override init() {
        self.init(direction: .horizontal, bar1Position: 0.0, bar2Position: 0.0,
                  crossBarPosition: 0, calibration: Calibration(), viewport: .init(magnification: 1.0, offset: .zero))
    }

    private func correctedOffsetBar(in viewport: CalipersViewport) -> CGFloat {
        return direction == .horizontal ? viewport.offset.x : viewport.offset.y
    }

    private func correctedOffsetCrossBar(in viewport: CalipersViewport) -> CGFloat {
        return direction == .horizontal ? viewport.offset.y : viewport.offset.x
    }

    func bar1Position(in viewport: CalipersViewport) -> CGFloat {
        viewport.scaledPosition(fromAbsolutePosition: _bar1Position, axisOffset: correctedOffsetBar(in: viewport))
    }

    func setBar1Position(_ position: CGFloat, in viewport: CalipersViewport) {
        _bar1Position = viewport.absolutePosition(
            fromScaledPosition: position,
            axisOffset: correctedOffsetBar(in: viewport)
        )
    }

    func bar2Position(in viewport: CalipersViewport) -> CGFloat {
        viewport.scaledPosition(fromAbsolutePosition: _bar2Position, axisOffset: correctedOffsetBar(in: viewport))
    }

    func setBar2Position(_ position: CGFloat, in viewport: CalipersViewport) {
        _bar2Position = viewport.absolutePosition(
            fromScaledPosition: position,
            axisOffset: correctedOffsetBar(in: viewport)
        )
    }

    func crossBarPosition(in viewport: CalipersViewport) -> CGFloat {
        viewport.scaledPosition(fromAbsolutePosition: _crossBarPosition, axisOffset: correctedOffsetCrossBar(in: viewport))
    }

    func setCrossBarPosition(_ position: CGFloat, in viewport: CalipersViewport) {
        _crossBarPosition = viewport.absolutePosition(
            fromScaledPosition: position,
            axisOffset: correctedOffsetCrossBar(in: viewport)
        )
    }

    // set slightly different position for each new caliper
    func setInitialPositionInRect(_ rect: CGRect, in viewport: CalipersViewport) {
        // no static func variables in Swift :(
        struct Holder {
            static var differential: CGFloat = 0
        }

        switch direction {
        case .horizontal:
            setBar1Position((rect.size.width / 3) + Holder.differential, in: viewport)
            setBar2Position(((2 * rect.size.width) / 3) + Holder.differential, in: viewport)
            setCrossBarPosition((rect.size.height / 2) + Holder.differential, in: viewport)
        case .vertical:
            setBar1Position((rect.size.height / 3) + Holder.differential, in: viewport)
            setBar2Position(((2 * rect.size.height) / 3) + Holder.differential, in: viewport)
            setCrossBarPosition((rect.size.width / 3) + Holder.differential, in: viewport)
        }

        Holder.differential += 15
        if Holder.differential > 80 {
            Holder.differential = 0
        }
    }

    func drawWithContext(_ context: CGContext, inRect rect:CGRect, viewport: CalipersViewport) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)

        if self.direction == .horizontal {
            setCrossBarPosition(CGFloat(fmin(Double(crossBarPosition(in: viewport)), Double(rect.size.height) - delta)), in: viewport)
            setCrossBarPosition(CGFloat(fmax(Double(crossBarPosition(in: viewport)), delta)), in: viewport)
            context.move(to: CGPoint(x: bar1Position(in: viewport), y: 0));
            context.addLine(to: CGPoint(x: bar1Position(in: viewport), y: rect.size.height))
            context.move(to: CGPoint(x: bar2Position(in: viewport), y: 0))
            context.addLine(to: CGPoint(x: bar2Position(in: viewport), y: rect.size.height))
            context.move(to: CGPoint(x: bar2Position(in: viewport), y: crossBarPosition(in: viewport)))
            context.addLine(to: CGPoint(x: bar1Position(in: viewport), y: crossBarPosition(in: viewport)))

        } else {    // vertical caliper
            setCrossBarPosition(CGFloat(fmin(Double(crossBarPosition(in: viewport)), Double(rect.size.width) - delta)), in: viewport)
            setCrossBarPosition(CGFloat(fmax(Double(crossBarPosition(in: viewport)), delta)), in: viewport)
            context.move(to: CGPoint(x: 0, y: bar1Position(in: viewport)))
            context.addLine(to: CGPoint(x: rect.size.width, y: bar1Position(in: viewport)))
            context.move(to: CGPoint(x: 0, y: bar2Position(in: viewport)))
            context.addLine(to: CGPoint(x: rect.size.width, y: bar2Position(in: viewport)))
            context.move(to: CGPoint(x: crossBarPosition(in: viewport), y: bar2Position(in: viewport)))
            context.addLine(to: CGPoint(x: crossBarPosition(in: viewport), y: bar1Position(in: viewport)))
        }
        context.strokePath()
        if isMarching && isTimeCaliper() {
            drawMarchingCalipers(context, inRect: rect, viewport: viewport)
        }
        // TODO: investigate why optimizeTextPosition is set to true.  Is it a Parameter?
        caliperText(rect: rect, textPosition: textPosition, viewport: viewport, optimizeTextPosition: true)
        drawChosenComponent(context, inRect: rect, viewport: viewport)
    }

    // could be calculated property
    func getChosenComponentColor() -> CGColor {
        let chosenComponentColor: NSColor
        if selected {
            chosenComponentColor = unselectedColor
        }
        else {
            chosenComponentColor = selectedColor
        }
        return chosenComponentColor.cgColor
    }

    func drawChosenComponent(_ context: CGContext, inRect rect: CGRect, viewport: CalipersViewport) {
        guard chosenComponent != .noComponent, isTweaking else { return }
        context.setStrokeColor(getChosenComponentColor())

        switch self.chosenComponent {
        case .leftBar:
            context.move(to: CGPoint(x: bar1Position(in: viewport), y: rect.size.height))
            context.addLine(to: CGPoint(x: bar1Position(in: viewport), y: 0))
        case .lowerBar:
            context.move(to: CGPoint(x: 0, y: bar1Position(in: viewport)))
            context.addLine(to: CGPoint(x: rect.size.width, y: bar1Position(in: viewport)))
        case .rightBar:
            context.move(to: CGPoint(x: bar2Position(in: viewport), y: rect.size.height))
            context.addLine(to: CGPoint(x: bar2Position(in: viewport), y: 0))
        case .upperBar:
            context.move(to: CGPoint(x: 0, y: bar2Position(in: viewport)))
            context.addLine(to: CGPoint(x: rect.size.width, y: bar2Position(in: viewport)))
        case .crossBar:
            if (direction == .horizontal) {
                context.move(to: CGPoint(x: bar2Position(in: viewport), y: crossBarPosition(in: viewport)))
                context.addLine(to: CGPoint(x: bar1Position(in: viewport), y: crossBarPosition(in: viewport)))
            }
            else {
                context.move(to: CGPoint(x: crossBarPosition(in: viewport), y: bar2Position(in: viewport)))
                context.addLine(to: CGPoint(x: crossBarPosition(in: viewport), y: bar1Position(in: viewport)))
            }
        default:
            break
        }
        context.strokePath()
    }

    func getSelectedCaliperComponent(atPoint p: NSPoint, in viewport: CalipersViewport) -> CaliperComponent {
        if pointNearBar1(p: p, in: viewport) {
            return direction == .horizontal ? .leftBar : .lowerBar
        }
        else if pointNearBar2(p: p, in: viewport) {
            return direction == .horizontal ? .rightBar : .upperBar
        }
        else if pointNearCrossBar(p, in: viewport) {
            return isAngleCaliper ? .apex : .crossBar
        }
        else {
            return .noComponent
        }
    }

    func isTimeCaliper() -> Bool {
        return direction == .horizontal && !isAngleCaliper
    }
    
    func drawMarchingCalipers(_ context: CGContext, inRect rect:CGRect, viewport: CalipersViewport) {
        let difference = abs(bar1Position(in: viewport) - bar2Position(in: viewport))
        if difference < minDistanceForMarch {
            return
        }
        let greaterBar = fmax(bar1Position(in: viewport), bar2Position(in: viewport))
        let lesserBar = fmin(bar1Position(in: viewport), bar2Position(in: viewport))

        var biggerBars = Array<CGFloat>(repeating: 0, count: numberOfMarchingComponants)
        var smallerBars = Array<CGFloat>(repeating: 0, count: numberOfMarchingComponants)
        var point = greaterBar + difference
        var index = 0
        while point < rect.size.width && index < numberOfMarchingComponants {
            biggerBars[index] = point
            point += difference
            index += 1
        }
        let maxBiggerBars = index
        index = 0
        point = lesserBar - difference
        while point > 0 && index < numberOfMarchingComponants {
            smallerBars[index] = point
            point -= difference
            index += 1
        }
        let maxSmallerBars = index
        // draw them
        var i = 0
        while i < maxBiggerBars {
            context.move(to: CGPoint(x: biggerBars[i], y: 0))
            context.addLine(to: CGPoint(x: biggerBars[i], y: rect.size.height))
            i += 1
        }
        i = 0
        while i < maxSmallerBars {
            context.move(to: CGPoint(x: smallerBars[i], y: 0))
            context.addLine(to: CGPoint(x: smallerBars[i], y: rect.size.height))
            i += 1
        }
        if deemphasizeMarchingComponents {
            context.setLineWidth(fmax(lineWidth - 1, 1))
        } 
        context.strokePath()
    }
    
    func caliperText(rect: CGRect, textPosition: TextPosition, viewport: CalipersViewport, optimizeTextPosition: Bool) {
        let text = measurement(in: viewport)
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .center
        var attributes = [NSAttributedString.Key: Any]()
        attributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: color
            ]
        let size = text.size(withAttributes: attributes)
        let textRect = caliperTextPosition(left: fmin(bar1Position(in: viewport), bar2Position(in: viewport)), right: fmax(bar1Position(in: viewport), bar2Position(in: viewport)), center: crossBarPosition(in: viewport), size: size, rect: rect, textPosition: textPosition, optimizeTextPosition: optimizeTextPosition)
        text.draw(in: textRect, withAttributes: attributes)
    }

    func caliperTextPosition(left: CGFloat, right: CGFloat, center: CGFloat,
                             size: CGSize, rect: CGRect,
                             textPosition: TextPosition,
                             optimizeTextPosition: Bool) -> CGRect {
        // assumes X is center of text block and y is text baseline
        var textOrigin = CGPoint()
        var origin = CGPoint()
        let textHeight = size.height
        let textWidth = size.width
        let yOffset: CGFloat = 5
        let xOffset: CGFloat = 5
        let optimizedPosition = optimizedTextPosition(left: left, right: right, center: center, rect: rect, textPosition: textPosition, textWidth: textWidth, textHeight: textHeight, optimizeTextPosition: optimizeTextPosition)
        if direction == .horizontal {
            // Guard against the margin obsucring left and right labels.
            origin.y = center
            switch optimizedPosition {
            case .centerAbove:
                origin.x = left + (right - left) / 2
                textOrigin.x = origin.x
                textOrigin.y = origin.y + yOffset
            case .centerBelow:
                origin.x = left + (right - left) / 2
                textOrigin.x = origin.x
                textOrigin.y = origin.y - yOffset - textHeight
            case .left:
                origin.x = left
                textOrigin.x = origin.x - xOffset - textWidth / 2
                textOrigin.y = origin.y + yOffset
            case .right:
                origin.x = right
                textOrigin.x = origin.x + xOffset + textWidth / 2
                textOrigin.y = origin.y + yOffset
            default:
                assertionFailure("Invalid text position.")
            }
        }
        else { // vertical caliper
            textOrigin.y = left + (right - left) / 2 - textHeight / 2
            switch optimizedPosition {
            case .left:
                textOrigin.x = center - xOffset - textWidth / 2;
            case .right:
                textOrigin.x = center + xOffset + textWidth / 2;
            case .top:
                textOrigin.y = right + yOffset;
                textOrigin.x = center;
            case .bottom:
                textOrigin.y = left - yOffset - textHeight;
                textOrigin.x = center;
            default:
                assertionFailure("Invalid text position.")
            }
        }
            // Adjust rectangle so that it is centered
        return CGRect(x: textOrigin.x - textWidth / 2,
                      y: textOrigin.y,
                      width: textWidth,
                      height: textHeight)
    }

    private func optimizedTextPosition(left: CGFloat,
                                       right: CGFloat,
                                       center: CGFloat,
                                       rect: CGRect,
                                       textPosition: TextPosition,
                                       textWidth: CGFloat,
                                       textHeight: CGFloat,
                                       optimizeTextPosition: Bool) -> TextPosition {
        // Just use textPosition if we're not auto-positioning the text.
        if !autoPositionText || !optimizeTextPosition {
            return textPosition
        }
        // Allow a few pixels margin so that screen edges never obscures text
        let offset: CGFloat = 4
        var optimizedPosition = textPosition
        if direction == .horizontal {
            switch optimizedPosition {
            case .centerAbove:
                fallthrough
            case .centerBelow:
                // Avoid squeezing label.
                if textWidth + offset > right - left {
                    if textWidth + right + offset > rect.width {
                        optimizedPosition = .left
                    }
                    else {
                        optimizedPosition = .right
                    }
                }
            case .left:
                if textWidth + offset > left {
                    if textWidth + right + offset > rect.width {
                        optimizedPosition = .centerAbove
                    }
                    else {
                        optimizedPosition = .right
                    }
                }
            case .right:
                if textWidth + right + offset > rect.width {
                    if textWidth + offset > left {
                        optimizedPosition = .centerAbove
                    }
                    else {
                        optimizedPosition = .left
                    }
                }
            default:
                // should not be here, but least painful thing to do is...
                optimizedPosition = textPosition
            }
        }
        else if direction == .vertical {
            // watch for squeeze
            if (optimizedPosition == .left || optimizedPosition == .right) && textHeight + offset > right - left {
                if left - textHeight - offset < 0 {
                    optimizedPosition = .top
                }
                else {
                    optimizedPosition = .bottom
                }
            }
            else {
                switch optimizedPosition {
                case .left:
                    if textWidth + offset > center {
                        optimizedPosition = .right
                    }
                case .right:
                    if textWidth + center + offset > rect.width {
                        optimizedPosition = .left
                    }
                case .top:
                    if right + textHeight + offset > rect.height {
                        if left - textHeight - offset < 0 {
                            optimizedPosition = .right
                        }
                        else {
                            optimizedPosition = .bottom
                        }
                    }
                case .bottom:
                    if left - textHeight - offset < 0 {
                        if right + textHeight + offset > rect.height {
                            optimizedPosition = .right
                        }
                        else {
                            optimizedPosition = .top
                        }
                    }
                default:
                    optimizedPosition = textPosition
                }
            }
        }
        return optimizedPosition
    }
    
    func barCoord(_ p: CGPoint) -> CGFloat {
        return (direction == .horizontal ? p.x : p.y)
    }
    
//    func rect(_ containerRect: CGRect) -> CGRect {
//        if direction == .horizontal {
//            return CGRect(x: bar1Position, y: containerRect.origin.y, width: self.bar2Position - bar1Position, height: containerRect.size.height)
//        }
//        else { // vertical caliper
//            return CGRect(x: 0, y: bar1Position, width: containerRect.size.width, height: bar2Position - bar1Position)
//        }
//    }

    func measurement(in viewport: CalipersViewport) -> String {
        var s: String
        var format: NSString
        if calibration.unitsAreMsecOrRate {
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
            if (rounding == .ToInteger) {
                s = NSString.localizedStringWithFormat(format, Int(round(calibratedResult(in: viewport))), calibration.units) as String
            }
            else {
                s = NSString.localizedStringWithFormat(format, calibratedResult(in: viewport), calibration.units) as String
            }
        }
        else {
            s = NSString.localizedStringWithFormat(roundToFourPlacesString, calibratedResult(in: viewport), calibration.units) as String
        }
        return s
    }
    
    func calibratedResult(in viewport: CalipersViewport) -> Double {
        var result = intervalResult(in: viewport)
        if result != 0 && calibration.displayRate && calibration.canDisplayRate {
            result = rateResult(result)
        }
        return result
    }

    func points(in viewport: CalipersViewport) -> CGFloat {
        return bar2Position(in: viewport) - bar1Position(in: viewport)
    }
    
    func intervalResult(in viewport: CalipersViewport) -> Double {
        let result = Double(points(in: viewport)) * calibration.multiplier(currentMagnification: viewport.magnification)
        if allowNegativeValues {
            return result
        }
        return abs(result)
    }
    
    func rateResult(_ interval: Double) -> Double {
        let absInterval = abs(interval)
        if absInterval != 0 {
            if calibration.unitsAreMsec {
                return 60000.0 / absInterval
            }
            if calibration.unitsAreSeconds {
                return 60.0 / absInterval
            }
        }
        return absInterval
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
    
    func pointNearBar1(p: CGPoint, in viewport: CalipersViewport) -> Bool {
        return pointNearBar(p, forBarPosition: bar1Position(in: viewport))
    }
    
    func pointNearBar2(p: CGPoint, in viewport: CalipersViewport) -> Bool {
        return pointNearBar(p, forBarPosition: bar2Position(in: viewport))
    }
    
    func pointNearCrossBar(_ p: CGPoint, in viewport: CalipersViewport) -> Bool {
        var nearBar = false
        let adjustedDelta = delta + 5  // make crossbar delta a little larger
        if direction == .horizontal {
            nearBar = (Double(p.x) > fmin(Double(bar1Position(in: viewport)), Double(bar2Position(in: viewport))) &&
                       Double(p.x) < fmax(Double(bar2Position(in: viewport)), Double(bar1Position(in: viewport))) &&
                       Double(p.y) > Double(crossBarPosition(in: viewport)) - adjustedDelta && Double(p.y) < Double(crossBarPosition(in: viewport)) + adjustedDelta)
        }
        else {
            nearBar = (Double(p.y) > fmin(Double(bar1Position(in: viewport)), Double(bar2Position(in: viewport))) &&
                       Double(p.y) < fmax(Double(bar2Position(in: viewport)), Double(bar1Position(in: viewport))) &&
                       Double(p.x) > Double(crossBarPosition(in: viewport)) - adjustedDelta && Double(p.x) < Double(crossBarPosition(in: viewport)) + adjustedDelta)
        }
        return nearBar
    }
    
    func pointNearCaliper(_ p: CGPoint, in viewport: CalipersViewport) -> Bool {
        return pointNearCrossBar(p, in: viewport) || pointNearBar1(p: p, in: viewport) || pointNearBar2(p: p, in: viewport)
    }
    
    func moveCrossBar(delta: CGPoint, in viewport: CalipersViewport) {
        setBar1Position(bar1Position(in: viewport) + delta.x, in: viewport)
        setBar2Position(bar2Position(in: viewport) + delta.x, in: viewport)
        // origin is lower left in Cocoa
        setCrossBarPosition(crossBarPosition(in: viewport) - delta.y, in: viewport)
    }
    
    func moveBar1(delta: CGPoint, forLocation location: CGPoint, in viewport: CalipersViewport) {
        // location parameter unused here, but is in subclass
        setBar1Position(bar1Position(in: viewport) + delta.x, in: viewport)
    }
    
    func moveBar2(delta: CGPoint, forLocation location: CGPoint, in viewport: CalipersViewport) {
        setBar2Position(bar2Position(in: viewport) + delta.x, in: viewport)
    }
    
    class func componentName(_ component: CaliperComponent) -> String? {
        let s: String?
        switch (component) {
        case .leftBar:
            s = NSLocalizedString("left bar", comment:"") as String
        case .rightBar:
            s = NSLocalizedString("right bar", comment:"") as String
        case .crossBar:
            s = NSLocalizedString("crossbar", comment:"") as String
        case .upperBar:
            s = NSLocalizedString("upper bar", comment:"") as String
        case .lowerBar:
            s = NSLocalizedString("lower bar", comment:"") as String
        case .apex:
            s = NSLocalizedString("apex", comment:"") as String
        default:
            s = nil
        }
        return s
    }

    func moveBarInDirection(movementDirection: MovementDirection, distance: CGFloat, in viewport: CalipersViewport) {
        moveBarInDirection(movementDirection: movementDirection, distance: distance, forComponent: chosenComponent, in: viewport)
    }

    func moveBarInDirection(movementDirection: MovementDirection, distance: CGFloat, forComponent component: CaliperComponent, in viewport: CalipersViewport) {
        if component == .noComponent {
            return
        }
        let adjustedComponent = moveCrossbarInsteadOfSideBar(movementDirection: movementDirection, component: component) ? .crossBar : component
        if adjustedComponent == .crossBar {
            moveCrosbarInDirection(movementDirection: movementDirection, distance: distance, in: viewport)
            return
        }
        var delta = distance
        if movementDirection == .down || movementDirection == .left {
            delta = -delta
        }
        switch (adjustedComponent) {
        case .leftBar, .lowerBar:
            setBar1Position(bar1Position(in: viewport) + delta, in: viewport)
        case .rightBar, .upperBar:
            setBar2Position(bar2Position(in: viewport) + delta, in: viewport)
        default:
            break
        }
    }
    
    // E.g. see if you are doing up and down instead of left and right for a horizontal caliper sidebar
    func moveCrossbarInsteadOfSideBar(movementDirection: MovementDirection, component: CaliperComponent) -> Bool {
        if component == .crossBar || component == .apex {
            return false
        }
        return (direction == .horizontal && (movementDirection == .up || movementDirection == .down)) ||
            (direction == .vertical && (movementDirection == .left || movementDirection == .right))
    }
    
    func moveCrosbarInDirection(movementDirection: MovementDirection, distance: CGFloat, in viewport: CalipersViewport) {
        var movementDirection = movementDirection
        if direction == .vertical {
            movementDirection = swapDirection(movementDirection)
        }
        switch (movementDirection) {
        case .up:
            setCrossBarPosition(crossBarPosition(in: viewport) + distance, in: viewport)
        case .down:
            setCrossBarPosition(crossBarPosition(in: viewport) - distance, in: viewport)
        case .left:
            setBar1Position(bar1Position(in: viewport) - distance, in: viewport)
            setBar2Position(bar2Position(in: viewport) - distance, in: viewport)
        case .right:
            setBar1Position(bar1Position(in: viewport) + distance, in: viewport)
            setBar2Position(bar2Position(in: viewport) + distance, in: viewport)
        default:
            break
        }

    }
    
    func swapDirection(_ movementDirection: MovementDirection) -> MovementDirection {
        switch (movementDirection) {
        case .left:
            return .down
        case .right:
            return .up
        case .up:
            return .right
        case .down:
            return .left
        default:
            return .stationary;
        }
    }
    
}
