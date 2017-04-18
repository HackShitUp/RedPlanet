//
//  RPCaptionContainer.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/17/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import Foundation

class RPCaptionContainer: UIView {

    struct ViewState {
        var transform = CGAffineTransform.identity
        var center = CGPoint.zero
    }
    
    fileprivate var textViewContainer = UIView()
    fileprivate var textView = RPTextView()
    
    fileprivate var pinchGesture: UIPinchGestureRecognizer!
    fileprivate var panGesture: UIPanGestureRecognizer!
    fileprivate var rotateGesture: UIRotationGestureRecognizer!
    fileprivate var tapGesture: UITapGestureRecognizer!
    
    fileprivate private(set) var viewState: ViewState?
    fileprivate var lastState: ViewState?
    
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configurate()
    }
    
    override var isFirstResponder: Bool {
        return textView.isFirstResponder
    }
    
    override func becomeFirstResponder() -> Bool {
        self.superview?.bringSubview(toFront: self.textViewContainer)
        self.textViewContainer.superview?.bringSubview(toFront: self.textViewContainer)
        self.textView.superview?.bringSubview(toFront: self.textView)
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
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinGesture(_:)))
        addGestureRecognizer(pinchGesture)
        pinchGesture.delegate = self
        
        rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotateGesture(_:)))
        addGestureRecognizer(rotateGesture)
        rotateGesture.delegate = self
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        addGestureRecognizer(panGesture)
        panGesture.delegate = self
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        addGestureRecognizer(tapGesture)
        tapGesture.delegate = self
        
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
    }
}

// MARK: - UIGestureRecognizer Delegate
extension RPCaptionContainer: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.view?.isKind(of: UITextView.classForCoder()) == false &&
            otherGestureRecognizer.view?.isKind(of: UITextView.classForCoder()) == false
    }
}

// MARK: - Gesture Handler
extension RPCaptionContainer {
    
    func handleTapGesture(_ gesture: UIPanGestureRecognizer) {
        textView.resignFirstResponder()
    }
    
    func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard var viewState = viewState else { return }
        switch gesture.state {
        case .began:
            textView.resignFirstResponder()
        case .changed:
            let translation = gesture.translation(in: gesture.view)
            let newCenter = CGPoint(x: viewState.center.x + translation.x, y: viewState.center.y + translation.y)
            viewState.center = newCenter
            updateState(viewState)
            gesture.setTranslation(CGPoint.zero, in: gesture.view)
        default:
            break
        }
    }
    
    func handlePinGesture(_ gesture: UIPinchGestureRecognizer) {
        guard var viewState = viewState else { return }
        switch gesture.state {
        case .began:
            textView.resignFirstResponder()
        case .changed:
            viewState.transform = viewState.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            updateState(viewState)
            gesture.scale = 1
        default:
            break
        }
    }
    
    func handleRotateGesture(_ gesture: UIRotationGestureRecognizer) {
        guard var viewState = viewState else { return }
        switch gesture.state {
        case .began:
            textView.resignFirstResponder()
        case .changed:
            viewState.transform = viewState.transform.rotated(by: gesture.rotation)
            updateState(viewState)
            gesture.rotation = 0
        default:
            break
        }
    }
}

// MARK: - UITextView Delegate
extension RPCaptionContainer: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.bounds.size = textViewContainer.bounds.size
        textView.clipsToBounds = true
        textView.isScrollEnabled = true
        self.bounds = UIScreen.main.bounds
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
        
        self.bounds.size = textView.bounds.size
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.updateState(self.lastState)
        }
    }
    
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            _ = self.resignFirstResponder()
        }
        return true
    }
}
