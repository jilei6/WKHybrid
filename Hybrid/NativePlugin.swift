//
//  NativePlugin.swift
//  Hybrid
//
//  Created by jilei on 2017/4/9.
//  Copyright © 2017年 jilei. All rights reserved.
//

import UIKit

@objc protocol NativePluginProtocol: PluginExport {
    func sample1()
    func sample2(_ param: String)
    func sample3() -> String
    func sample4(_ str1: String, _ str2: String) -> String
    func sample5(_ a: Int, _ b: Float, _ c: Double) -> String
    func sample6(_ array: [Any], _ dic: [String : Any]) -> String
    func sample7(_ callback: RJBCallback) -> String
}

class NativePlugin: NSObject, NativePluginProtocol {
    
    class func pluginName() -> String! {
        return "plugin"
    }
    
    // 无参数，无返回值
    func sample1() {
        print("JS调用native.sample1")
    }
    
    // 有参数，无返回值
    func sample2(_ param: String) {
        print("JS调用native.sample2, 参数: \(param)")
    }
    
    // 无参数，有返回值
    func sample3() -> String {
        print("JS调用native.sample3, 返回'native param'")
        return "native param"
    }
    
    // 有参数，有返回值
    func sample4(_ str1: String, _ str2: String) -> String {
        print("JS调用native.sample4")
        return str1 + str2
    }
    
    // int、float类型参数，有返回值
    func sample5(_ a: Int, _ b: Float, _ c: Double) -> String {
        print("JS调用native.sample5")
        return "\(a)+\(b)+\(c) is \(Double(a) + Double(b) + c)"
    }
    
    // 数组、字典类型参数，有返回值
    func sample6(_ array: [Any], _ dic: [String : Any]) -> String {
        print("JS调用native.sample6, 参数: array: \(array)\ndic: \(dic)")
        return "array.len = \(array.count), dic.len = \(dic.count)"
    }
    
    // 闭包类型参数，有返回值
    func sample7(_ callback: RJBCallback) -> String {
        print("JS调用native.sample7, 执行闭包")
        callback(["callback param"])
        return "return value"
    }
}
