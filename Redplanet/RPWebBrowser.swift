//
//  RPWebBrowser.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/13/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import WebKit

class RPWebBrowser: UIViewController , WKUIDelegate {
    
    var webView: WKWebView!
    open var urlToGet: String!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UIView
        self.view.roundTopCorners(sender: self.view)
        
        let myURL = URL(string: self.urlToGet!)
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Clear WKWebViewCache
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = NSDate(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date as Date, completionHandler:{ })
    }
    
}
