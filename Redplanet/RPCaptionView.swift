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
    
    // Struct element to determine state of object
    struct ViewState {
        var transform = CGAffineTransform.identity
        var center = CGPoint.zero
    }
    
    // Setup private element, struct
    fileprivate private(set) var viewState: ViewState?
    fileprivate var lastState: ViewState?
    
    // Default Size; CGSize
    var defaultSize: CGSize {
        let width = UIScreen.main.bounds.width
        return CGSize(width: width * 2, height: width * 2)
    }
    
    // Default Center; CGPoint
    var defaultCenter: CGPoint {
        return CGPoint(x: bounds.width / 2, y: bounds.width / 2)
    }
    
    // Default Matrix; (?) CGAffineTransform (?)
    var defaultTransform: CGAffineTransform {
        return CGAffineTransform.init(scaleX: 0.5, y: 0.5)
    }
    
    // MARK: - Class variables
    open var textViewContainer = UIView()
    open var textView = RPTextView()
    
    // MARK: - UIGestureRecognizers
    fileprivate var pinchGesture: UIPinchGestureRecognizer!
    fileprivate var panGesture: UIPanGestureRecognizer!
    fileprivate var rotateGesture: UIRotationGestureRecognizer!
    fileprivate var tapGesture: UITapGestureRecognizer!
    
    // Initialize RPCaptionView
    required public override init(frame: CGRect) {
        super.init(frame: frame)

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
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(sender:)))
        pinchGesture.delegate = self
        self.textViewContainer.addGestureRecognizer(pinchGesture)
        
        // ROTATE
        rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateAction(sender:)))
        rotateGesture.delegate = self
        self.textViewContainer.addGestureRecognizer(rotateGesture)
        
        // PAN
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panAction(sender:)))
        panGesture.delegate = self
        self.textViewContainer.addGestureRecognizer(panGesture)
        
        // TAP
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(sender:)))
        tapGesture.delegate = self
        self.textViewContainer.addGestureRecognizer(tapGesture)
        
        viewState = getInitState()
        updateState(viewState)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    }
    
    fileprivate func updateFrame(_ viewState: ViewState?) {
        guard let viewState = viewState else { return }
        self.viewState = viewState
        self.frame = self.textViewContainer.frame
    }
}

// MARK: - UIGestureRecognizer Delegate
extension RPCaptionView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.view?.isKind(of: UITextView.classForCoder()) == false &&
            otherGestureRecognizer.view?.isKind(of: UITextView.classForCoder()) == false
    }
}

// MARK: - Gesture Handlers
extension RPCaptionView {
    
    func tapAction(sender: UITapGestureRecognizer) {
        textView.becomeFirstResponder()
    }
    
    func panAction(sender: UIPanGestureRecognizer) {
        guard var viewState = viewState else { return }
        textView.resignFirstResponder()
        viewState.center = sender.location(in: self)
        updateState(viewState)
        sender.setTranslation(.zero, in: sender.view)
        
//        if sender.state == .ended {
//            self.updateFrame(viewState)
//        }
    }
    
    func pinchAction(sender: UIPinchGestureRecognizer) {
        guard var viewState = viewState else { return }
        textView.resignFirstResponder()
        viewState.transform = viewState.transform.scaledBy(x: sender.scale, y: sender.scale)
        updateState(viewState)
        sender.scale = 1
        
//        if sender.state == .ended {
//            self.updateFrame(viewState)
//        }
    }
    
    func rotateAction(sender: UIRotationGestureRecognizer) {
        guard var viewState = viewState else { return }
        textView.resignFirstResponder()
        viewState.transform = viewState.transform.rotated(by: sender.rotation)
        updateState(viewState)
        sender.rotation = 0
        
//        if sender.state == .ended {
//            self.updateFrame(viewState)
//        }
    }
}

// MARK: - UITextView Delegate Methods
extension RPCaptionView: UITextViewDelegate {

    override var isFirstResponder: Bool {
        return textView.isFirstResponder
    }
    
    override func becomeFirstResponder() -> Bool {
        self.superview?.bringSubview(toFront: self)
        self.textView.becomeFirstResponder()
        return self.textView.isFirstResponder
    }
    
    override func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.bounds.size = textViewContainer.bounds.size
        textView.clipsToBounds = true
        textView.isScrollEnabled = true
        
        lastState = viewState
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.updateState(self.getInitState())
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let contentSize = textView.contentSize
        textView.clipsToBounds = false
        textView.isScrollEnabled = false
        textView.bounds.size = contentSize
        
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.updateState(self.lastState)
        }

        // Bring self to front of keyWindow
        UIApplication.shared.keyWindow?.bringSubview(toFront: self)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            _ = self.resignFirstResponder()
        }
        
        // Limit text to 180 characters
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.characters.count
        return numberOfChars < 180
    }
}
