//  Converted with Swiftify v1.0.6221 - https://objectivec2swift.com/
//
//  JotTextView.h
//  jot
//
//  Created by Laura Skelton on 4/30/15.
//
//
import UIKit
import Foundation
/**
 *  Private class to handle text display and gesture interactions.
 *  Change the properties in a JotViewController instance to 
 *  configure this private class.
 */
class JotTextView: UIView {
    /**
     *  The text string the JotTextView is currently displaying.
     *
     *  @note Set textString in JotViewController
     *  to control or read this property.
     */
    var textString: String {
        get {
            // TODO: add getter implementation
        }
        set(textString) {
            if !(textString == textString) {
                self.textString = textString
                var center: CGPoint? = self.textLabel?.center
                self.textLabel?.text = textString
                self.sizeLabel()
                self.textLabel?.center = center
            }
        }
    }
    /**
     *  The color of the text displayed in the JotTextView.
     *
     *  @note Set textColor in JotViewController
     *  to control this property.
     */
    var textColor: UIColor! {
        get {
            // TODO: add getter implementation
        }
        set(textColor) {
            if textColor != textColor {
                self.textColor = textColor
                self.textLabel?.textColor = textColor
            }
        }
    }
    /**
     *  The font of the text displayed in the JotTextView.
     *
     *  @note Set font in JotViewController to control this property.
     *  To change the default size of the font, you must also set the
     *  fontSize property to the desired font size.
     */
    var font: UIFont! {
        get {
            // TODO: add getter implementation
        }
        set(font) {
            if font != font {
                self.font = font
                self.adjustLabelFont()
            }
        }
    }
    /**
     *  The initial font size of the text displayed in the JotTextView. The
     *  displayed text's font size will get proportionally larger or smaller 
     *  than this size if the viewer pinch zooms the text.
     *
     *  @note Set fontSize in JotViewController to control this property,
     *  which overrides the size of the font property.
     */
    var fontSize: CGFloat {
        get {
            // TODO: add getter implementation
        }
        set(fontSize) {
            if fontSize != fontSize {
                self.fontSize = fontSize
                self.adjustLabelFont()
            }
        }
    }
    /**
     *  The alignment of the text displayed in the JotTextView, which only
     *  applies if fitOriginalFontSizeToViewWidth is true.
     *
     *  @note Set textAlignment in JotViewController to control this property,
     *  which will be ignored if fitOriginalFontSizeToViewWidth is false.
     */
    var textAlignment: NSTextAlignment {
        get {
            // TODO: add getter implementation
        }
        set(textAlignment) {
            if textAlignment != textAlignment {
                self.textAlignment = textAlignment
                self.textLabel?.textAlignment = self.textAlignment
                self.sizeLabel()
            }
        }
    }
    /**
     *  The initial insets of the text displayed in the JotTextView, which only
     *  applies if fitOriginalFontSizeToViewWidth is true. If fitOriginalFontSizeToViewWidth
     *  is true, then initialTextInsets sets the initial insets of the displayed text relative to the
     *  full size of the JotTextView. The user can resize, move, and rotate the text from that
     *  starting position, but the overall proportions of the text will stay the same.
     *
     *  @note Set initialTextInsets in JotViewController to control this property,
     *  which will be ignored if fitOriginalFontSizeToViewWidth is false.
     */
    var initialTextInsets: UIEdgeInsets {
        get {
            // TODO: add getter implementation
        }
        set(initialTextInsets) {
            if !UIEdgeInsetsEqualToEdgeInsets(initialTextInsets, initialTextInsets) {
                self.initialTextInsets = initialTextInsets
                self.sizeLabel()
            }
        }
    }
    /**
     *  If fitOriginalFontSizeToViewWidth is true, then the text will wrap to fit within the width
     *  of the JotTextView, with the given initialTextInsets, if any. The layout will reflect
     *  the textAlignment property as well as the initialTextInsets property. If this is false,
     *  then the text will be displayed as a single line, and will ignore any initialTextInsets and
     *  textAlignment settings
     *
     *  @note Set fitOriginalFontSizeToViewWidth in JotViewController to control this property.
     */
    var isFitOriginalFontSizeToViewWidth: Bool {
        get {
            // TODO: add getter implementation
        }
        set(fitOriginalFontSizeToViewWidth) {
            if isFitOriginalFontSizeToViewWidth != isFitOriginalFontSizeToViewWidth {
                self.isFitOriginalFontSizeToViewWidth = isFitOriginalFontSizeToViewWidth
                self.textLabel?.numberOfLines = (isFitOriginalFontSizeToViewWidth ? 0 : 1)
                self.sizeLabel()
            }
        }
    }
    /**
     *  Clears text from the drawing, giving a blank slate.
     *
     *  @note Call clearText or clearAll in JotViewController
     *  to trigger this method.
     */

    func clearText() {
        self.scale() = 1.0
        self.textLabel?.transform = CGAffineTransform.identity
        self.textString = ""
    }
    /**
     *  Overlays the text on the given background image.
     *
     *  @param image The background image to render text on top of.
     *
     *  @return An image of the rendered drawing on the background image.
     *
     *  @note Call drawOnImage: in JotViewController
     *  to trigger this method.
     */

    func drawText(on image: UIImage) -> UIImage {
        return self.drawTextImage(with: image.size, backgroundImage: image)
    }
    /**
     *  Renders the text overlay at full resolution for the given size.
     *
     *  @param size The size of the image to return.
     *
     *  @return An image of the rendered text.
     *
     *  @note Call renderWithSize: in JotViewController
     *  to trigger this method.
     */

    func renderDraw(with size: CGSize) -> UIImage {
        return self.drawTextImage(with: size, backgroundImage: nil)
    }
    /**
     *  Tells the JotTextView to handle a pan gesture.
     *
     *  @param recognizer The pan gesture recognizer to handle.
     *
     *  @note This method is triggered by the JotDrawController's
     *  internal pan gesture recognizer.
     */

    func handlePanGesture(_ recognizer: UIGestureRecognizer) {
        if !(recognizer is UIPanGestureRecognizer) {
            return
        }
        switch recognizer.state {
            case .began:
                self.referenceCenter = self.textLabel?.center
            case .changed:
                var panTranslation: CGPoint? = (recognizer as? UIPanGestureRecognizer)?.translation(in: self)
                self.textLabel?.center = CGPoint(x: CGFloat(self.referenceCenter.x + panTranslation?.x), y: CGFloat(self.referenceCenter.y + panTranslation?.y))
            case .ended:
                self.referenceCenter = self.textLabel?.center
            default:
                break
        }

    }
    /**
     *  Tells the JotTextView to handle a pinch or rotate gesture.
     *
     *  @param recognizer The pinch or rotation gesture recognizer to handle.
     *
     *  @note This method is triggered by the JotDrawController's
     *  internal pinch and rotation gesture recognizers.
     */

    func handlePinchOrRotateGesture(_ recognizer: UIGestureRecognizer) {
        switch recognizer.state {
            case .began:
                if (recognizer is UIRotationGestureRecognizer) {
                    self.currentRotateTransform = self.referenceRotateTransform
                    self.activeRotationRecognizer = (recognizer as? UIRotationGestureRecognizer)
                }
                else {
                    self.activePinchRecognizer = (recognizer as? UIPinchGestureRecognizer)
                }
            case .changed:
                var currentTransform: CGAffineTransform = self.referenceRotateTransform
                if (recognizer is UIRotationGestureRecognizer) {
                    self.currentRotateTransform = self.self.apply(recognizer, to: self.referenceRotateTransform)
                }
                currentTransform = self.self.apply(self.activePinchRecognizer, to: currentTransform)
                currentTransform = self.self.apply(self.activeRotationRecognizer, to: currentTransform)
                self.textLabel?.transform = currentTransform
            case .ended:
                if (recognizer is UIRotationGestureRecognizer) {
                    self.referenceRotateTransform = self.self.apply(recognizer, to: self.referenceRotateTransform)
                    self.currentRotateTransform = self.referenceRotateTransform
                    self.activeRotationRecognizer = nil
                }
                else if (recognizer is UIPinchGestureRecognizer) {
                    self.scale() *= (recognizer as? UIPinchGestureRecognizer)?.scale
                    self.activePinchRecognizer = nil
                }
            default:
                break
        }

    }


    convenience override init() {
        if (super.init()) {
            self.backgroundColor = UIColor.clear
            self.initialTextInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
            self.fontSize = 60.0
            self.scale = 1.0
            self.font = UIFont.systemFont(ofSize: CGFloat(self.fontSize))
            self.textAlignment = .center
            self.textColor = UIColor.white
            self.textString = ""
            self.textLabel = UILabel()
            if self.isFitOriginalFontSizeToViewWidth {
                self.textLabel?.numberOfLines = 0
            }
            self.textLabel?.font = self.font
            self.textLabel?.textColor = self.textColor
            self.textLabel?.textAlignment = self.textAlignment
            self.textLabel?.center = CGPoint(x: CGFloat(UIScreen.main.bounds.midX), y: CGFloat(UIScreen.main.bounds.midY))
            self.referenceCenter = CGPoint.zero
            self.sizeLabel()
            self.addSubview(self.textLabel)
            self.referenceRotateTransform = CGAffineTransform.identity
            self.currentRotateTransform = CGAffineTransform.identity
            self.userInteractionEnabled = false
        }
    }
// MARK: - Layout Subviews

    override func layoutSubviews() {
        super.layoutSubviews()
        if self.referenceCenter.equalTo(CGPoint.zero) {
            self.textLabel?.center = CGPoint(x: CGFloat(self.bounds.midX), y: CGFloat(self.bounds.midY))
        }
    }
// MARK: - Undo
// MARK: - Properties

    override func setScale(_ scale: CGFloat) {
        if scale != scale {
            self.scale = scale
            self.textLabel?.transform = CGAffineTransform.identity
            var labelCenter: CGPoint? = self.textLabel?.center
            var scaledLabelFrame = CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(labelFrame.width * scale * 1.05), height: CGFloat(labelFrame.height * scale * 1.05))
            var currentFontSize: CGFloat = self.fontSize * scale
            self.textLabel?.font = self.font.withSize(currentFontSize)
            self.textLabel?.frame = scaledLabelFrame
            self.textLabel?.center = labelCenter
            self.textLabel?.transform = self.currentRotateTransform
        }
    }

    func setLabelFrame(_ labelFrame: CGRect) {
        if !labelFrame.equalTo(labelFrame) {
            self.labelFrame = labelFrame
            var labelCenter: CGPoint? = self.textLabel?.center
            var scaledLabelFrame = CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(labelFrame.width * scale * 1.05), height: CGFloat(labelFrame.height * scale * 1.05))
            var labelTransform: CGAffineTransform? = self.textLabel?.transform
            self.textLabel?.transform = CGAffineTransform.identity
            self.textLabel?.frame = scaledLabelFrame
            self.textLabel?.transform = labelTransform
            self.textLabel?.center = labelCenter
        }
    }
// MARK: - Format Text Label

    func adjustLabelFont() {
        var currentFontSize: CGFloat = fontSize * scale
        var center: CGPoint? = self.textLabel?.center
        self.textLabel?.font = font.withSize(currentFontSize)
        self.sizeLabel()
        self.textLabel?.center = center
    }

    func sizeLabel() {
        var temporarySizingLabel = UILabel()
        temporarySizingLabel.text = textString
        temporarySizingLabel.font = font.withSize(fontSize)
        temporarySizingLabel.textAlignment = textAlignment
        var insetViewRect: CGRect
        if isFitOriginalFontSizeToViewWidth {
            temporarySizingLabel.numberOfLines = 0
            insetViewRect = self.bounds.insetBy(dx: CGFloat(initialTextInsets.left + initialTextInsets.right), dy: CGFloat(initialTextInsets.top + initialTextInsets.bottom))
        }
        else {
            temporarySizingLabel.numberOfLines = 1
            insetViewRect = CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(CGFLOAT_MAX), height: CGFloat(CGFLOAT_MAX))
        }
        var originalSize: CGSize = temporarySizingLabel.sizeThatFits(insetViewRect.size)
        temporarySizingLabel.frame = CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(originalSize.width * 1.05), height: CGFloat(originalSize.height * 1.05))
        temporarySizingLabel.center = self.textLabel?.center
        self.labelFrame = temporarySizingLabel.frame
    }
// MARK: - Gestures

    class func apply(_ recognizer: UIGestureRecognizer, to transform: CGAffineTransform) -> CGAffineTransform {
        if !recognizer || !(recognizer is UIRotationGestureRecognizer) || (recognizer is UIPinchGestureRecognizer) {
            return transform
        }
        if (recognizer is UIRotationGestureRecognizer) {
            return transform.rotated(by: (recognizer as? UIRotationGestureRecognizer)?.rotation)!
        }
        var scale: CGFloat? = (recognizer as? UIPinchGestureRecognizer)?.scale
        return transform.scaledBy(x: scale, y: scale)
    }
// MARK: - Image Rendering

    func drawTextImage(with size: CGSize, backgroundImage: UIImage) -> UIImage {
        var scale: CGFloat = size.width / self.bounds.width
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, scale)
        backgroundImage.draw(in: CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(self.bounds.width), height: CGFloat(self.bounds.height)))
        self.layer.render(in: UIGraphicsGetCurrentContext())
        var drawnImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return UIImage(cgImage: drawnImage?.cgImage, scale: 1.0, orientation: drawnImage?.imageOrientation)!
    }

    var textLabel: UILabel!
    var textEditingContainer: UIView!
    var textEditingView: UITextView!
    var referenceRotateTransform = CGAffineTransform()
    var currentRotateTransform = CGAffineTransform()
    var referenceCenter = CGPoint.zero
    var activePinchRecognizer: UIPinchGestureRecognizer!
    var activeRotationRecognizer: UIRotationGestureRecognizer!
    var scale: CGFloat {
        get {
            // TODO: add getter implementation
        }
        set(scale) {
            if scale != scale {
                self.scale = scale
                self.textLabel?.transform = CGAffineTransform.identity
                var labelCenter: CGPoint? = self.textLabel?.center
                var scaledLabelFrame = CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(labelFrame.width * scale * 1.05), height: CGFloat(labelFrame.height * scale * 1.05))
                var currentFontSize: CGFloat = self.fontSize * scale
                self.textLabel?.font = self.font.withSize(currentFontSize)
                self.textLabel?.frame = scaledLabelFrame
                self.textLabel?.center = labelCenter
                self.textLabel?.transform = self.currentRotateTransform
            }
        }
    }
    var labelFrame: CGRect {
        get {
            // TODO: add getter implementation
        }
        set(labelFrame) {
            if !labelFrame.equalTo(labelFrame) {
                self.labelFrame = labelFrame
                var labelCenter: CGPoint? = self.textLabel?.center
                var scaledLabelFrame = CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(labelFrame.width * scale * 1.05), height: CGFloat(labelFrame.height * scale * 1.05))
                var labelTransform: CGAffineTransform? = self.textLabel?.transform
                self.textLabel?.transform = CGAffineTransform.identity
                self.textLabel?.frame = scaledLabelFrame
                self.textLabel?.transform = labelTransform
                self.textLabel?.center = labelCenter
            }
        }
    }
}
//
//  JotTextView.m
//  jot
//
//  Created by Laura Skelton on 4/30/15.
//
//