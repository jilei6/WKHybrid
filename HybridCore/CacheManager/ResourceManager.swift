//
//  ResourceManager.swift
//  Hybrid
//
//  Created by jilei on 2017/4/16.
//  Copyright © 2017年 jilei. All rights reserved.
//

import UIKit
import objective_zip

internal class ResourceManager: NSObject {
    
    public static let shared = ResourceManager()
    
    /// 查询一个资源包信息
    public func webapp(withRoute url: String) -> WebappItem? {
        return selectWebapp(routeUrl: url)
    }
    
    /// 保存资源包信息
    @discardableResult public func saveWebapp(_ webapp: WebappItem) -> Bool {
        return insert(webapp)
    }
    
    /// 删除一个资源包
    ///
    /// - Parameter routeUrl: 资源包的路由URL
    /// - Returns:            删除成功返回true，否则false
    @discardableResult public func deleteWebapp(_ routeUrl: String) -> Bool {
        if let webapp = webapp(withRoute: routeUrl), delete(routeUrl: routeUrl) {
            do {
                try FileManager.default.removeItem(at: webapp.localUrl)
                return true
            } catch {
                LogError("资源包文件删除失败: \(error)")
            }
        }
        
        return false
    }
    
    /// 下载一个资源包
    ///
    /// - Parameters:
    ///   - url:     资源包下载url
    ///   - success: 下载成功回调
    ///   - failure: 下载失败回调
    @discardableResult public func downloadPackage(url: URL, success: ((URL) -> Void)?, failure: ((Error) -> Void)?) -> DownloadTask? {
        let callback = { (desUrl: URL?, error: Error?) in
            if let error = error {
                failure?(error)
            } else if let desUrl = desUrl {
                success?(desUrl)
            } else {
                failure?(NSError(domain: "Download file location unkown", code: 6000, userInfo: nil))
            }
        }
        
        // 下载任务已存在
        if let downloadingTask = downloadingTasks[url.absoluteString] {
            downloadingTask.addCompletionCallback(callback)
            return downloadingTask
        }
        
        // 从路由表中查找路由URL
        if let routeUrl = Router.shared.routeUrl(with: url), let session = session {
            let task = DownloadTask.startDownloadTask(in: session, downloadUrl: url, routeUrl: routeUrl, completion: callback)
            downloadingTasks[url.absoluteString] = task
            return task
        }
        return nil
    }
    
    /// 预先打包到App中的资源包路径
    public var resourcePreloadPath: String = "" {
        didSet {
            guard FileManager.default.fileExists(atPath: resourcePreloadPath) else {
                LogWarning("资源目录不存在:\(resourcePreloadPath)")
                return
            }
            guard let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: resourcePreloadPath), includingPropertiesForKeys: [.pathKey]) else {
                LogWarning("无法遍历目录\(resourcePreloadPath)")
                return
            }
            
            // 遍历预装的资源包目录
            for file in enumerator {
                guard let fileUrl = file as? URL,
                    let fileInfo = try? fileUrl.resourceValues(forKeys: [.pathKey]),
                    let zipPath = fileInfo.path,
                    zipPath.lowercased().hasSuffix(".zip") else {
                        continue
                }
                
                guard let info = Util.loadJsonObject(fromZip: URL(fileURLWithPath: zipPath)) as? [String : String], let webappPath = Util.webappPath else {
                    continue
                }
                
                if let route = info[Router.Constant.RouteUrl], let version = info[Router.Constant.Version] {
                    let targetPath = webappPath.appendingPathComponent(route.md5()) // 资源包安装路径
                    
                    // 资源包已存在则判断版本
                    if let webapp = self.webapp(withRoute: route) {
                        // 当前资源包版本较低则更新
                        if webapp.version < version && Util.unzip(from: URL(fileURLWithPath: zipPath), to: targetPath) {
                           self.insert(WebappItem(routeUrl: route, localPath: targetPath.path, version: version))
                           LogVerbose("'\(route)'资源包更新成功，当前版本: \(version)")
                        }
                    }
                    // 资源包不存在则直接解压到安装目录
                    else if Util.unzip(from: URL(fileURLWithPath: zipPath), to: targetPath) {
                        self.insert(WebappItem(routeUrl: route, localPath: targetPath.path, version: version))
                    }
                }
            }
        }
    }
    
    override init() {
        super.init()
        initDatabase()
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Private
    
    fileprivate let sqlQueue: DispatchQueue = DispatchQueue(label: "Hybrid.com.database")
    fileprivate var downloadingTasks: [String : DownloadTask] = [:] // URL字符串作为key
    fileprivate var session: URLSession? = nil
}

// MARK: - URLSessionDownloadDelegate

extension ResourceManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let url = downloadTask.originalRequest?.url?.absoluteString, let task = downloadingTasks[url] {
            task.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let url = task.originalRequest?.url?.absoluteString, let downloadingTask = downloadingTasks[url] {
            downloadingTask.urlSession(session, task: task, didCompleteWithError: error)
            downloadingTasks.removeValue(forKey: url)
        }
    }
}

// MARK: - Database

internal extension ResourceManager {
    
    private struct Table {
        static let Name = "ResourceTable"
        static let RouteUrl = "route_url" // key
        static let ZipPath = "zip_path"
        static let LocalPath = "local_path"
        static let Version = "version"
    }
    
    fileprivate var sqlPath: URL? {
        if let webappPath = Util.webappPath {
            return webappPath.appendingPathComponent("Hybrid.db")
        }
        return nil
    }
    
    fileprivate func initDatabase() {
        if let webappPath = Util.webappPath {
            let sqlUrl = webappPath.appendingPathComponent("Hybrid.db")
            _ = Util.createFileIfNotExist(withPath: sqlUrl.path)
        }
        
        query { (database) -> Bool in
            let createTable = "create table if not exists \(Table.Name)(" +
                "\(Table.RouteUrl) text primary key, " +
                "\(Table.LocalPath) text, " +
                "\(Table.Version) text);"
            if sqlite3_exec(database, createTable, nil, nil, nil) != SQLITE_OK {
                LogError("创建数据库表失败: \(String(cString: sqlite3_errmsg(database)))")
                return false
            }
            
            return true
        }
    }
    
    /// 根据Route URL查询资源包信息
    ///
    /// - Parameter routeUrl: 路由URL
    /// - Returns:            包含资源包信息的`WebappItem`实例
    fileprivate func selectWebapp(routeUrl: String) -> WebappItem? {
        var webapp: WebappItem? = nil
        
        let sema = DispatchSemaphore(value: 0)
        query({ (database) -> Bool in
            let sql = "select * from \(Table.Name) where \(Table.RouteUrl)=\"\(routeUrl)\";"
            var stat: OpaquePointer? = nil
            var result = false
            
            if sqlite3_prepare_v2(database, sql, -1, &stat, nil) == SQLITE_OK {
                if sqlite3_step(stat) == SQLITE_ROW {
                    webapp = WebappItem()
                    if let routeUrl = sqlite3_column_text(stat, 0) {
                        webapp?.routeUrl = String(cString: routeUrl)
                    }

                    if let localPath = sqlite3_column_text(stat, 1), let rootPath = Util.appSpportPath {
                        webapp?.localPath = rootPath.appendingPathComponent(String(cString: localPath)).path
                    }
                    if let version = sqlite3_column_text(stat, 2) {
                        webapp?.version = String(cString: version)
                    }
                    result = true
                }
            }
            sqlite3_finalize(stat)
            sema.signal()
            
            return result
        })
        
        sema.wait()
        
        return webapp
    }
    
    /// 插入一条资源包信息
    ///
    /// - Parameter item: 包含资源包信息的`WebappItem`实例
    /// - Returns:        插入成功返回true，否则返回false
    @discardableResult fileprivate func insert(_ item: WebappItem) -> Bool {
        return query({ (database) -> Bool in
            guard let relativePath = item.localUrl.relatedTo(Util.appSpportPath)?.path else {
                return false
            }
            let sql = "insert or replace into \(Table.Name) values ('\(item.routeUrl)', '\(relativePath)', '\(item.version)');"
            if sqlite3_exec(database, sql, nil, nil, nil) != SQLITE_OK {
                LogError("Fail to insert into Table \(Table.Name): \(String(cString: sqlite3_errmsg(database)))")
                return false
            }
            return true
        })
    }
    
    /// 从数据库中删除一条数据
    ///
    /// - Parameter zipUrl: 资源压缩包路径
    /// - Returns: 删除成功返回true，否则false
    @discardableResult fileprivate func delete(routeUrl: String) -> Bool {
        return query({ (database) -> Bool in
            let sql = "delete from \(Table.Name) where \(Table.RouteUrl)='\(routeUrl)';"
            if sqlite3_exec(database, sql, nil, nil, nil) != SQLITE_OK {
                LogError("Fail to delete from Table \(Table.Name): \(String(cString: sqlite3_errmsg(database)))")
                return false
            }
            return true
        })
    }
    
    /// 执行一条数据库查询
    ///
    /// - Parameter block: 在block中执行数据库操作
    /// - Returns:         操作成功返回true，否则返回false
    @discardableResult fileprivate func query(_ block: (_ database: OpaquePointer?) -> Bool) -> Bool {
        guard let sqlPath = sqlPath?.path else {
            return false
        }
        
        var result: Bool = true
        self.sqlQueue.sync {
            var database: OpaquePointer? = nil
            if sqlite3_open(sqlPath, &database) != SQLITE_OK {
                LogError("打开数据库失败: \(String(cString: sqlite3_errmsg(database)))")
                result = false
                return
            }
            
            result = block(database)
            
            if sqlite3_close(database) != SQLITE_OK {
                LogError("关闭数据库失败: \(String(cString: sqlite3_errmsg(database)))")
            }
        }
        return result
    }
}
