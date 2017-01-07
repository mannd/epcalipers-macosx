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
    
    init() {
        super.init(direction: .horizontal, bar1Position: 100.0, bar2Position: 100.0, crossBarPosition: 100.0)
        requiresCalibration = false
        isAngleCaliper = true
    }
    
    override func setInitialPositionInRect(_ rect: CGRect) {
        struct Holder {
            static var differential: CGFloat = 0
        }
        bar1Position = (rect.size.width / 3) * Holder.differential
        bar2Position = bar1Position
        crossBarPosition = (rect.size.height / 3) * Holder.differential * 1.5
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
        let text = measurement()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = (direction == .horizontal ? .center : .left)
        let attributes = [
            NSFontAttributeName: textFont,
            NSParagraphStyleAttributeName: paragraphStyle,
            NSForegroundColorAttributeName: color
            ] as [String : Any]
        if direction == .horizontal {
            // the math here insures that the label doesn't get so small that it can't be read
            text.draw(in: CGRect(x: (bar2Position > bar1Position ? bar1Position - 25: bar2Position - 25), y: crossBarPosition - 20,  width: fmax(50.0, fabs(bar2Position - bar1Position) + 50), height: 20),  withAttributes:attributes);
        }
        else {
            text.draw(in: CGRect(x: crossBarPosition + 5, y: bar1Position + (bar2Position - bar1Position) / 2, width: 140, height: 20), withAttributes:attributes);
        }
        
    }
    
    func endPointForPosition(p: CGPoint, angle: CGFloat, length: CGFloat) -> CGPoint {
        let endX = cos(angle) * length + p.x
        let endY = sin(angle) * length + p.y
        let endPoint = CGPoint(x: endX, y: endY)
        return endPoint
    }

   
    
}
