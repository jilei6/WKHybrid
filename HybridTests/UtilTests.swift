//
//  Util.swift
//  Hybrid
//
//  Created by jilei on 2017/5/21.
//  Copyright © 2017年 jilei. All rights reserved.
//

import XCTest
@testable import Hybrid

class UtilTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // 测试读取单个json文件
    func testLoadJson() {
        guard let jsonPath = Bundle.main.resourceURL?.appendingPathComponent("TestRes/route.json") else {
            XCTAssert(false)
            return
        }
        
        if let jsonList = Util.loadJsonObject(fromUrl: jsonPath) as? [[String : String]], let json = jsonList.first {
            XCTAssert(json["route_url"] != nil && json["route_url"]! == "/test", "数据错误")
            XCTAssert(json["download_url"] != nil && json["download_url"]! == "http://local/main", "数据错误")
            XCTAssert(json["version"] != nil && json["version"]! == "1.1", "数据错误")
        } else {
            XCTAssert(false, "加载json文件失败")
        }
    }
    
    // 从压缩包中读取json文件
    func testLoadJsonFromZip() {
        guard let zipPath = Bundle.main.resourceURL?.appendingPathComponent("TestRes/test.zip") else {
            XCTAssert(false)
            return
        }
        
        if let json = Util.loadJsonObject(fromZip: zipPath) as? [String : String] {
            XCTAssert(json["route_url"] != nil && json["route_url"]! == "/test", "数据错误")
            XCTAssert(json["entrance"] != nil && json["entrance"]! == "main.html", "数据错误")
            XCTAssert(json["version"] != nil && json["version"]! == "1.1", "数据错误")
        } else {
            XCTAssert(false, "加载json文件失败")
        }
    }
    
    // 解压缩测试
    func testUnzip() {
        guard let zipPath = Bundle.main.resourceURL?.appendingPathComponent("TestRes/test.zip") else {
            XCTAssert(false)
            return
        }
        guard let targetPath = Util.appSpportPath?.appendingPathComponent("/test".md5()) else {
            XCTAssert(false)
            return
        }
        
        if Util.unzip(from: zipPath, to: targetPath) {
            XCTAssert(FileManager.default.fileExists(atPath: targetPath.appendingPathComponent("main.html").path), "解压文件错误")
            XCTAssert(FileManager.default.fileExists(atPath: targetPath.appendingPathComponent("global.css").path), "解压文件错误")
            XCTAssert(FileManager.default.fileExists(atPath: targetPath.appendingPathComponent("webapp_info.json").path), "解压文件错误")
        } else {
            XCTAssert(false, "解压失败")
        }
    }
}
