//
//  LiteNetworkConfigureManager.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/2/28.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation


final class LiteNetworkConfigureManager {
    /// 配置类型
    enum ConfigureType {
        case Default
        case Ephemeral
        case Background(String)
    }
    
    private var configureType: ConfigureType = .Default
    /// 随请求发送的其它标头的字典
    private var httpAdditionalHeaders: [AnyHashable: Any] = [:]
    
    /// 是否全权委托
    private var isDiscretionary = false
    /// 在传输完成之后是否应该恢复或者在后台启动应用
    private var sessionSendsLaunchEvents = true
    
    /// 资源请求允许的超时间隔
    private var timeoutIntervalForResource: TimeInterval = 604_800
    /// 等待其他数据时允许的超时间隔
    private var timeoutIntervalForRequest: TimeInterval = 60
    
    private var httpShouldSetCookies = true
    private var httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.onlyFromMainDocumentDomain
    
    private var requestCachePolicy = NSURLRequest.CachePolicy.useProtocolCachePolicy
}


extension LiteNetworkConfigureManager {
    /// 获取新的session配置信息
    func getNewSessionConfigure() -> URLSessionConfiguration {
        let newConfigure: URLSessionConfiguration
        switch configureType {
        case .Default:
            newConfigure = URLSessionConfiguration.default
        case .Ephemeral:
            newConfigure = URLSessionConfiguration.ephemeral
        case .Background(let identifier):
            newConfigure = URLSessionConfiguration.background(withIdentifier: identifier)
            newConfigure.isDiscretionary = isDiscretionary
            #if !os(macOS)
            newConfigure.sessionSendsLaunchEvents = sessionSendsLaunchEvents
            #endif
        }
        
        newConfigure.httpAdditionalHeaders = httpAdditionalHeaders
        
        newConfigure.timeoutIntervalForResource = timeoutIntervalForResource
        newConfigure.timeoutIntervalForRequest = timeoutIntervalForRequest
        
        newConfigure.httpShouldSetCookies = httpShouldSetCookies
        newConfigure.httpCookieAcceptPolicy = httpCookieAcceptPolicy
        
        newConfigure.requestCachePolicy = requestCachePolicy

        return newConfigure
    }
    
    /// 更新配置类型
    /// - Parameter type: 目标类型
    func updateConfigureType(type: ConfigureType) {
        configureType = type
    }
    
    /// 添加随请求发送的其它标头的字典
    /// - Parameter dictionary: 要添加的标头字典
    func appendHttpAdditionalHeaders(dictionary: [AnyHashable: Any]) {
        let newDictionary = httpAdditionalHeaders.merging(dictionary, uniquingKeysWith: {
            _, new in
            new
        })
        httpAdditionalHeaders = newDictionary
    }
    
    /// 更新是否全权委托
    /// - Parameter new: Bool
    func updateIsDiscretionary(for new: Bool) {
        isDiscretionary = new
    }
    
    /// 更新资源请求允许的超时间隔
    /// - Parameter new: 目标时长
    func updateTimeoutIntervalForResource(for new: TimeInterval) {
        timeoutIntervalForResource = new
    }
    
    /// 更新等待其他数据时允许的超时间隔
    /// - Parameter new: 目标时长
    func updateTimeoutIntervalForRequest(for new: TimeInterval) {
        timeoutIntervalForRequest = new
    }
    
    /// 更新在传输完成之后是否应该恢复或者在后台启动应用
    /// - Parameter new: Bool
    func updateSessionSendsLaunchEvents(for new: Bool) {
        sessionSendsLaunchEvents = new
    }
    
    /// 更新是否请求应包含cookie存储中的cookie
    /// - Parameter new: Bool
    func updateHttpShouldSetCookies(for new: Bool) {
        httpShouldSetCookies = new
    }
    
    /// 更新请求缓存政策
    /// - Parameter new: 目标policy
    func updateRequestCachePolicy(for new: NSURLRequest.CachePolicy) {
        requestCachePolicy = new
    }
    
    /// 更新http cookie接受政策
    /// - Parameter new: 目标policy
    func updateHttpCookieAcceptPolicy(for new: HTTPCookie.AcceptPolicy) {
        httpCookieAcceptPolicy = new
    }
}

extension LiteNetworkConfigureManager.ConfigureType: CustomStringConvertible {
    var description: String {
        switch self {
        case .Default:
            return "默认配置类型"
        case .Ephemeral:
            return "ephemeral配置类型"
        case .Background(let identifier):
            return "background(\(identifier))配置类型"
        }
    }
}
