//
//  WebView.swift
//  TheOneHybrid
//
//  Created by jilei on 2017/11/14.
//  Copyright © 2017年 jilei. All rights reserved.
//
//

import UIKit
import GCDWebServer

@objc public protocol WebViewDelegate {
    // 提供一个失败状态的视图，在加载失败时该视图会覆盖在WebView之上
    func failView(in webView: WebView, error: NSError) -> UIView?
}

public class WebView: WKWebView {

    // MARK: - Public
    
    public weak var delegate: WebViewDelegate? = nil
    
    public override func loadFileURL(_ URL: URL, allowingReadAccessTo readAccessURL: URL) -> WKNavigation? {
//        if #available(iOS 9.0, *) {
//            return super.loadFileURL(URL, allowingReadAccessTo: readAccessURL)
//        } else {
             //readAccessURL必须是文件夹，且包含文件URL
            if !Util.isFolder(url: readAccessURL) {
                LogError("'\(readAccessURL.path)'不是文件夹")
                return nil
            }
        
       
            var relationship: FileManager.URLRelationship = .other
            do {
                try FileManager.default.getRelationship(&relationship, ofDirectoryAt: readAccessURL, toItemAt: URL)
            } catch {
                LogError("获取文件关系失败: \(error)")
            }
            
            if relationship == .other {
                LogError("'\(readAccessURL.path)'目录中必须包含'\(URL.path)'文件")
                return nil
            }
            
            // 启动HTTP Server
            let port: UInt = 8008
            if !WebView.server.isRunning {
                WebView.server.addGETHandler(forBasePath: "/", directoryPath: readAccessURL.path, indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)
                WebView.server.start(withPort: port, bonjourName: nil)
            }

//            guard let relatedPath = URL.relatedTo(Util.webappPath)?.path else {
//                return nil
//            }
        
            var urlConponment = URLComponents(string: "http://127.0.0.1")
            urlConponment?.port = Int(port)
            urlConponment?.path = "/main.html"
            if let url = urlConponment?.url {
                return self.load(URLRequest(url: url))
            } else {
                return nil
            }
        }
//    }
    
    /// 通过路由URL加载一个页面
    ///
    /// - Parameter routeUrl: 资源包的Route URL
    public func load(routeUrl: String) {
        if let webapp = ResourceManager.shared.webapp(withRoute: routeUrl) { // 已缓存在本地
            load(url: URL(fileURLWithPath: webapp.localPath))
        } else if let downloadUrl = Router.shared.downloadUrl(with: routeUrl) { // 否则下载
            ResourceManager.shared.downloadPackage(url: downloadUrl, success: { (localPath) in
                self.load(url: localPath)
            }, failure: { (error) in
                if let delegate = self.delegate, let view = delegate.failView(in: self, error: error as NSError) {
                    self.addSubview(view)
                    view.center = CGPoint(x: self.bounds.size.width / 2, y: self.bounds.height / 2)
                }
            })
        }
    }
    
    /// 通过URL加载资源
    ///
    /// - Parameter url: 资源URL，支持网络资源、本地文件和本地文件夹
    public func load(url: URL) {
        if url.isFileURL {
             if Util.isFolder(url: url) { // 加载一个本地的文件夹
                // 读取webapp_info.json文件
                let infoUrl = url.appendingPathComponent(Util.Constant.webappInfoFile)
                
                guard FileManager.default.fileExists(atPath: infoUrl.path) else {
                    LogError("目录'\(url.path)'中未找到配置文件`\(Util.Constant.webappInfoFile)`")
                    return
                }
                guard let profile = Util.loadJsonObject(fromUrl: infoUrl) as? [String : String] else {
                    return
                }
                
                if let entrance = profile["entrance"] {
                    LogVerbose("加载本地资源包: '\(url.path)'\n入口文件: '\(entrance)'")
                    let entranceUrl = url.appendingPathComponent(entrance)
                    _ = loadFileURL(entranceUrl, allowingReadAccessTo: url)
                } else {
                    LogError("未指定入口文件: '\(infoUrl.path)'")
                }
            } else { // 加载一个单独的本地文件
                let request = URLRequest(url: url)
                self.load(request)
            }
        } else {
            let request = URLRequest(url: url)
            self.load(request)
        }
    }
    
    convenience init() {
        self.init(frame: CGRect.zero, configuration: WKWebViewConfiguration())
    }
    
    convenience init(frame: CGRect, url: URL) {
        self.init(frame: frame, configuration: WKWebViewConfiguration())
        load(url: url)
    }
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        bridge = ReflectJavascriptBridge(self)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    fileprivate var bridge: ReflectJavascriptBridge?
    fileprivate static let server: GCDWebServer = GCDWebServer()
}
