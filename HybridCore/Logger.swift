//
//  Logger.swift
//  Hybrid
//
//  Created by jilei on 2016/12/27.
//  Copyright © 2016年 jilei. All rights reserved.
//

import UIKit

internal class Logger: NSObject {
    enum LoggerLevel: Int {
        case Verbose = 0
        case Warning = 1
        case Error = 2
    }
    
    public static var level: LoggerLevel = .Warning
    
    public class func LogVerbose(_ log: String) {
        if LogLevel.rawValue <= LoggerLevel.Verbose.rawValue {
            printLog(level: .Verbose, log: log)
        }
    }
    
    public class func LogWarning(_ log: String) {
        if LogLevel.rawValue <= LoggerLevel.Warning.rawValue {
            printLog(level: .Warning, log: log)
        }
    }
    
    public class func LogError(_ log: String) {
        if LogLevel.rawValue <= LoggerLevel.Error.rawValue {
            printLog(level: .Error, log: log)
        }
    }
    
    // MARK: - Private
    
    private class func printLog(level: LoggerLevel, log: String) {
        let levelNames = ["Verbose", "Warning", "Error"]
        print("[\(levelNames[level.rawValue])]: \(log)")
    }
}

// MARK: - Shortcut

internal var LogLevel: Logger.LoggerLevel {
    set(newValue) {
        Logger.level = newValue
    }
    get {
        return Logger.level
    }
}

internal func LogVerbose(_ log: String) {
    Logger.LogVerbose(log)
}

internal func LogWarning(_ log: String) {
    Logger.LogWarning(log)
}

internal func LogError(_ log: String) {
    Logger.LogError(log)
}
