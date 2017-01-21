//
//  StackPageView.swift
//  osaki
//
//  Created by Tomoya Hirano on 2015/11/11.
//  Copyright © 2015年 Tomoya Hirano. All rights reserved.
//

import UIKit


public protocol StackViewDataSource {
    func stackViewPrev(_ currentViewController:UIViewController?)->UIViewController?
    func stackViewNext(_ currentViewController:UIViewController?)->UIViewController?
}

class StackPageView:UIView {
    //MustInit!!
    var parentViewController:UIViewController!
    
    var prevContainer:PageView?
    var currentContainer = PageView()
    var nextContainer:PageView?
    var dataSource:StackViewDataSource?
    var offset:CGFloat = 64
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setup(){
        clipsToBounds = true
        currentContainer.backgroundColor = UIColor.red
        currentContainer.frame = bounds
        addSubview(currentContainer)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(StackPageView.panAction(_:)))
        addGestureRecognizer(pan)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        currentContainer.frame = bounds
    }
    
    func panAction(_ gesture:UIPanGestureRecognizer){
        let p = gesture.translation(in: self)
        if gesture.state == .began {
            if let prev = dataSource?.stackViewPrev(currentContainer.viewController) {
                parentViewController.addChildViewController(prev)
                prevContainer = PageView()
                prevContainer?.frame = currentContainer.bounds
                prevContainer?.viewController = prev
                prevContainer?.center = CGPoint(x: bounds.width/2, y: -bounds.height/2)
                addSubview(prevContainer!)
                prev.didMove(toParentViewController: parentViewController)
            }
            if let next = dataSource?.stackViewNext(currentContainer.viewController) {
                parentViewController.addChildViewController(next)
                nextContainer = PageView()
                nextContainer?.frame = currentContainer.bounds
                nextContainer?.viewController = next
                insertSubview(nextContainer!, belowSubview: currentContainer)
                next.didMove(toParentViewController: parentViewController)
            }
        }else if gesture.state == .changed {
            if p.y < 0 {
                currentContainer.center.y = bounds.height/2 + p.y
                prevContainer?.center.y = -bounds.height/2
            }else if p.y > 0 {
                currentContainer.center.y = bounds.height/2
                let prevPosY = -bounds.height/2 + p.y
                if prevPosY < bounds.height/2 {
                    prevContainer?.center.y = prevPosY
                }else{
                    prevContainer?.center.y = bounds.height/2
                }
            }
        }else if gesture.state == .ended {
            UIView.animate(withDuration: 0.5, delay: 0,
                options: [.curveEaseOut], animations: { () -> Void in
                    
                    if p.y < -self.offset && self.nextContainer != nil {
                        self.currentContainer.center.y = -self.bounds.height/2
                    }else if p.y > self.offset && self.prevContainer != nil {
                        self.prevContainer?.center.y = self.bounds.height/2
                    }else{
                        self.prevContainer?.center.y = -self.bounds.height/2
                        self.currentContainer.center.y = self.bounds.height/2
                    }
                    
                }, completion: { (_) -> Void in
                    
                    if p.y < -self.offset && self.nextContainer != nil {
                        self.currentContainer.viewController?.willMove(toParentViewController: nil)
                        self.prevContainer?.viewController?.willMove(toParentViewController: nil)
                        self.currentContainer.viewController?.removeFromParentViewController()
                        self.prevContainer?.viewController?.removeFromParentViewController()
                        self.currentContainer.viewController = self.nextContainer?.viewController
                    }else if p.y > self.offset && self.prevContainer != nil {
                        self.currentContainer.viewController?.willMove(toParentViewController: nil)
                        self.nextContainer?.viewController?.willMove(toParentViewController: nil)
                        self.currentContainer.viewController?.removeFromParentViewController()
                        self.nextContainer?.viewController?.removeFromParentViewController()
                        self.currentContainer.viewController = self.prevContainer?.viewController
                    }
                    self.prevContainer?.removeFromSuperview()
                    self.prevContainer = nil
                    self.nextContainer?.removeFromSuperview()
                    self.nextContainer = nil
                    self.currentContainer.center = CGPoint(x: self.bounds.width/2, y: self.bounds.height/2)
                    
            })
        }
    }
}

class PageView:UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var viewController:UIViewController?{
        didSet{
            let v = viewController?.view
            v?.frame = bounds
            v?.removeFromSuperview()
            for sv in subviews {
                sv.removeFromSuperview()
            }
            addSubview(v!)
        }
    }
}
