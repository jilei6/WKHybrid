//
//  HTTPMock.swift
//  Hybrid
//
//  Created by jilei on 2016/12/16.
//  Copyright © 2016年 jilei. All rights reserved.
//

import UIKit

@objc class HTTPMock: URLProtocol {
    
    // MARK: - Public 
    
    /// 将请求url映射到本地的文件
    static public func map(url: String, toLocalFile filePath: String) {
        HTTPMock.localFileMaps[url] = filePath
    }
    
    /// 将对某一域名的所有请求映射到本地文件夹
    static public func map(domain: String, toLocalDir dir: String) {
        HTTPMock.localDirMaps[domain] = dir
    }
    
    /// 取消对url的映射
    static public func removeMap(withUrl url: String) {
        if HTTPMock.localFileMaps.keys.contains(url) {
            HTTPMock.localFileMaps.removeValue(forKey: url)
        }
        if HTTPMock.localDirMaps.keys.contains(url) {
            HTTPMock.localDirMaps.removeValue(forKey: url)
        }
    }
    
    override class func initialize() {
        URLProtocol.registerClass(HTTPMock.self)
    }
    
    deinit {
        URLProtocol.unregisterClass(HTTPMock.self)
    }
    
    // MARK: - Private
    
    fileprivate static var localFileMaps: [String: String] = [:]
    fileprivate static var localDirMaps: [String: String] = [:]
    fileprivate static let queue = DispatchQueue(label: "HTTPMock.queue")
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else {
            return false
        }
        
        if let userAgent = request.allHTTPHeaderFields?["User-Agent"], userAgent.hasPrefix("Mozilla") {
            return false
        }
        
        if HTTPMock.localFileMaps.keys.contains(url.absoluteString) {
            return true
        }
        
        if let host = url.host, HTTPMock.localDirMaps.keys.contains(host) {
            return true
        }
        
        return false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let key = self.request.url?.absoluteString else {
            self.client?.urlProtocol(self, didFailWithError: CFNetworkErrors.cfurlErrorUnknown as! Error)
            return
        }
        guard let url = self.request.url else {
            self.client?.urlProtocol(self, didFailWithError: CFNetworkErrors.cfurlErrorUnknown as! Error)
            return
        }
        
        repeat {
            do {
                // 文件映射
                if let mapLocalPath = HTTPMock.localFileMaps[key] {
                    let data = try Data(contentsOf: URL(string: "file://" + mapLocalPath)!)
                    let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])
                    self.client?.urlProtocol(self, didReceive: httpResponse!, cacheStoragePolicy: URLCache.StoragePolicy.notAllowed)
                    self.client?.urlProtocol(self, didLoad: data)
                    self.client?.urlProtocolDidFinishLoading(self)
                    break
                }
                
                // 域名映射
                if let host = url.host, let mapLocalDir = HTTPMock.localDirMaps[host] {
                    let localPath = mapLocalDir + url.path
                    let data = try Data(contentsOf: URL(string: "file://" + localPath)!)
                    let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])
                    self.client?.urlProtocol(self, didReceive: httpResponse!, cacheStoragePolicy: URLCache.StoragePolicy.notAllowed)
                    self.client?.urlProtocol(self, didLoad: data)
                    self.client?.urlProtocolDidFinishLoading(self)
                    break
                }
            } catch {
                print("\(error)")
            }
        } while false
    }
    
    override func stopLoading() {
        
    }
}
