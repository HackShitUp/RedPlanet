//  Converted with Swiftify v1.0.6221 - https://objectivec2swift.com/
//
//  JotDrawingContainer.h
//  jot
//
//  Created by Laura Skelton on 5/12/15.
//
//
import UIKit
import Foundation

class JotDrawingContainer: UIView {
    /**
     *  The delegate of the JotDrawingContainer, which receives
     *  updates about touch events in the drawing container.
     */
    weak var delegate: JotDrawingContainerDelegate?

// MARK: - Touches

    override func touchesBegan(_ touches: Set<AnyHashable>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        self.delegate.jotDrawingContainerTouchBegan(at: touches.first?.location(in: self))
    }

    override func touchesMoved(_ touches: Set<AnyHashable>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        self.delegate.jotDrawingContainerTouchMoved(to: touches.first?.location(in: self))
    }

    override func touchesEnded(_ touches: Set<AnyHashable>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        self.delegate.jotDrawingContainerTouchEnded()
    }
}
protocol JotDrawingContainerDelegate: NSObjectProtocol {
    /**
     *  Tells the delegate to handle a touchesBegan event.
     *
     *  @param touchPoint The point in this view's coordinate
     *  system where the touch began.
     */
    func jotDrawingContainerTouchBegan(at touchPoint: CGPoint)
    /**
     *  Tells the delegate to handle a touchesMoved event.
     *
     *  @param touchPoint The point in this view's coordinate
     *  system to which the touch moved.
     */

    func jotDrawingContainerTouchMoved(to touchPoint: CGPoint)
    /**
     *  Tells the delegate to handle a touchesEnded event.
     */

    func jotDrawingContainerTouchEnded()
}
//
//  JotDrawingContainer.m
//  jot
//
//  Created by Laura Skelton on 5/12/15.
//
//