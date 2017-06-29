//
//  RPCaptionView.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/17/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//
import UIKit
import Foundation

class RPCaptionView: UIView {
    
    struct ViewState {
        var transform = CGAffineTransform.identity
        var center = CGPoint.zero
    }
    
    open var textViewContainer = UIView()
    open var textView = RPTextView()
    
    fileprivate var pinchGesture: UIPinchGestureRecognizer!
    fileprivate var panGesture: UIPanGestureRecognizer!
    fileprivate var rotateGesture: UIRotationGestureRecognizer!
    fileprivate var tapGesture: UITapGestureRecognizer!
    
    fileprivate private(set) var viewState: ViewState?
    fileprivate var lastState: ViewState?
    
    var defaultSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
    
    var defaultCenter: CGPoint {
        return CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
    }
    
    var defaultTransform: CGAffineTransform {
        return CGAffineTransform.init(scaleX: 0.5, y: 0.5)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configurate()
    }
    
    override var isFirstResponder: Bool {
        return textView.isFirstResponder
    }
    
    override func becomeFirstResponder() -> Bool {
        self.superview?.bringSubview(toFront: self)
        return textView.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }
    
    func configurate() {
        clipsToBounds = false
        backgroundColor = UIColor.clear
        
        textViewContainer.frame.size = defaultSize
        textViewContainer.clipsToBounds = false
        textViewContainer.backgroundColor = UIColor.clear
        addSubview(textViewContainer)
        
        textView.frame = textViewContainer.bounds
        textViewContainer.addSubview(textView)
        textView.configurate()
        textView.delegate = self
        
        // PINCH
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:)))
        pinchGesture.delegate = self
        self.textViewContainer.addGestureRecognizer(pinchGesture)
        
        // ROTATE
        rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateAction(_:)))
        rotateGesture.delegate = self
        self.textViewContainer.addGestureRecognizer(rotateGesture)
        
        // PAN
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        panGesture.delegate = self
        self.textViewContainer.addGestureRecognizer(panGesture)
        
        // TAP
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        tapGesture.delegate = self
        self.textViewContainer.addGestureRecognizer(tapGesture)
        
        viewState = getInitState()
        updateState(viewState)
    }
    
    fileprivate func getInitState() -> ViewState {
        var viewState = ViewState()
        viewState.center = defaultCenter
        viewState.transform = defaultTransform
        return viewState
    }
    
    fileprivate func updateState(_ viewState: ViewState?) {
        guard let viewState = viewState else { return }
        self.viewState = viewState
        textViewContainer.center = viewState.center
        textViewContainer.transform = viewState.transform

//        self.center = viewState.center
//        self.transform = viewState.transform
//        self.frame = self.textViewContainer.frame
//        self.clipsToBounds = true
//        print(self.frame)
    }
}

// MARK: - UIGestureRecognizer Delegate
extension RPCaptionView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Gesture Handlers
extension RPCaptionView {
    
    func tapAction(_ gesture: UITapGestureRecognizer) {
        textView.becomeFirstResponder()
    }
    
    func panAction(_ gesture: UIPanGestureRecognizer) {
        textView.resignFirstResponder()
        guard var viewState = viewState else { return }
        viewState.center = gesture.location(in: self)
        updateState(viewState)
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    func pinchAction(_ gesture: UIPinchGestureRecognizer) {
        textView.resignFirstResponder()
        guard var viewState = viewState else { return }
        viewState.transform = viewState.transform.scaledBy(x: gesture.scale, y: gesture.scale)
        updateState(viewState)
        gesture.scale = 1
    }
    
    func rotateAction(_ gesture: UIRotationGestureRecognizer) {
        textView.resignFirstResponder()
        guard var viewState = viewState else { return }
        viewState.transform = viewState.transform.rotated(by: gesture.rotation)
        updateState(viewState)
        gesture.rotation = 0
    }
}

// MARK: - UITextView Delegate
extension RPCaptionView: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.bounds.size = textViewContainer.bounds.size
        textView.clipsToBounds = true
        textView.isScrollEnabled = true
        
        lastState = viewState
        self.updateState(self.getInitState())
        UIView.animate(withDuration: 0.3) { [unowned self] in
//            self.updateState(self.getInitState())
            self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height/2)
            self.clipsToBounds = true
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // Bring self to front of keyWindow
        UIApplication.shared.keyWindow?.bringSubview(toFront: self)
        
        let contentSize = textView.contentSize
        textView.clipsToBounds = false
        textView.isScrollEnabled = false
        textView.bounds.size = contentSize

        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.updateState(self.lastState)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            _ = self.resignFirstResponder()
        }
        
        // Limit text to 500 characters
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.characters.count
        return numberOfChars < 500
    }
}
