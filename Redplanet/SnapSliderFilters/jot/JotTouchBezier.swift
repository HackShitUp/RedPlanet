//  Converted with Swiftify v1.0.6221 - https://objectivec2swift.com/
//
//  JotTouchBezier.h
//  jot
//
//  Created by Laura Skelton on 4/30/15.
//
//
import UIKit
import Foundation
/**
 *  Private class to handle drawing variable-width cubic bezier paths in a JotDrawView.
 */
class JotTouchBezier: NSObject {
    /**
     *  The start point of the cubic bezier path.
     */
    var startPoint = CGPoint.zero
    /**
     *  The end point of the cubic bezier path.
     */
    var endPoint = CGPoint.zero
    /**
     *  The first control point of the cubic bezier path.
     */
    var controlPoint1 = CGPoint.zero
    /**
     *  The second control point of the cubic bezier path.
     */
    var controlPoint2 = CGPoint.zero
    /**
     *  The starting width of the cubic bezier path.
     */
    var startWidth: CGFloat = 0.0
    /**
     *  The ending width of the cubic bezier path.
     */
    var endWidth: CGFloat = 0.0
    /**
     *  The stroke color of the cubic bezier path.
     */
    var strokeColor: UIColor!
    /**
     *  YES if the line is a constant width, NO if variable width.
     */
    var isConstantWidth: Bool = false
    /**
     *  Returns an instance of JotTouchBezier with the given stroke color.
     *
     *  @param color       The color to use for drawing the bezier path.
     *
     *  @return An instance of JotTouchBezier
     */

    class func withColor(_ color: UIColor) -> Self {
        var touchBezier = JotTouchBezier()
        touchBezier.strokeColor = color
        return touchBezier
    }
    /**
     *  Draws the JotTouchBezier in the current graphics context, using the
     *  strokeColor and transitioning from the start width to the end width
     *  along the length of the curve.
     */

    func jotDraw() {
        if self.isConstantWidth {
            var bezierPath = UIBezierPath()
            bezierPath.move(to: self.startPoint)
            bezierPath.addCurve(to: self.endPoint, controlPoint1: self.controlPoint1, controlPoint2: self.controlPoint2)
            bezierPath.lineWidth = self.startWidth
            bezierPath.lineCapStyle = kCGLineCapRound
            self.strokeColor.setStroke()
            bezierPath.stroke(withBlendMode: kCGBlendModeNormal, alpha: 1.0)
        }
        else {
            self.strokeColor.setFill()
            var widthDelta: CGFloat = self.endWidth - self.startWidth
            for i in 0..<kJotDrawStepsPerBezier {
                var t = (CGFloat(i)) / CGFloat(kJotDrawStepsPerBezier)
                var tt: CGFloat = t * t
                var ttt: CGFloat = tt * t
                var u: CGFloat = 1.0 - t
                var uu: CGFloat = u * u
                var uuu: CGFloat = uu * u
                var x: CGFloat = uuu * self.startPoint.x
                x += 3 * uu * t * self.controlPoint1.x
                x += 3 * u * tt * self.controlPoint2.x
                x += ttt * self.endPoint.x
                var y: CGFloat = uuu * self.startPoint.y
                y += 3 * uu * t * self.controlPoint1.y
                y += 3 * u * tt * self.controlPoint2.y
                y += ttt * self.endPoint.y
                var pointWidth: CGFloat = self.startWidth + (ttt * widthDelta)
                self.self.jotDraw(CGPoint(x: x, y: y), withWidth: pointWidth)
            }
        }
    }
    /**
     *  Draws a single circle at the given point in the current graphics context,
     *  using the current fillColor of the context and the given width.
     *
     *  @param point       The CGPoint to use as the center of the circle to be drawn.
     *  @param width       The diameter of the circle to be drawn at the given point.
     */

    class func jotDraw(_ point: CGPoint, withWidth width: CGFloat) {
        var context: CGContext? = UIGraphicsGetCurrentContext()
        if context == nil {
            return
        }
        context.fillEllipse(in: CGRect(x: CGFloat(point.x), y: CGFloat(point.y), width: CGFloat(0.0), height: CGFloat(0.0)).insetBy(dx: CGFloat(-width / 2.0), dy: CGFloat(-width / 2.0)))
    }
}
//
//  JotTouchBezier.m
//  jot
//
//  Created by Laura Skelton on 4/30/15.
//
//
let kJotDrawStepsPerBezier: Int = 300