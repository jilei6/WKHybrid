//
//  DownloadTask.swift
//  Hybrid
//
//  Created by jilei on 2017/4/22.
//  Copyright © 2017年 jilei. All rights reserved.
//

import UIKit

class DownloadTask: NSObject {
    
    /// desUrl: 资源包解压后的的路径
    /// error:  错误类型，成功则为nil
    typealias CompletionCallback = (_ desUrl: URL?, _ error: Error?) -> Void
    
    /// 创建并启动一个下载任务
    ///
    /// - Parameters:
    ///   - session:     URLSession实例
    ///   - downloadUrl: 下载文件的URL
    ///   - routeUrl:    该资源包的路由URL
    ///   - completion:  下载完成的回调
    /// - Returns:       下载任务DownloadTask实例
    public class func startDownloadTask(in session: URLSession,
                                        downloadUrl: URL,
                                        routeUrl: String,
                                        completion: @escaping CompletionCallback) -> DownloadTask {
        let task = DownloadTask(session: session, downloadUrl: downloadUrl, routeUrl: routeUrl)
        task.addCompletionCallback(completion)
        task.resume()
        return task
    }
    
    /// 返回当前正在下载文件的URL字符串
    public var downloadingUrl: String {
        return downloadUrl.absoluteString
    }
    
    /// 添加一个下载结束时的回调
    ///
    /// - Parameter block: 下载结束时调用的闭包，desUrl: 下载文件的保存位置，error: 是否发生错误
    public func addCompletionCallback(_ block: @escaping CompletionCallback) {
        completionBlocks.append(block)
    }
    
    /// 开始下载
    public func resume() {
        task?.resume()
    }
    
    /// 暂停下载
    public func suspend() {
        task?.suspend()
    }
    
    /// 取消下载
    public func cancel() {
        task?.cancel()
    }
    
    init(session: URLSession, downloadUrl: URL, routeUrl: String) {
        self.routeUrl = routeUrl
        self.downloadUrl = downloadUrl
        
        super.init()
        
        task = session.downloadTask(with: downloadUrl)
    }
    
    // MARK: - Private
    
    fileprivate var downloadUrl: URL
    fileprivate var routeUrl: String
    fileprivate var task: URLSessionDownloadTask? = nil
    fileprivate var completionBlocks: [CompletionCallback] = []
    
    fileprivate func callback(_ desUrl: URL?, _ error: Error?) {
        for callback in completionBlocks {
            callback(desUrl, error)
        }
        completionBlocks.removeAll()
    }
    
    /// 校验资源包完整性
    fileprivate func verifyPackage(_ path: URL) -> Bool {
        if let key = HybridConfig.encryptionKey { // 如果启用验证
            if let md5 = Router.shared.md5(for: routeUrl) {
                return ValidationChecker.validateFile(path, with: md5, using: key)
            } else {
                LogError("路由表中缺少资源包'\(routeUrl)'的MD5信息，校验失败")
                return false
            }
        } else {
            return true
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadTask: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let webappPath = Util.webappPath else {
            callback(nil, NSError(domain: "无法访问 'Application Support/Hybrid/webapp'", code: 6001, userInfo: nil))
            return
        }
        
        // 资源包校验
        guard verifyPackage(location) else {
            LogWarning("'\(downloadUrl.absoluteString)'资源包完整性校验失败，可能已被篡改!")
            callback(nil, NSError(domain: "资源包完整性校验失败，可能已被篡改", code: 6006, userInfo: nil))
            return
        }
        
        let localUrl = webappPath.appendingPathComponent(routeUrl.md5())
                
        // 已存在旧的资源包则先解压到临时文件夹, 下次启动时再更新
        if ResourceManager.shared.webapp(withRoute: routeUrl) != nil {
            guard let webappTempPath = Util.webappTempPath else {
                callback(nil, NSError(domain: "无法访问 'Application Support/Hybrid/temp'", code: 6003, userInfo: nil))
                return
            }
            
            let targetPath = webappTempPath.appendingPathComponent(routeUrl.md5())
            if Util.unzip(from: location, to: targetPath) {
                callback(localUrl, nil)
            } else {
                LogError("解压文件'\(location.path)'失败")
                callback(nil, NSError(domain: "Unzip error", code: 6004, userInfo: nil))
            }
        } else {
            if Util.unzip(from: location, to: localUrl) {
                // 将webapp储存到数据库
                // FIXME: 插入数据库的时机和方式可以优化
                var webapp = WebappItem()
                webapp.routeUrl = routeUrl
                webapp.localPath = localUrl.path
                webapp.version = Router.shared.version(for: routeUrl) ?? ""
                ResourceManager.shared.saveWebapp(webapp)
                
                callback(localUrl, nil)
            } else {
                LogError("解压文件'\(location.path)'失败")
                callback(nil, NSError(domain: "Unzip error", code: 6004, userInfo: nil))
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            callback(nil, error)
        }
    }
}
