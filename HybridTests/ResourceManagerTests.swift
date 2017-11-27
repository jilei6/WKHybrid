//
//  HybridTests.swift
//  HybridTests
//
//  Created by jilei on 2016/12/11.
//  Copyright © 2016年 jilei. All rights reserved.
//

import XCTest
@testable import Hybrid

let LocalFile = "http://local/main"
let UnsafeLocalFile = "http://local/unsafe"
let StubUrl = "/local/main"
let TestZipVersion = "1.0"

class ResourceManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        guard let testRoute = Bundle.main.resourceURL?.appendingPathComponent("TestRes/route.json") else {
            XCTAssert(false, "获取路由表失败")
            return
        }
        guard let resPath = Bundle.main.resourceURL?.appendingPathComponent("TestRes/test.zip"), let unsafePath = Bundle.main.resourceURL?.appendingPathComponent("TestRes/unsafe.zip") else {
            XCTAssert(false, "获取mock资源失败")
            return
        }
        
        HybridConfig.routeFilePath = testRoute.path
        
        HTTPMock.map(url: LocalFile, toLocalFile: resPath.path)
        HTTPMock.map(url: UnsafeLocalFile, toLocalFile: unsafePath.path)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        HTTPMock.removeMap(withUrl: LocalFile)
        HTTPMock.removeMap(withUrl: UnsafeLocalFile)
        
        HybridConfig.encryptionKey = nil
    }
    
    // 数据库插入测试
    func testInsertAndQuery() {
        guard let resPath = Util.webappPath else {
            XCTAssert(false, "无法获得资源路径")
            return
        }
        
        let testPath = resPath.appendingPathComponent("localPath")
        let webapp = WebappItem(routeUrl: "/test", localPath: testPath.path, version: "1.0")
        
        XCTAssert(ResourceManager.shared.saveWebapp(webapp), "插入数据库失败")
        
        guard let queryItem = ResourceManager.shared.webapp(withRoute: "/test") else {
            XCTAssert(false, "webapp不存在")
            return
        }
        
        let desPath = resPath.appendingPathComponent("localPath")
        
        XCTAssert(desPath.path == queryItem.localPath.replacingOccurrences(of: "//", with: "/"), "webapp路径错误")
    }
    
    // 资源包删除测试
    func testDelete() {
        guard let resPath = Util.webappPath else {
            XCTAssert(false, "无法获得资源路径")
            return
        }
        guard let testPath = Bundle.main.resourceURL?.appendingPathComponent("TestRes/test.zip"), FileManager.default.fileExists(atPath: testPath.path) else {
            XCTAssert(false, "未找到测试资源包")
            return
        }
        
        // 1. 将资源包解压到指定路径
        let desPath = resPath.appendingPathComponent("/test".md5())
        XCTAssert(Util.unzip(from: testPath, to: desPath), "解压失败")
        
        // 2. 在数据库中插入一条信息
        let webapp = WebappItem(routeUrl: "/test", localPath: desPath.path, version: TestZipVersion)
        XCTAssert(ResourceManager.shared.saveWebapp(webapp), "保存资源包信息失败")
        
        // 3. 删除操作应该同时删除数据库中的信息和目录中实际的资源文件
        XCTAssert(ResourceManager.shared.deleteWebapp("/test"), "删除资源包失败")
        if FileManager.default.fileExists(atPath: desPath.path) {
            XCTAssert(false, "删除资源包失败")
        }
    }
    
    // 资源包打包到本地测试
    func testPreload() {
        guard let preloadPath = Bundle.main.resourceURL?.appendingPathComponent("TestRes") else {
            XCTAssert(false)
            return
        }
        
        HybridConfig.resourcePreloadPath = preloadPath.path
        
        XCTAssert(ResourceManager.shared.webapp(withRoute: "/test") != nil, "预打包资源加载失败")
    }
    
    // 资源包下载测试
    func testDonwload() {
        guard let url = URL(string: LocalFile) else {
            XCTAssert(false, "URL初始化失败")
            return
        }
        
        if let resPath = Bundle.main.resourceURL?.appendingPathComponent("TestRes/test.zip") {
            XCTAssert(FileManager.default.fileExists(atPath: resPath.path), "文件不存在")
        }
        
        // 1. 保证资源包不在缓存中
        ResourceManager.shared.deleteWebapp("/test")
        
        // 2. 下载资源包
        ResourceManager.shared.downloadPackage(url: url, success: { (desUrl) in
            XCTAssert(ResourceManager.shared.webapp(withRoute: "/test") != nil, "资源包信息未保存到数据库")
        }) { (error) in
            XCTAssert(false, "下载失败:\(error)")
        }
    }
    
    // 资源包更新测试
    func testUpdate() {
        guard let url = URL(string: LocalFile) else {
            XCTAssert(false, "URL初始化失败")
            return
        }
        guard let tempPath = Util.webappTempPath else {
            XCTAssert(false)
            return
        }
        
        let oldWebapp = WebappItem(routeUrl: "/test", localPath: "aa/bb/cc", version: "1.0")
        ResourceManager.shared.saveWebapp(oldWebapp)
        
        ResourceManager.shared.downloadPackage(url: url, success: { (desUrl) in
            let targetPath = tempPath.appendingPathComponent("/test".md5())
            if let currWebapp = ResourceManager.shared.webapp(withRoute: "/test") {
                XCTAssert(currWebapp.version == "1.0", "不应该更新数据库信息")
            }
            XCTAssert(FileManager.default.fileExists(atPath: targetPath.path), "更新包为保存到临时目录中")
        }) { (error) in
            XCTAssert(false, "下载失败:\(error)")
        }
    }
    
    // 资源包校验测试, 正常资源包
    func testVerifySafeDigest() {
        guard let url = URL(string: LocalFile) else {
            XCTAssert(false, "URL初始化失败")
            return
        }
        
        ResourceManager.shared.downloadPackage(url: url, success: { (desUrl) in
            
        }) { (error) in
            XCTAssert(false, "下载错误")
        }
    }
    
    // 资源包检验测试, 被篡改资源包
    func testVerifyUnsafeDigest() {
        guard let url = URL(string: LocalFile) else {
            XCTAssert(false, "URL初始化失败")
            return
        }
        
        HybridConfig.encryptionKey = "divngefkdpqlcmferfxef3de"
        
        ResourceManager.shared.downloadPackage(url: url, success: { (desUrl) in
            XCTAssert(false, "资源包校验出错")
        }) { (error) in
            XCTAssert((error as NSError).code == 6006, "下载失败")
        }
    }
}
