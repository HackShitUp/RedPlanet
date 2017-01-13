//  Converted with Swiftify v1.0.6221 - https://objectivec2swift.com/
//
//  JotDrawView.h
//  jot
//
//  Created by Laura Skelton on 4/30/15.
//
//
import UIKit
import Foundation
/**
 *  Private class to handle touch drawing. Change the properties
 *  in a JotViewController instance to configure this private class.
 */
class JotDrawView: UIView {
    /**
     *  Set to YES if you want the stroke width to be constant,
     *  NO if the stroke width should vary depending on drawing
     *  speed.
     *
     *  @note Set drawingConstantStrokeWidth in JotViewController
     *  to control this setting.
     */
    var isConstantStrokeWidth: Bool {
        get {
            // TODO: add getter implementation
        }
        set(constantStrokeWidth) {
            if isConstantStrokeWidth != isConstantStrokeWidth {
                self.isConstantStrokeWidth = isConstantStrokeWidth
                self.bezierPath() = nil
                self.pointsArray.removeAll()
                self.pointsCounter = 0
            }
        }
    }
    /**
     *  Sets the stroke width if constantStrokeWidth is true,
     *  or sets the base strokeWidth for variable drawing paths.
     *
     *  @note Set drawingStrokeWidth in JotViewController
     *  to control this setting.
     */
    var strokeWidth: CGFloat = 0.0
    /**
     *  Sets the stroke color. Each path can have its own stroke color.
     *
     *  @note Set drawingColor in JotViewController
     *  to control this setting.
     */
    var strokeColor: UIColor! {
        get {
            // TODO: add getter implementation
        }
        set(strokeColor) {
            self.strokeColor = strokeColor
            self.bezierPath() = nil
        }
    }
    /**
     *  Clears all paths from the drawing, giving a blank slate.
     *
     *  @note Call clearDrawing or clearAll in JotViewController
     *  to trigger this method.
     */

    func clearDrawing() {
        self.cachedImage = nil
        self.pathsArray.removeAll()
        self.bezierPath() = nil
        self.pointsCounter = 0
        self.pointsArray.removeAll()
        self.lastVelocity = self.initialVelocity
        self.lastWidth = self.strokeWidth
        UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve, animations: {() -> Void in
            self.setNeedsDisplay()
        }, completion: { _ in })
    }
    /**
     *  Tells the JotDrawView to handle a touchesBegan event.
     *
     *  @param touchPoint The point in this view's coordinate
     *  system where the touch began.
     *
     *  @note This method is triggered by the JotDrawController's
     *  touchesBegan event.
     */

    func drawTouchBegan(at touchPoint: CGPoint) {
        self.lastVelocity = self.initialVelocity
        self.lastWidth = self.strokeWidth
        self.pointsCounter = 0
        self.pointsArray.removeAll()
        self.pointsArray.append(JotTouchPoint.withPoint(touchPoint))
    }
    /**
     *  Tells the JotDrawView to handle a touchesMoved event.
     *
     *  @param touchPoint The point in this view's coordinate
     *  system where the touch moved.
     *
     *  @note This method is triggered by the JotDrawController's
     *  touchesMoved event.
     */

    func drawTouchMoved(to touchPoint: CGPoint) {
        self.pointsCounter += 1
        self.pointsArray.append(JotTouchPoint.withPoint(touchPoint))
        if self.pointsCounter == 4 {
            self.pointsArray[3] = JotTouchPoint.withPoint(CGPoint(x: CGFloat((self.pointsArray[2].cgPoint().x + self.pointsArray[4].cgPoint().x) / 2.0), y: CGFloat((self.pointsArray[2].cgPoint().y + self.pointsArray[4].cgPoint().y) / 2.0)))
            self.bezierPath().startPoint = self.pointsArray[0].cgPoint()
            self.bezierPath().endPoint = self.pointsArray[3].cgPoint()
            self.bezierPath().controlPoint1 = self.pointsArray[1].cgPoint()
            self.bezierPath().controlPoint2 = self.pointsArray[2].cgPoint()
            if self.isConstantStrokeWidth {
                self.bezierPath().startWidth = self.strokeWidth
                self.bezierPath().endWidth = self.strokeWidth
            }
            else {
                var velocity: CGFloat? = (self.pointsArray[3] as? JotTouchPoint)?.velocity(from: (self.pointsArray[0] as? JotTouchPoint))
                velocity = (+((1.0 - kJotVelocityFilterWeight) * self.lastVelocity) as? kJotVelocityFilterWeight)
                var strokeWidth: CGFloat = self.strokeWidth(forVelocity: velocity)
                self.bezierPath().startWidth = self.lastWidth
                self.bezierPath().endWidth = strokeWidth
                self.lastWidth = strokeWidth
                self.lastVelocity = velocity
            }
            self.pointsArray[0] = self.pointsArray[3]
            self.pointsArray[1] = self.pointsArray[4]
            self.drawBitmap()
            self.pointsArray.removeLast()
            self.pointsArray.removeLast()
            self.pointsArray.removeLast()
            self.pointsCounter = 1
        }
    }
    /**
     *  Tells the JotDrawView to handle a touchesEnded event.
     *
     *  @note This method is triggered by the JotDrawController's
     *  touchesEnded event.
     */

    func drawTouchEnded() {
        self.drawBitmap()
        self.lastVelocity = self.initialVelocity
        self.lastWidth = self.strokeWidth
    }
    /**
     *  Overlays the drawing on the given background image, rendering
     *  the drawing at the full resolution of the image.
     *
     *  @param image The background image to draw on top of.
     *
     *  @return An image of the rendered drawing on the background image.
     *
     *  @note Call drawOnImage: in JotViewController
     *  to trigger this method.
     */

    func draw(on image: UIImage) -> UIImage {
        return self.drawAllPathsImage(with: image.size, backgroundImage: image)
    }
    /**
     *  Renders the drawing at full resolution for the given size.
     *
     *  @param size The size of the image to return.
     *
     *  @return An image of the rendered drawing.
     *
     *  @note Call renderWithSize: in JotViewController
     *  to trigger this method.
     */

    func renderDrawing(with size: CGSize) -> UIImage {
        return self.drawAllPathsImage(with: size, backgroundImage: nil)
    }


    convenience override init() {
        if (super.init()) {
            self.backgroundColor = UIColor.clear
            self.strokeWidth = 10.0
            self.strokeColor = UIColor.black
            self.pathsArray = [Any]()
            self.isConstantStrokeWidth = false
            self.pointsArray = [Any]()
            self.initialVelocity = kJotInitialVelocity
            self.lastVelocity = initialVelocity
            self.lastWidth = strokeWidth
            self.userInteractionEnabled = false
        }
    }
// MARK: - Undo
// MARK: - Properties
// MARK: - Draw Touches
// MARK: - Drawing

    func drawBitmap() {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale())
        if self.cachedImage {
            self.cachedImage.draw(at: CGPoint.zero)
        }
        self.bezierPath().jotDraw()
        self.bezierPath() = nil
        if self.pointsArray.count == 1 {
            var touchPoint: JotTouchPoint? = self.pointsArray.first
            touchPoint?.strokeColor = self.strokeColor
            touchPoint?.strokeWidth = 1.5 * self.strokeWidth(forVelocity: 1.0)
            self.pathsArray.append(touchPoint)
            touchPoint?.strokeColor?.setFill()
            JotTouchBezier.jotDraw(touchPoint?.cgPointValue(), withWidth: touchPoint?.strokeWidth)
        }
        self.cachedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        self.cachedImage.draw(in: rect)
        self.bezierPath().jotDraw()
    }

    func strokeWidth(forVelocity velocity: CGFloat) -> CGFloat {
        return self.strokeWidth - (self.strokeWidth * (1.0 - kJotRelativeMinStrokeWidth)) / (1.0 + CGFloat(pow(Double(M_E), Double(-((velocity - self.initialVelocity) / self.initialVelocity)))))
    }

    override func bezierPath() -> JotTouchBezier {
        if !bezierPath {
            self.bezierPath = JotTouchBezier.withColor(self.strokeColor)
            self.pathsArray.append(bezierPath)
            self.bezierPath.isConstantWidth = self.isConstantStrokeWidth
        }
        return bezierPath
    }
// MARK: - Image Rendering

    func drawAllPathsImage(with size: CGSize, backgroundImage: UIImage) -> UIImage {
        var scale: CGFloat = size.width / self.bounds.width
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, scale)
        backgroundImage.draw(in: CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(self.bounds.width), height: CGFloat(self.bounds.height)))
        self.drawAllPaths()
        var drawnImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return UIImage(cgImage: drawnImage?.cgImage, scale: 1.0, orientation: drawnImage?.imageOrientation)!
    }

    func drawAllPaths() {
        for path: NSObject in self.pathsArray {
            if (path is JotTouchBezier) {
                (path as? JotTouchBezier)?.jotDraw()
            }
            else if (path is JotTouchPoint) {
                (path as? JotTouchPoint)?.strokeColor?.setFill()
                JotTouchBezier.jotDraw((path as? JotTouchPoint)?.cgPointValue(), withWidth: (path as? JotTouchPoint)?.strokeWidth())
            }
        }
    }

    var cachedImage: UIImage!
    var pathsArray = [Any]()
    var bezierPath: JotTouchBezier! {
        if bezierPath == nil {
                self.bezierPath = JotTouchBezier.withColor(self.strokeColor)
                self.pathsArray.append(bezierPath)
                self.bezierPath.isConstantWidth = self.isConstantStrokeWidth
            }
            return bezierPath
    }
    var pointsArray = [Any]()
    var pointsCounter: Int = 0
    var lastVelocity: CGFloat = 0.0
    var lastWidth: CGFloat = 0.0
    var initialVelocity: CGFloat = 0.0
}
//
//  JotDrawView.m
//  jot
//
//  Created by Laura Skelton on 4/30/15.
//
//
let kJotVelocityFilterWeight: CGFloat = 0.9

let kJotInitialVelocity: CGFloat = 220.0

let kJotRelativeMinStrokeWidth: CGFloat = 0.4