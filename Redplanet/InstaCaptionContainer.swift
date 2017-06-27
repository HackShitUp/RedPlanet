//
//  InstaCaptionContainer.swift
//  InstagramCaption
//
//  Created by NAH on 2/11/17.
//  Copyright © 2017 NAH. All rights reserved.
//

import Foundation
import UIKit

class InstaCaptionContainer: UIView {
    
    struct ViewState {
        var transform = CGAffineTransform.identity
        var center = CGPoint.zero
    }
    
    open var textViewContainer = UIView()
    open var textView = InstaTextView()
    
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
        print("isFirstResponder --> \(self.isFirstResponder)")
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
        addSubview(textViewContainer)
        
        textView.frame = textViewContainer.bounds
        textViewContainer.addSubview(textView)
        textView.configurate()
        textView.delegate = self
        self.tintColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        
        // PAN
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        panGesture.delegate = self
        self.textViewContainer.addGestureRecognizer(panGesture)
        
        // PINCH
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:)))
        pinchGesture.delegate = self
        self.textViewContainer.addGestureRecognizer(pinchGesture)
        
        // ROTATE
        rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateAction(_:)))
        rotateGesture.delegate = self
        self.textViewContainer.addGestureRecognizer(rotateGesture)
        
        // TAP
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        tapGesture.delegate = self
        self.textViewContainer.addGestureRecognizer(tapGesture)
        
        viewState = getInitState()
        updateState(viewState)

        textView.alpha = 1
        textView.backgroundColor = UIColor.clear
        textViewContainer.alpha = 1
        textViewContainer.backgroundColor = UIColor.clear
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
extension InstaCaptionContainer: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Gesture Handler
extension InstaCaptionContainer {
    
    func tapAction(_ gesture: UITapGestureRecognizer) {
        textView.becomeFirstResponder()
    }
    
    func panAction(_ gesture: UIPanGestureRecognizer) {
        guard var viewState = viewState else { return }
        textView.resignFirstResponder()
        viewState.center = gesture.location(in: self)
        updateState(viewState)
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    func pinchAction(_ gesture: UIPinchGestureRecognizer) {
        guard var viewState = viewState else { return }
        textView.resignFirstResponder()
        viewState.transform = viewState.transform.scaledBy(x: gesture.scale, y: gesture.scale)
        updateState(viewState)
        gesture.scale = 1
    }
    
    func rotateAction(_ gesture: UIRotationGestureRecognizer) {
        guard var viewState = viewState else { return }
        textView.resignFirstResponder()
        viewState.transform = viewState.transform.rotated(by: gesture.rotation)
        updateState(viewState)
        gesture.rotation = 0
    }
}

// MARK: - UITextView Delegate
extension InstaCaptionContainer: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            _ = self.resignFirstResponder()
        }
        
        return true
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
    }
}
