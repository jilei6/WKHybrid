//
//  Router.swift
//  TheOneHybrid
//
//  Created by jilei on 2017/11/14.
//  Copyright © 2017年 jilei. All rights reserved.
//

import UIKit

@objc public protocol HybridRouterDelegate {
    // 实现该方法并返回一个UIViewController可以自定义路由，返回nil则走默认的路由流程
    func viewController(for routeUrl: String, params: [String : String]) -> UIViewController?
}

public class Router: NSObject {
    
    // MARK: - Public
    
    public static let shared = Router()
    
    public weak var delegate: HybridRouterDelegate? = nil
    
    /// 设置路由表的本地路径
    public var routeFilePath: String = "" {
        didSet {
            applyUpdates()
            
            if !FileManager.default.fileExists(atPath: routeFilePath) {
                LogError("\(routeFilePath)路由表配置文件不存在")
                routeTable = [:]
                return
            }
            
            if let routes = Util.loadJsonObject(fromUrl: URL(fileURLWithPath: routeFilePath)) as? [[String : String]] {
                var table: [String : [String : String]] = [:]
                for routeItem in routes {
                    if let routeUrl = routeItem[Constant.RouteUrl] { // 将route url作为key
                        table[routeUrl] = routeItem
                    } else {
                        LogWarning("路由表:'\(routeFilePath)'缺少'\(Constant.RouteUrl)'")
                    }
                }
                routeTable = table
                downloadPackages()
            } else {
                routeTable = [:]
            }
        }
    }
    
    /// 根据url获取一个ViewController
    ///
    /// - Parameter routeUrl: webapp的url，唯一标示一个Hybrid页面
    /// - Returns:            一个用于展示该页面的WebViewController实例
    public func webViewController(routeUrl: String) -> UIViewController? {
        return webViewController(routeUrl: routeUrl, params: [:])
    }
    
    public func webViewController(routeUrl: String, params: [String : String]) -> UIViewController? {
        if let delegate = delegate, let vc = delegate.viewController(for: routeUrl, params: params) {
            return vc
        } else if let webView = webView(routeUrl: routeUrl, params: params) {
            return WebViewController(webView: webView)
        } else {
            return nil
        }
    }
    
    /// 根据route_url获取一个WebView
    ///
    /// - Parameter routeUrl: 路由URL，唯一标识一个页面
    /// - Returns:            用于展示该页面的WebView
    public func webView(routeUrl: String) -> WebView? {
        return webView(routeUrl: routeUrl, params: [:])
    }
        
    public func webView(routeUrl: String, params: [String : Any]) -> WebView? {
        if routeTable.keys.contains(routeUrl) {
            let webView = WebView()
            webView.load(routeUrl: routeUrl)
            return webView
        } else {
            LogError("Route url '\(routeUrl)' not exist")
        }
        return nil
    }
    
    // MARK: - Internal
    
    /// 根据资源包的`download_url`获取`route_url`
    ///
    /// - Parameter downloadUrl: 资源包下载url
    /// - Returns:               该资源包的的路由
    internal func routeUrl(with downloadUrl: URL) -> String? {
        for (_, routeItem) in routeTable {
            if let download = routeItem[Constant.DownloadUrl], downloadUrl.absoluteString == download {
                return routeItem[Constant.RouteUrl]
            }
        }
        return nil
    }
    
    /// 根据路由URL获取资源包的下载URL
    ///
    /// - Parameter routeUrl: 路由URL字符串
    /// - Returns:            资源包下载URL
    internal func downloadUrl(with routeUrl: String) -> URL? {
        for (_, routeItem) in routeTable {
            if let route = routeItem[Constant.RouteUrl], routeUrl == route, let download = routeItem[Constant.DownloadUrl] {
                return URL(string: download)
            }
        }
        return nil
    }
    
    /// 获取指定资源包的版本
    ///
    /// - Parameter routeUrl: 资源包的路由URL
    /// - Returns:            该资源包的版本号
    internal func version(for routeUrl: String) -> String? {
        for (_, routeItem) in routeTable {
            if let route = routeItem[Constant.RouteUrl], routeUrl == route {
                return routeItem[Constant.Version]
            }
        }
        return nil
    }
    
    /// 获取资源包的MD5
    ///
    /// - Parameter routeUrl: 资源包的路由URL
    /// - Returns:            MD5值
    internal func md5(for routeUrl: String) -> String? {
        for (_, routeItem) in routeTable {
            if let route = routeItem[Constant.RouteUrl], routeUrl == route {
                return routeItem[Constant.MD5]
            }
        }
        return nil
    }
    
    // MARK: - Private
    
    internal struct Constant {
        static let RouteUrl = "route_url"
        static let DownloadUrl = "download_url"
        static let Version = "version"
        static let MD5 = "md5"
    }
    
    fileprivate var routeTable: [String : [String : String]] = [:]; // 路由表
    
    /// 预缓存资源包
    fileprivate func downloadPackages() {
        for (_, routeItem) in routeTable {
            guard let version = routeItem[Constant.Version], let routeUrl = routeItem[Constant.RouteUrl], let download = routeItem[Constant.DownloadUrl] else {
                LogError("路由文件的信息不完整")
                return
            }
            
            // 当前为最新版
            if let webapp = ResourceManager.shared.webapp(withRoute: routeUrl), webapp.version >= version {
                continue
            }
            
            if let donwloadUrl = URL(string: download) {
                ResourceManager.shared.downloadPackage(url: donwloadUrl, success: nil, failure: nil)
            } else {
                LogError("无效的下载链接")
            }
        }
    }
    
    /// 应用更新包
    fileprivate func applyUpdates() {
        guard let tempPath = Util.webappTempPath else {
            LogWarning("Can not access to 'Application Support/Hybrid/temp'")
            return
        }
        guard let enumerator = FileManager.default.enumerator(at: tempPath, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey]) else {
            return
        }
        
        for item in enumerator {
            if let fileUrl = item as? URL, let info = try? fileUrl.resourceValues(forKeys: [URLResourceKey.isDirectoryKey]) {
                if let isDir = info.isDirectory, isDir == true {
                    installPackage(at: fileUrl)
                }
            }
        }
    }
    
    /// 将临时文件夹的资源包移动到目标文件夹中
    fileprivate func installPackage(at tempPath: URL) {
        guard let targetPath = Util.webappPath?.appendingPathComponent(tempPath.lastPathComponent) else {
            LogError("无法访问'Application Support/Hybrid/webapp'")
            return
        }
        guard let webappInfo = Util.loadJsonObject(fromUrl: tempPath.appendingPathComponent(Util.Constant.webappInfoFile)) as? [String : String] else {
            LogError("更新包\(tempPath.lastPathComponent)中没有'\(Util.Constant.webappInfoFile)'文件")
            removePackage(at: tempPath)
            return
        }
        
        do {
            if let route = webappInfo[Constant.RouteUrl], let version = webappInfo[Constant.Version] {
                if FileManager.default.fileExists(atPath: targetPath.path) {
                    try FileManager.default.removeItem(at: targetPath)
                }
                try FileManager.default.moveItem(at: tempPath, to: targetPath)
                
                var webapp = WebappItem()
                webapp.routeUrl = route
                webapp.localPath = targetPath.path
                webapp.version = version
                ResourceManager.shared.saveWebapp(webapp)
                LogVerbose("'\(route)'更新包应用成功, 当前版本: \(version)")
            } else {
                LogError("资源包信息不全")
                removePackage(at: tempPath)
            }
        } catch {
            LogError("移动文件夹失败: \(error)")
        }
    }
    
    /// 删除指定位置的更新包
    fileprivate func removePackage(at path: URL) {
        do {
            try FileManager.default.removeItem(at: path)
        } catch {
            LogError("删除文件失败: \(error)")
        }
    }
}
