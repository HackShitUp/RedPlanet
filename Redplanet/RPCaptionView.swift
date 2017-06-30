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
    
    fileprivate private(set) var viewState: ViewState?
    fileprivate var lastState: ViewState?
    
//    var defaultSize: CGSize {
//        return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/2)
//    }
//    
//    var defaultCenter: CGPoint {
////        return CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
//        return CGPoint(x: bounds.width / 2, y: bounds.width / 2)
//    }
    
    var defaultSize: CGSize {
        let width = UIScreen.main.bounds.width
        return CGSize(width: width * 2, height: width * 2)
    }
    
    var defaultCenter: CGPoint {
        return CGPoint(x: bounds.width / 2, y: bounds.width / 2)
    }
    
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
}

// MARK: - UIGestureRecognizer Delegate
extension RPCaptionView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true
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
//        textView.resignFirstResponder()
//        guard var viewState = viewState else { return }
//        viewState.center = sender.location(in: self)
//        updateState(viewState)
//        sender.setTranslation(.zero, in: sender.view)
        guard var viewState = viewState else { return }
        switch sender.state {
        case .began:
            textView.resignFirstResponder()
        case .changed:
            let translation = sender.translation(in: sender.view)
            let newCenter = CGPoint(x: viewState.center.x + translation.x, y: viewState.center.y + translation.y)
            viewState.center = newCenter
            updateState(viewState)
            sender.setTranslation(CGPoint.zero, in: sender.view)
        default:
            break
        }
    }
    
    func pinchAction(sender: UIPinchGestureRecognizer) {
//        textView.resignFirstResponder()
//        guard var viewState = viewState else { return }
//        viewState.transform = viewState.transform.scaledBy(x: sender.scale, y: sender.scale)
//        updateState(viewState)
//        sender.scale = 1
        guard var viewState = viewState else { return }
        switch sender.state {
        case .began:
            textView.resignFirstResponder()
        case .changed:
            viewState.transform = viewState.transform.scaledBy(x: sender.scale, y: sender.scale)
            updateState(viewState)
            sender.scale = 1
        default:
            break
        }
    }
    
    func rotateAction(sender: UIRotationGestureRecognizer) {
//        textView.resignFirstResponder()
//        guard var viewState = viewState else { return }
//        viewState.transform = viewState.transform.rotated(by: sender.rotation)
//        updateState(viewState)
//        sender.rotation = 0
        guard var viewState = viewState else { return }
        switch sender.state {
        case .began:
            textView.resignFirstResponder()
        case .changed:
            viewState.transform = viewState.transform.rotated(by: sender.rotation)
            updateState(viewState)
            sender.rotation = 0
        default:
            break
        }
    }
}

// MARK: - UITextView Delegate
extension RPCaptionView: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.bounds.size = textViewContainer.bounds.size
        textView.clipsToBounds = true
        textView.isScrollEnabled = true
        
        lastState = viewState
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.updateState(self.getInitState())
        }
        
        print(self.frame)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let contentSize = textView.contentSize
        textView.clipsToBounds = false
        textView.isScrollEnabled = false
        textView.bounds.size = contentSize
        
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.updateState(self.lastState)
            // self.frame = self.textViewContainer.frame
        }

        // Bring self to front of keyWindow
        UIApplication.shared.keyWindow?.bringSubview(toFront: self)
        
        print("UITextView_Frame: \(self.textView.frame)")
        print("TextViewContainer_Frame: \(self.textViewContainer.frame)")
        print("RPCaptionView_Frame: \(self.frame)")
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
