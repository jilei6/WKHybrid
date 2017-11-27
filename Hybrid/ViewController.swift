//
//  ViewController.swift
//  TheOneHybrid
//
//  Created by jilei on 2017/11/14.
//  Copyright © 2017年 jilei. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false);
        // Do any additional setup after loading the view, typically from a nib.
        URLProtocol.wk_registerScheme("http");
        URLProtocol.wk_registerScheme("http");
        HybridConfig.encryptionKey = "divngefkdpqlcmferfxef3de"
        
        if let preload = Bundle.main.resourceURL?.appendingPathComponent("HybridResource") {
            HybridConfig.resourcePreloadPath = preload.path
        }
        
        if let resUrl = Bundle.main.resourceURL {
            let url = resUrl.appendingPathComponent("HybridResource").appendingPathComponent("route.json")
            HybridConfig.routeFilePath = url.path
        }

        if let web = Router.shared.webView(routeUrl: "main") {
            web.delegate = self
            web.scrollView.bounces = false;
            web.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height )
            self.view.addSubview(web)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: WebViewDelegate {
    func failView(in webView: WebView, error: NSError) -> UIView? {
        NSLog("error---%@", error);
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        view.backgroundColor = UIColor.red
        return view
    }
}
