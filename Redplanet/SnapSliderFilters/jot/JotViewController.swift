//  Converted with Swiftify v1.0.6221 - https://objectivec2swift.com/
//
//  JotViewController.h
//  jot
//
//  Created by Laura Skelton on 4/30/15.
//
//
import UIKit
import Foundation
/**
 *  The possible states of the JotViewController
 */
enum JotViewState : Int {
    /**
         *  The default state, which does not allow
         *  any touch interactions.
         */
    case default
    /**
         *  The drawing state, where drawing with touch
         *  gestures will create colored lines in the view.
         */
    case drawing
    /**
         *  The text state, where pinch, pan, and rotate
         *  gestures will manipulate the displayed text, and
         *  a tap gesture will switch to text editing mode.
         */
    case text
    /**
         *  The text editing state, where the contents of
         *  the text string can be edited with the keyboard.
         */
    case editingText
}

import UIKit
/**
 *  Public class for you to use to create a jot view! Import <jot.h>
 *  into your view controller, then create an instance of JotViewController
 *  and add it as a child of your view controller. Set the state of the
 *  JotViewController to switch between manipulating text and drawing.
 *
 *  @note You will be able to see your view controller's view through
 *  the jot view, so you can display the jot view above either a colored
 *  background for a sketchpad/whiteboard-like interface, or above a photo
 *  for a photo annotation interface.
 */
class JotViewController: UIViewController, UIGestureRecognizerDelegate, JotTextEditViewDelegate, JotDrawingContainerDelegate {
    /**
     *  The delegate of the JotViewController instance.
     */
    weak var delegate: JotViewControllerDelegate?
    /**
     *  The state of the JotViewController. Change the state between JotViewStateDrawing
     *  and JotViewStateText in response to your own editing controls to toggle between
     *  the different modes. Tapping while in JotViewStateText will automatically switch
     *  to JotViewStateEditingText, and tapping the keyboard's Done button will automatically
     *  switch back to JotViewStateText.
     *
     *  @note The JotViewController's delegate will get updates when it enters and exits
     *  text editing mode, in case you need to update your interface to reflect this.
     */
    var state: JotViewState {
        get {
            // TODO: add getter implementation
        }
        set(state) {
            if state != state {
                self.state = state
                self.textView.isHidden = self.textEditView.isEditing = (state == .editingText)
                if state == .editingText && self.delegate.responds(to: Selector("jotViewController:isEditingText:")) {
                    self.delegate.jotViewController(self, isEditingText: true)
                }
                self.drawingContainer.isMultipleTouchEnabled = self.tapRecognizer.isEnabled = self.panRecognizer.isEnabled = self.pinchRecognizer.isEnabled = self.rotationRecognizer.isEnabled = (state == .text)
            }
        }
    }
    /**
     *  The font of the text displayed in the JotTextView and JotTextEditView.
     *
     *  @note To change the default size of the font, you must also set the
     *  fontSize property to the desired font size.
     */
    var font: UIFont! {
        get {
            // TODO: add getter implementation
        }
        set(font) {
            if font != font {
                self.font = font
                self.textView.font = self.textEditView.font = font
            }
        }
    }
    /**
     *  The initial font size of the text displayed in the JotTextView before pinch zooming,
     *  and the fixed font size of the JotTextEditView.
     *
     *  @note This property overrides the size of the font property.
     */
    var fontSize: CGFloat {
        get {
            // TODO: add getter implementation
        }
        set(fontSize) {
            if fontSize != fontSize {
                self.fontSize = fontSize
                self.textView.fontSize = self.textEditView.fontSize = fontSize
            }
        }
    }
    /**
     *  The color of the text displayed in the JotTextView and the JotTextEditView.
     */
    var textColor: UIColor! {
        get {
            // TODO: add getter implementation
        }
        set(textColor) {
            if textColor != textColor {
                self.textColor = textColor
                self.textView.textColor = self.textEditView.textColor = textColor
            }
        }
    }
    /**
     *  The text string the JotTextView and JotTextEditView are displaying.
     */
    var textString: String {
        get {
            // TODO: add getter implementation
        }
        set(textString) {
            if !(textString == textString) {
                self.textString = textString
                if !(self.textView.textString == textString) {
                    self.textView.textString = textString
                }
                if !(self.textEditView.textString == textString) {
                    self.textEditView.textString = textString
                }
            }
        }
    }
    /**
     *  The alignment of the text displayed in the JotTextView, which only
     *  applies if fitOriginalFontSizeToViewWidth is true, and the alignment of the
     *  text displayed in the JotTextEditView regardless of other settings.
     */
    var textAlignment: NSTextAlignment {
        get {
            // TODO: add getter implementation
        }
        set(textAlignment) {
            if textAlignment != textAlignment {
                self.textAlignment = textAlignment
                self.textView.textAlignment = self.textEditView.textAlignment = textAlignment
            }
        }
    }
    /**
     *  Sets the stroke color for drawing. Each drawing path can have its own stroke color.
     */
    var drawingColor: UIColor! {
        get {
            // TODO: add getter implementation
        }
        set(drawingColor) {
            if drawingColor != drawingColor {
                self.drawingColor = drawingColor
                self.drawView.strokeColor = drawingColor
            }
        }
    }
    /**
     *  Sets the stroke width for drawing if constantStrokeWidth is true, or sets
     *  the base strokeWidth for variable drawing paths constantStrokeWidth is false.
     */
    var drawingStrokeWidth: CGFloat {
        get {
            // TODO: add getter implementation
        }
        set(drawingStrokeWidth) {
            if drawingStrokeWidth != drawingStrokeWidth {
                self.drawingStrokeWidth = drawingStrokeWidth
                self.drawView.strokeWidth = drawingStrokeWidth
            }
        }
    }
    /**
     *  Set to YES if you want the stroke width for drawing to be constant,
     *  NO if the stroke width should vary depending on drawing speed.
     */
    var isDrawingConstantStrokeWidth: Bool {
        get {
            // TODO: add getter implementation
        }
        set(drawingConstantStrokeWidth) {
            if isDrawingConstantStrokeWidth != isDrawingConstantStrokeWidth {
                self.isDrawingConstantStrokeWidth = isDrawingConstantStrokeWidth
                self.drawView.isConstantStrokeWidth = isDrawingConstantStrokeWidth
            }
        }
    }
    /**
     *  The view insets of the text displayed in the JotTextEditView. By default,
     *  the text that extends beyond the insets of the text input view will fade out
     *  with a gradient to the edges of the JotTextEditView. If clipBoundsToEditingInsets
     *  is true, then the text will be clipped at the inset instead of fading out.
     */
    var textEditingInsets: UIEdgeInsets {
        get {
            // TODO: add getter implementation
        }
        set(textEditingInsets) {
            if !UIEdgeInsetsEqualToEdgeInsets(textEditingInsets, textEditingInsets) {
                self.textEditingInsets = textEditingInsets
                self.textEditView.textEditingInsets = textEditingInsets
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
     *  @note This will be ignored if fitOriginalFontSizeToViewWidth is false.
     */
    var initialTextInsets: UIEdgeInsets {
        get {
            // TODO: add getter implementation
        }
        set(initialTextInsets) {
            if !UIEdgeInsetsEqualToEdgeInsets(initialTextInsets, initialTextInsets) {
                self.initialTextInsets = initialTextInsets
                self.textView.initialTextInsets = initialTextInsets
            }
        }
    }
    /**
     *  If fitOriginalFontSizeToViewWidth is true, then the text will wrap to fit within the width
     *  of the JotTextView, with the given initialTextInsets, if any. The layout will reflect
     *  the textAlignment property as well as the initialTextInsets property. If this is false,
     *  then the text will be displayed as a single line, and will ignore any initialTextInsets and
     *  textAlignment settings
     */
    var isFitOriginalFontSizeToViewWidth: Bool {
        get {
            // TODO: add getter implementation
        }
        set(fitOriginalFontSizeToViewWidth) {
            if isFitOriginalFontSizeToViewWidth != isFitOriginalFontSizeToViewWidth {
                self.isFitOriginalFontSizeToViewWidth = isFitOriginalFontSizeToViewWidth
                self.textView.isFitOriginalFontSizeToViewWidth = isFitOriginalFontSizeToViewWidth
                if isFitOriginalFontSizeToViewWidth {
                    self.textEditView.textAlignment = self.textAlignment
                }
                else {
                    self.textEditView.textAlignment = .left
                }
            }
        }
    }
    /**
     *  By default, clipBoundsToEditingInsets is false, and the text that extends
     *  beyond the insets of the text input view in the JotTextEditView will fade out with
     *  a gradient to the edges of the JotTextEditView. If clipBoundsToEditingInsets is true,
     *  then the text will be clipped at the inset instead of fading out in the JotTextEditView.
     */
    var isClipBoundsToEditingInsets: Bool {
        get {
            // TODO: add getter implementation
        }
        set(clipBoundsToEditingInsets) {
            if isClipBoundsToEditingInsets != isClipBoundsToEditingInsets {
                self.isClipBoundsToEditingInsets = isClipBoundsToEditingInsets
                self.textEditView.isClipBoundsToEditingInsets = isClipBoundsToEditingInsets
            }
        }
    }
    private(set) var drawingContainer: JotDrawingContainer!
    /**
     *  Clears all paths from the drawing in and sets the text to an empty string, giving a blank slate.
     */

    func clearAll() {
        self.clearDrawing()
        self.clearText()
    }
    /**
     *  Clears only the drawing, leaving the text alone.
     */

    func clearDrawing() {
        self.drawView.clearDrawing()
    }
    /**
     *  Clears only the text, leaving the drawing alone.
     */

    func clearText() {
        self.textString = ""
        self.textView.clearText()
    }
    /**
     *  Overlays the drawing and text on the given background image at the full
     *  resolution of the image.
     *
     *  @param image The background image to draw on top of.
     *
     *  @return An image of the rendered drawing and text on the background image.
     */

    func draw(on image: UIImage) -> UIImage {
        var drawImage: UIImage? = self.drawView.draw(on: image)
        return self.textView.drawText(on: drawImage)
    }
    /**
     *  Renders the drawing and text at the view's size with a transparent background.
     *
     *  @return An image of the rendered drawing and text.
     */

    func renderImage() -> UIImage {
        return self.renderImage(withScale: 1.0)
    }
    /**
     *  Renders the drawing and text at the view's size with a colored background.
     *
     *  @return An image of the rendered drawing and text on a colored background.
     */

    func renderImage(on color: UIColor) -> UIImage {
        return self.renderImage(withScale: 1.0, on: color)
    }
    /**
     *  Renders the drawing and text at the view's size multiplied by the given scale
     *  with a transparent background.
     *
     *  @return An image of the rendered drawing and text.
     */

    func renderImage(withScale scale: CGFloat) -> UIImage {
        return self.renderImage(with: CGSize(width: CGFloat(self.drawingContainer.frame.width * scale), height: CGFloat(self.drawingContainer.frame.height * scale)))
    }
    /**
     *  Renders the drawing and text at the view's size multiplied by the given scale
     *  with a colored background.
     *
     *  @return An image of the rendered drawing and text on a colored background.
     */

    func renderImage(withScale scale: CGFloat, on color: UIColor) -> UIImage {
        return self.renderImage(with: CGSize(width: CGFloat(self.drawingContainer.frame.width * scale), height: CGFloat(self.drawingContainer.frame.height * scale)), on: color)
    }


    convenience override init() {
        if (super.init()) {
            self.drawView = JotDrawView()
            self.textEditView = JotTextEditView()
            self.textEditView.delegate = self
            self.textView = JotTextView()
            self.drawingContainer = JotDrawingContainer()
            self.drawingContainer.delegate = self
            self.font = self.textView.font
            self.textEditView.font = self.font
            self.fontSize = self.textView.fontSize
            self.textEditView.fontSize = self.fontSize
            self.textAlignment = self.textView.textAlignment
            self.textEditView.textAlignment = .left
            self.textColor = self.textView.textColor
            self.textEditView.textColor = self.textColor
            self.textString = ""
            self.drawingColor = self.drawView.strokeColor
            self.drawingStrokeWidth = self.drawView.strokeWidth
            self.textEditingInsets = self.textEditView.textEditingInsets
            self.initialTextInsets = self.textView.initialTextInsets
            self.state = .default
            self.pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchOrRotateGesture))
            self.pinchRecognizer.delegate = self
            self.rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(self.handlePinchOrRotateGesture))
            self.rotationRecognizer.delegate = self
            self.panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture))
            self.panRecognizer.delegate = self
            self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture))
            self.tapRecognizer.delegate = self
        }
    }

    deinit {
        self.textEditView.delegate = nil
        self.drawingContainer.delegate = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        self.drawingContainer.clipsToBounds = true
        self.view.addSubview(self.drawingContainer)
        self.drawingContainer.mas_makeConstraints({(_ make: MASConstraintMaker) -> Void in
            make.edges.equalTo(self.view)
        })
        self.drawingContainer.addSubview(self.drawView)
        self.drawView.mas_makeConstraints({(_ make: MASConstraintMaker) -> Void in
            make.edges.equalTo(self.drawingContainer)
        })
        self.drawingContainer.addSubview(self.textView)
        self.textView.mas_makeConstraints({(_ make: MASConstraintMaker) -> Void in
            make.edges.equalTo(self.drawingContainer)
        })
        self.view.addSubview(self.textEditView)
        self.textEditView.mas_makeConstraints({(_ make: MASConstraintMaker) -> Void in
            make.edges.equalTo(self.view)
        })
        self.drawingContainer.addGestureRecognizer(self.tapRecognizer)
        self.drawingContainer.addGestureRecognizer(self.panRecognizer)
        self.drawingContainer.addGestureRecognizer(self.rotationRecognizer)
        self.drawingContainer.addGestureRecognizer(self.pinchRecognizer)
    }
// MARK: - Properties
// MARK: - Undo
// MARK: - Output UIImage

    func renderImage(with size: CGSize) -> UIImage {
        var renderDrawingImage: UIImage? = self.drawView.renderDrawing(with: size)
        return self.textView.drawText(on: renderDrawingImage)
    }

    func renderImage(with size: CGSize, on color: UIColor) -> UIImage {
        var colorImage = UIImage.jotImage(with: color, size: size)
        var renderDrawingImage: UIImage? = self.drawView.draw(on: colorImage)
        return self.textView.drawText(on: renderDrawingImage)
    }
// MARK: - Gestures

    func handleTapGesture(_ recognizer: UIGestureRecognizer) {
        if !(self.state == .editingText) {
            self.state = .editingText
        }
    }

    func handlePanGesture(_ recognizer: UIGestureRecognizer) {
        self.textView.handlePanGesture(recognizer)
    }

    func handlePinchOrRotateGesture(_ recognizer: UIGestureRecognizer) {
        self.textView.handlePinchOrRotateGesture(recognizer)
    }
// MARK: - JotDrawingContainer Delegate

    func jotDrawingContainerTouchBegan(at touchPoint: CGPoint) {
        if self.state == .drawing {
            self.drawView.drawTouchBegan(at: touchPoint)
        }
    }

    func jotDrawingContainerTouchMoved(to touchPoint: CGPoint) {
        if self.state == .drawing {
            self.drawView.drawTouchMoved(to: touchPoint)
        }
    }

    func jotDrawingContainerTouchEnded() {
        if self.state == .drawing {
            self.drawView.drawTouchEnded()
        }
    }
// MARK: - UIGestureRecognizer Delegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer is UITapGestureRecognizer) {
            return true
        }
        return false
    }
// MARK: - JotTextEditView Delegate

    func jotTextEditViewFinishedEditing(withNewTextString textString: String) {
        if self.state == .editingText {
            self.state = .text
        }
        self.textString = textString
        if self.delegate.responds(to: Selector("jotViewController:isEditingText:")) {
            self.delegate.jotViewController(self, isEditingText: false)
        }
    }

    var tapRecognizer: UITapGestureRecognizer!
    var pinchRecognizer: UIPinchGestureRecognizer!
    var rotationRecognizer: UIRotationGestureRecognizer!
    var panRecognizer: UIPanGestureRecognizer!
    var drawingContainer: JotDrawingContainer!
    var drawView: JotDrawView!
    var textEditView: JotTextEditView!
    var textView: JotTextView!
}
protocol JotViewControllerDelegate: NSObjectProtocol {
    /**
     *  Called whenever the JotViewController begins or ends text editing (keyboard entry) mode.
     *
     *  @param jotViewController The draw text view controller
     *  @param isEditing    YES if entering edit (keyboard text entry) mode, NO if exiting edit mode
     */
    func jotViewController(_ jotViewController: JotViewController, isEditingText isEditing: Bool)
}
//
//  JotViewController.m
//  jot
//
//  Created by Laura Skelton on 4/30/15.
//
//
import Masonry