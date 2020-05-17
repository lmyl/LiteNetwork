//
//  LiteNetworkConfigureManager.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/2/28.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation


final class LiteNetworkConfigureManager {
    /// Defines the type of session configuration
    enum ConfigureType {
        case Default
        case Ephemeral
        case Background(String)
    }
    
    private var configureType: ConfigureType = .Default
    /// Dictionary of other headers that send with request.
    private var httpAdditionalHeaders: [AnyHashable: Any] = [:]
    
    /// A Boolean value that determines whether background tasks can be scheduled at the discretion of the system for optimal performance.
    private var isDiscretionary = false
    /// A Boolean value that indicates whether the app should be resumed or launched in the background when transfers finish.
    private var sessionSendsLaunchEvents = true
    
    /// Allowed timeout interval for resource
    private var timeoutIntervalForResource: TimeInterval = 604_800
    /// Allowed timeout interval when waiting for request
    private var timeoutIntervalForRequest: TimeInterval = 60
    
    /// A Boolean value that determines whether requests should contain cookies from the cookie store.
    private var httpShouldSetCookies = true
    /// A policy constant that determines when cookies should be accepted.
    private var httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.onlyFromMainDocumentDomain
    
    /// A predefined constant that determines when to return a response from the cache.
    private var requestCachePolicy = NSURLRequest.CachePolicy.useProtocolCachePolicy
}


extension LiteNetworkConfigureManager {
    /// get newest session configuration
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
    
    /// Update the type of configuration
    /// - Parameter type: Target type
    func updateConfigureType(type: ConfigureType) {
        configureType = type
    }
    
    /// Append dictionary of other headers that send with request
    /// - Parameter dictionary: The `Dictionary` needed to be added
    func appendHttpAdditionalHeaders(dictionary: [AnyHashable: Any]) {
        let newDictionary = httpAdditionalHeaders.merging(dictionary, uniquingKeysWith: {
            _, new in
            new
        })
        httpAdditionalHeaders = newDictionary
    }
    
    /// Update `isDiscretinary` attribute
    /// - Parameter new: Bool
    func updateIsDiscretionary(for new: Bool) {
        isDiscretionary = new
    }
    
    /// Update `timeoutIntervalForResource` attribute
    /// - Parameter new: target time interval
    func updateTimeoutIntervalForResource(for new: TimeInterval) {
        timeoutIntervalForResource = new
    }
    
    /// Update `timeoutIntervalForRequest` attribute
    /// - Parameter new: target time interval
    func updateTimeoutIntervalForRequest(for new: TimeInterval) {
        timeoutIntervalForRequest = new
    }
    
    /// Update whether the app should be resumed or launched in the background when transfers finish
    /// - Parameter new: Boolean
    func updateSessionSendsLaunchEvents(for new: Bool) {
        sessionSendsLaunchEvents = new
    }
    
    /// Update whether requests should contain cookies from the cookie store
    /// - Parameter new: Boolean
    func updateHttpShouldSetCookies(for new: Bool) {
        httpShouldSetCookies = new
    }
    
    /// Update the policy that determines when to return a response from the cache
    /// - Parameter new: new policy
    func updateRequestCachePolicy(for new: NSURLRequest.CachePolicy) {
        requestCachePolicy = new
    }
    
    /// Update the policy that determines when cookies should be accepted
    /// - Parameter new: new policy
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
