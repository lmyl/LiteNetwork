//
//  LiteNetworkStream.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/3/10.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

public final class LiteNetworkStream {
    public typealias ProcessAuthenticationChallenge = (URLAuthenticationChallenge) -> (disposition: URLSession.AuthChallengeDisposition, credential: URLCredential?)
    public typealias DataCommunicateComplteteHandler = (Data?, Error?) -> Bool
    public typealias WriteDataCompleteHandler = (Error?) -> Bool
    public typealias ReadDataCompleteHandler = (Data?, Bool, Error?) -> Bool
    public typealias StreamTaskCompleteHandler = (_ error: Error?) -> ()
    public typealias StreamCloseCompleteHandler = () -> ()
    
    private var liteNetworkStreamWorker = LiteNetworkStreamWorker()
    
    public init() { }
}

public extension LiteNetworkStream {
    /// Update the session-wide authentication processing
    /// - Parameter authentication:
    ///  a closure that takes a `URLAuthenticationChallenge` parameter, and return disposition and credential
    ///  to deal with the authentication challenge
    /// - Returns: `Self`
    func updateSessionAuthentication(for authentication: @escaping ProcessAuthenticationChallenge) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.updateSessionAuthentication(for: authentication)
        return self
    }
    
    /// Update the task-specific authentication processing
    /// - Parameter authentication:
    ///  a closure that takes a `URLAuthenticationChallenge` parameter, and return disposition and credential
    ///  to deal with the authentication challenge
    func updateTaskAuthentication(for authentication: @escaping ProcessAuthenticationChallenge) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.updateTaskAuthentication(for: authentication)
        return self
    }
    
    /// Update the completion handler of the stream task
    /// - Parameter handler: A handler that will be called when your stream task completed
    /// - Returns: `Self`
    func updateStreamTaskComplete(for handler: @escaping StreamTaskCompleteHandler) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.updateStreamTaskComplete(for: handler)
        return self
    }
    
    /// Create a stream task with given host and port
    /// - Parameters:
    ///   - host: `String`
    ///   - port: `Int`
    func makeStreamWith(host: String, port: Int) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.makeStreamWith(host: host, port: port)
        return self
    }
    
    /// Create a stream task with a given network service
    /// - Parameter netSever: network service
    func makeStreamWith(netSever: NetService) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.makeStreamWith(netSever: netSever)
        return self
    }
    
    /// Update completion handler of closing read stream
    /// - Parameter handler: A hander that will be called when your stream task's read closed
    func updateStreamReadCloseComplete(handler: @escaping StreamCloseCompleteHandler) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.updateStreamReadCloseComplete(handler: handler)
        return self
    }
    
    /// Update completion handler of closing write stream
    /// - Parameter handler: A hander that will be called when your stream task's write closed
    func updateStreamWriteCloseComplete(handler: @escaping StreamCloseCompleteHandler) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.updateStreamWriteCloseComplete(handler: handler)
        return self
    }
    
    /// trigger the chain sourceBag with secure connect
    func startSecureConnect() -> LiteNetworkStreamToken {
        self.liteNetworkStreamWorker.startSecureConnect()
    }
    
    /// trigger chain sourceBag withe normal connect
    func startConnect() -> LiteNetworkStreamToken {
        self.liteNetworkStreamWorker.startConnect()
    }
    
}


public extension LiteNetworkStream {
    /// Set `Defaule` initial configuration type
    func setDefaultConfigureType() -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.setDefaultConfigureType()
        return self
    }
    
    /// Set `Ephmeral` initial configyration type
    func setEphemeralConfigureType() -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.setEphemeralConfigureType()
        return self
    }
    
    /// Append dictionary of other headers that send with request
    func appendHttpAdditionalHeaders(dictionary: [AnyHashable: Any]) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.appendHttpAdditionalHeaders(dictionary: dictionary)
        return self
    }
    
    /// Set allowable timeout interval for chain sourceBag
    /// - Parameter new: target time interval
    func setTimeoutIntervalForResource(for new: TimeInterval) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.setTimeoutIntervalForResource(for: new)
        return self
    }
    
    /// Set allowable timeout interval while waiting for request
    /// - Parameter new: target time interval
    func setTimeoutIntervalForRequest(for new: TimeInterval) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.setTimeoutIntervalForRequest(for: new)
        return self
    }
    
    /// Set whether the request should include cookie
    /// - Parameter new: bool
    func setHttpShouldSetCookies(for new: Bool) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.setHttpShouldSetCookies(for: new)
        return self
    }
    
    /// Set the policy that determines when to return a response from the cache
    func setRequestCachePolicy(for new: NSURLRequest.CachePolicy) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.setRequestCachePolicy(for: new)
        return self
    }
    
    /// Set the policy that determines when cookies should be accepted
    func setHttpCookieAcceptPolicy(for new: HTTPCookie.AcceptPolicy) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.setHttpCookieAcceptPolicy(for: new)
        return self
    }
}




