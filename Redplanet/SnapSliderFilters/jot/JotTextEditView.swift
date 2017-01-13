//  Converted with Swiftify v1.0.6221 - https://objectivec2swift.com/
//
//  JotTextEditView.h
//  jot
//
//  Created by Laura Skelton on 4/30/15.
//
//
import UIKit
import Foundation

/**
 *  Private class to handle text editing. Change the properties
 *  in a JotViewController instance to configure this private class.
 */
class JotTextEditView: UIView, UITextViewDelegate {
    /**
     *  The delegate of the JotTextEditView, which receives an update
     *  when the JotTextEditView is finished editing text, with the
     *  revised textString.
     */
    weak var delegate: JotTextEditViewDelegate?
    /**
     *  Whether or not the JotTextEditView is actively in edit mode.
     *  This property controls whether or not the keyboard is displayed
     *  and the JotTextEditView is visible.
     *
     *  @note Set the JotViewController state to JotViewStateEditingText
     *  to turn on editing mode in JotTextEditView.
     */
    var isEditing: Bool = false
    /**
     *  The text string the JotTextEditView is currently displaying.
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
                self.textView.text = textString
                self.textView.setContentOffset(CGPoint.zero, animated: false)
            }
        }
    }
    /**
     *  The color of the text displayed in the JotTextEditView.
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
                self.textView.textColor = textColor
            }
        }
    }
    /**
     *  The font of the text displayed in the JotTextEditView.
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
                self.textView.font = font.withSize(CGFloat(fontSize))
            }
        }
    }
    /**
     *  The font size of the text displayed in the JotTextEditView.
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
                self.textView.font = font.withSize(fontSize)
            }
        }
    }
    /**
     *  The alignment of the text displayed in the JotTextEditView.
     *
     *  @note Set textAlignment in JotViewController to control this property.
     */
    var textAlignment: NSTextAlignment {
        get {
            // TODO: add getter implementation
        }
        set(textAlignment) {
            if textAlignment != textAlignment {
                self.textAlignment = textAlignment
                self.textView.textAlignment = textAlignment
            }
        }
    }
    /**
     *  The view insets of the text displayed in the JotTextEditView. By default,
     *  the text that extends beyond the insets of the text input view will fade out
     *  with a gradient to the edges of the JotTextEditView. If clipBoundsToEditingInsets
     *  is true, then the text will be clipped at the inset instead of fading out.
     *
     *  @note Set textEditingInsets in JotViewController to control this property.
     */
    var textEditingInsets: UIEdgeInsets {
        get {
            // TODO: add getter implementation
        }
        set(textEditingInsets) {
            if !UIEdgeInsetsEqualToEdgeInsets(textEditingInsets, textEditingInsets) {
                self.textEditingInsets = textEditingInsets
                self.textView.mas_updateConstraints({(_ make: MASConstraintMaker) -> Void in
                    make.edges.equalTo(self.textContainer).insets(textEditingInsets)
                })
                self.textView.layoutIfNeeded()
                self.textView.setContentOffset(CGPoint.zero, animated: false)
            }
        }
    }
    /**
     *  By default, clipBoundsToEditingInsets is false, and the text that extends 
     *  beyond the insets of the text input view will fade out with a gradient 
     *  to the edges of the JotTextEditView. If clipBoundsToEditingInsets is true, 
     *  then the text will be clipped at the inset instead of fading out.
     *
     *  @note Set clipBoundsToEditingInsets in JotViewController to control this property.
     */
    var isClipBoundsToEditingInsets: Bool {
        get {
            // TODO: add getter implementation
        }
        set(clipBoundsToEditingInsets) {
            if isClipBoundsToEditingInsets != isClipBoundsToEditingInsets {
                self.isClipBoundsToEditingInsets = isClipBoundsToEditingInsets
                self.textView.clipsToBounds = isClipBoundsToEditingInsets
                self.setupGradientMask()
            }
        }
    }


    convenience override init() {
        if (super.init()) {
            self.backgroundColor = UIColor.clear
            self.font = UIFont.systemFont(ofSize: CGFloat(40.0))
            self.fontSize = 40.0
            self.textEditingInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
            self.textContainer = UIView()
            self.textContainer.layer.masksToBounds = true
            self.addSubview(self.textContainer)
            self.textContainer.mas_makeConstraints({(_ make: MASConstraintMaker) -> Void in
                make.top.and.left.and.right.equalTo(self)
                make.bottom.equalTo(self).offset(0.0)
            })
            self.textView = UITextView()
            self.textView.backgroundColor = UIColor.clear
            self.textView.text = self.textString
            self.textView.keyboardType = .default
            self.textView.returnKeyType = UIReturnKeyDone
            self.textView.clipsToBounds = false
            self.textView.delegate = self
            self.textContainer.addSubview(self.textView)
            self.textView.mas_makeConstraints({(_ make: MASConstraintMaker) -> Void in
                make.edges.equalTo(self.textContainer).insets(textEditingInsets)
            })
            self.textContainer.isHidden = true
            self.userInteractionEnabled = false
            NotificationCenter.default.addObserver(forName: UIKeyboardWillChangeFrameNotification, object: nil, queue: nil, usingBlock: {(_ note: Notification) -> Void in
                self.textContainer.layer.removeAllAnimations()
                var keyboardRectEnd: CGRect? = note.userInfo?[UIKeyboardFrameEndUserInfoKey]?.cgRect()
                var duration: TimeInterval = CFloat(note.userInfo?[UIKeyboardAnimationDurationUserInfoKey])
                self.textContainer.mas_updateConstraints({(_ make: MASConstraintMaker) -> Void in
                    make.bottom.equalTo(self).offset(-keyboardRectEnd.height)
                })
                UIView.animate(withDuration: duration, delay: 0.0, options: .beginFromCurrentState, animations: {() -> Void in
                    self.textContainer.layoutIfNeeded()
                }, completion: { _ in })
            })
        }
    }

    deinit {
        self.textView.delegate = nil
        NotificationCenter.default.removeObserver(self)
    }
// MARK: - Properties

    func setIsEditing(_ isEditing: Bool) {
        if isEditing != isEditing {
            self.isEditing = isEditing
            self.textContainer.isHidden = !isEditing
            self.userInteractionEnabled = isEditing
            if isEditing {
                self.backgroundColor = UIColor(white: CGFloat(0.0), alpha: CGFloat(0.5))
                self.textView.becomeFirstResponder()
            }
            else {
                self.backgroundColor = UIColor.clear
                self.textString = self.textView.text
                self.textView.resignFirstResponder()
                if self.delegate.responds(to: #selector(self.jotTextEditViewFinishedEditingWithNewTextString)) {
                    self.delegate.jotTextEditViewFinishedEditing(withNewTextString: textString)
                }
            }
        }
    }
// MARK: - Gradient Mask

    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupGradientMask()
    }

    func setupGradientMask() {
        if !self.isClipBoundsToEditingInsets {
            self.textContainer.layer.mask = self.gradientMask()
            var percentTopOffset: CGFloat = self.textEditingInsets.top / self.textContainer.bounds.height
            var percentBottomOffset: CGFloat = self.textEditingInsets.bottom / self.textContainer.bounds.height
            self.gradientMask().locations = [(0.0 * percentTopOffset), (0.8 * percentTopOffset), (0.9 * percentTopOffset), (1.0 * percentTopOffset), (1.0 - (1.0 * percentBottomOffset)), (1.0 - (0.9 * percentBottomOffset)), (1.0 - (0.8 * percentBottomOffset)), (1.0 - (0.0 * percentBottomOffset))]
            self.gradientMask().frame = CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(self.textContainer.bounds.width), height: CGFloat(self.textContainer.bounds.height))
        }
        else {
            self.textContainer.layer.mask = nil
        }
    }

    func gradientMask() -> CAGradientLayer {
        if !gradientMask {
            self.gradientMask = CAGradientLayer()
            self.gradientMask.colors = [(UIColor(white: CGFloat(1.0), alpha: CGFloat(0.0)).cgColor as? Any), (UIColor(white: CGFloat(1.0), alpha: CGFloat(0.4)).cgColor as? Any), (UIColor(white: CGFloat(1.0), alpha: CGFloat(0.7)).cgColor as? Any), (UIColor(white: CGFloat(1.0), alpha: CGFloat(1.0)).cgColor as? Any), (UIColor(white: CGFloat(1.0), alpha: CGFloat(1.0)).cgColor as? Any), (UIColor(white: CGFloat(1.0), alpha: CGFloat(0.7)).cgColor as? Any), (UIColor(white: CGFloat(1.0), alpha: CGFloat(0.4)).cgColor as? Any), (UIColor(white: CGFloat(1.0), alpha: CGFloat(0.0)).cgColor as? Any)]
        }
        return gradientMask
    }
// MARK: - Text Editing

    func textView(_ textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            self.isEditing = false
            return false
        }
        if textView.text.characters.count + (text.characters.count - range.length) > 70 {
            return false
        }
        if (text as NSString).rangeOfCharacter(CharacterSet.newlines).location != NSNotFound {
            return false
        }
        return true
    }

    var textView: UITextView!
    var textContainer: UIView!
    var gradientMask: CAGradientLayer! {
        if gradientMask == nil {
                self.gradientMask = CAGradientLayer()
                self.gradientMask.colors = [(UIColor(white: CGFloat(1.0), alpha: CGFloat(0.0)).cgColor as? Any), (UIColor(white: CGFloat(1.0), alpha: CGFloat(0.4)).cgColor as? Any), (UIColor(white: CGFloat(1.0), alpha: CGFloat(0.7)).cgColor as? Any), (UIColor(white: CGFloat(1.0), alpha: CGFloat(1.0)).cgColor as? Any), (UIColor(white: CGFloat(1.0), alpha: CGFloat(1.0)).cgColor as? Any), (UIColor(white: CGFloat(1.0), alpha: CGFloat(0.7)).cgColor as? Any), (UIColor(white: CGFloat(1.0), alpha: CGFloat(0.4)).cgColor as? Any), (UIColor(white: CGFloat(1.0), alpha: CGFloat(0.0)).cgColor as? Any)]
            }
            return gradientMask
    }
    var topGradient: CAGradientLayer!
    var bottomGradient: CAGradientLayer!
}
protocol JotTextEditViewDelegate: NSObjectProtocol {
    /**
     *  Called whenever the JotTextEditView ends text editing (keyboard entry) mode.
     *
     *  @param textString    The new text string after editing
     */
    func jotTextEditViewFinishedEditing(withNewTextString textString: String)
}
//
//  JotTextEditView.m
//  jot
//
//  Created by Laura Skelton on 4/30/15.
//
//
import Masonry