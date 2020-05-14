//
//  LiteNetworkStream.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/3/10.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

final class LiteNetworkStream: NSObject {
    typealias ProcessAuthenticationChallenge = (URLAuthenticationChallenge) -> (disposition: URLSession.AuthChallengeDisposition, credential: URLCredential?)
    typealias DataCommunicateComplteteHandler = (Data?, Error?) -> ()
    typealias NormalCompleteHandler = (Error?) -> ()
    typealias ReadDataCompleteHandler = (Data?, Bool, Error?) -> ()
    typealias StreamTaskCompleteHandler = (_ dueError: Bool, _ error: Error?) -> ()
    typealias StreamCloseCompleteHandler = (_ dueError: Bool) -> ()
    
    private var configureManager = LiteNetworkConfigureManager()
    
    private let sessionTaskDelegateQueue: OperationQueue
    
    private lazy var session = { () -> URLSession in
        let newConfiguration = self.configureManager.getNewSessionConfigure()
        return URLSession(configuration: newConfiguration, delegate: self, delegateQueue: self.sessionTaskDelegateQueue)
    }()
    
    private var streamTask: URLSessionStreamTask?
    
    private var streamToken = LiteNetworkStreamToken()
    
    private var sessionAuthentication: ProcessAuthenticationChallenge?
    private var taskAuthentication: ProcessAuthenticationChallenge?
    private var streamTaskComplete: StreamTaskCompleteHandler?
    private var streamReadCloseComplete: StreamCloseCompleteHandler?
    private var streamWriteCloseComplete: StreamCloseCompleteHandler?
    
    private var chainSourceBagsManager = LiteNetworkStreamChainSourceBagManager()
    
    private var hasError = false
    
    override init() {
        let opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = 1
        self.sessionTaskDelegateQueue = opQueue
        
        super.init()
        
        streamToken.setDelegate(delegate: self)
    }
    
}

extension LiteNetworkStream {
    /// 更新session级别鉴权处理
    /// - Parameter authentication: 鉴权处理闭包，返回处理方法常量和认证证书
    func updateSessionAuthentication(for authentication: @escaping ProcessAuthenticationChallenge) -> Self {
        sessionAuthentication = authentication
        return self
    }
    
    /// 更新task级别鉴权处理
    /// - Parameter authentication: 鉴权处理闭包，返回处理方法常量和认证证书
    func updateTaskAuthentication(for authentication: @escaping ProcessAuthenticationChallenge) -> Self {
        taskAuthentication = authentication
        return self
    }
    
    func updateStreamTaskComplete(for handler: @escaping StreamTaskCompleteHandler) -> Self {
        streamTaskComplete = handler
        return self
    }
    
    /// 通过给定的域名和端口建立流任务
    /// - Parameters:
    ///   - host: 域名
    ///   - port: 端口
    func makeStreamWith(host: String, port: Int) -> Self {
        streamTask = session.streamTask(withHostName: host, port: port)
        return self
    }
    
    /// 通过给定的network Service建立流任务
    /// - Parameter netSever: network service
    func makeStreamWith(netSever: NetService) -> Self {
        streamTask = session.streamTask(with: netSever)
        return self
    }
    
    /// 更新关闭读取流的操作
    /// - Parameter handler: 要进行的操作
    func updateStreamReadCloseComplete(handler: @escaping StreamCloseCompleteHandler) -> Self {
        streamReadCloseComplete = handler
        return self
    }
    
    /// 更新关闭写入流的操作
    /// - Parameter handler: 要进行的操作
    func updateStreamWriteCloseComplete(handler: @escaping StreamCloseCompleteHandler) -> Self {
        streamWriteCloseComplete = handler
        return self
    }
    
    /// 启用安全连接
    func startSecureConnect() -> LiteNetworkStreamToken {
        streamTask?.startSecureConnection()
        streamTask?.resume()
        
        return streamToken
    }
    
    /// 开始连接
    func startConnect() -> LiteNetworkStreamToken {
        streamTask?.resume()
        
        return streamToken
    }
    
    /// 链式资源包进行与服务器的会话操作
    /// - Parameter bag: 传入链式资源包
    private func simpleCommunicateWithSeverForSourceBag(for bag: LiteNetworkStreamChainSourceBag) {
        // 如果初始化失败，移除该资源包，判断数组中的下一个链式资源包
        guard let streamTask = streamTask, let operation = bag.communicateOperation else {
            chainSourceBagsManager.removeFirst()
            if let firstBag = chainSourceBagsManager.firstSourceBag() {
                executeChainSourceBag(for: firstBag)
            }
            return
        }
        streamTask.write(operation.input, timeout: operation.timeout, completionHandler: { [weak self] error in
            guard let `self` = self else {
                return
            }
            if let error = error { // 出现错误时关闭读写流，提前返回
                self.chainSourceBagsManager.removeAll()
                self.hasError = true
                streamTask.closeRead()
                streamTask.closeWrite()
                self.session.invalidateAndCancel() // 取消所有未完成task，然后使session无效
                self.streamTask = nil
                operation.completeHandler(nil, error)
                return
            }
            streamTask.readData(ofMinLength: operation.min, maxLength: operation.max, timeout: operation.timeout, completionHandler: {
                [weak self] data, eof, error in
                guard let `self` = self else {
                    return
                }
                if let error = error {
                    self.chainSourceBagsManager.removeAll()
                    self.hasError = true
                    streamTask.closeRead()
                    streamTask.closeWrite()
                    self.session.invalidateAndCancel()
                    self.streamTask = nil
                    operation.completeHandler(nil, error)
                    return
                }
                if let data = data {
                    operation.completeHandler(data, nil)
                    self.chainSourceBagsManager.removeFirst()
                    if let first = self.chainSourceBagsManager.firstSourceBag() {
                        self.executeChainSourceBag(for: first)
                    }
                } else {
                    self.chainSourceBagsManager.removeAll()
                    self.hasError = true
                    streamTask.closeRead()
                    streamTask.closeWrite()
                    self.session.invalidateAndCancel()
                    self.streamTask = nil
                    operation.completeHandler(nil, LiteNetworkError.NoDataReadFormStream)
                }
            })
        })
    }
    
    /// 链式资源包进行写入操作
    /// - Parameter bag: 传入链式资源包
    private func writeDataForSourceBag(for bag: LiteNetworkStreamChainSourceBag) {
        guard let streamTask = streamTask, let operation = bag.writeOperation else {
            chainSourceBagsManager.removeFirst()
            if let firstBag = chainSourceBagsManager.firstSourceBag() {
                executeChainSourceBag(for: firstBag)
            }
            return
        }
        streamTask.write(operation.input, timeout: operation.timout, completionHandler: {
            [weak self] error in
            guard let `self` = self else {
                return
            }
            if let error = error {
                self.chainSourceBagsManager.removeAll()
                self.hasError = true
                streamTask.closeRead()
                streamTask.closeWrite()
                self.session.invalidateAndCancel()
                self.streamTask = nil
                operation.completeHandler(error)
                return
            }
            operation.completeHandler(nil)
            self.chainSourceBagsManager.removeFirst()
            if let first = self.chainSourceBagsManager.firstSourceBag() {
                self.executeChainSourceBag(for: first)
            }
        })
    }
    
    /// 链式资源包进行读取操作
    /// - Parameter bag: 传入链式资源包
    private func readDataForSourceBag(for bag: LiteNetworkStreamChainSourceBag) {
        guard let streamTask = streamTask, let operation = bag.readOperation else {
            chainSourceBagsManager.removeFirst()
            if let firstBag = chainSourceBagsManager.firstSourceBag() {
                executeChainSourceBag(for: firstBag)
            }
            return
        }
        streamTask.readData(ofMinLength: operation.min, maxLength: operation.max, timeout: operation.timeout, completionHandler: {
            [weak self] data, eof, error in
            guard let `self` = self else {
                return
            }
            if let error = error {
                self.chainSourceBagsManager.removeAll()
                self.hasError = true
                streamTask.closeRead()
                streamTask.closeWrite()
                self.session.invalidateAndCancel()
                self.streamTask = nil
                operation.completeHandler(nil, eof, error)
                return
            }
            if let data = data {
                operation.completeHandler(data, eof, nil)
                self.chainSourceBagsManager.removeFirst()
                if let first = self.chainSourceBagsManager.firstSourceBag() {
                    self.executeChainSourceBag(for: first)
                }
            } else {
                self.chainSourceBagsManager.removeAll()
                self.hasError = true
                streamTask.closeRead()
                streamTask.closeWrite()
                self.session.invalidateAndCancel()
                self.streamTask = nil
                operation.completeHandler(nil, eof, LiteNetworkError.NoDataReadFormStream)
                return
            }
            
        })
    }
    
    /// 关闭链式资源包的读操作
    private func closeReadForSourceBag() {
        guard let streamTask = streamTask else {
            chainSourceBagsManager.removeFirst()
            if let firstBag = chainSourceBagsManager.firstSourceBag() {
                executeChainSourceBag(for: firstBag)
            }
            return
        }
        streamTask.closeRead()
        self.chainSourceBagsManager.removeFirst()
        if let first = self.chainSourceBagsManager.firstSourceBag() {
            self.executeChainSourceBag(for: first)
        }
    }
    
    /// 关闭链式资源包的写操作
    private func closeWriteForSourceBag() {
        guard let streamTask = streamTask else {
            chainSourceBagsManager.removeFirst()
            if let firstBag = chainSourceBagsManager.firstSourceBag() {
                executeChainSourceBag(for: firstBag)
            }
            return
        }
        streamTask.closeWrite()
        self.chainSourceBagsManager.removeFirst()
        if let first = self.chainSourceBagsManager.firstSourceBag() {
            self.executeChainSourceBag(for: first)
        }
    }
    
    /// 判断链式资源包的操作类型，执行对应的操作
    /// - Parameter bag: 要判断的链式资源包
    private func executeChainSourceBag(for bag: LiteNetworkStreamChainSourceBag) {
        if !self.hasError {
            self.chainSourceBagsManager.removeAll()
            return
        }
        switch bag.type {
        case .Communicate:
            simpleCommunicateWithSeverForSourceBag(for: bag)
        case .Write:
            writeDataForSourceBag(for: bag)
        case .Read:
            readDataForSourceBag(for: bag)
        case .CloseWrite:
            closeWriteForSourceBag()
        case .CloseRead:
            closeReadForSourceBag()
        }
    }
}


extension LiteNetworkStream {
    /// 设置默认初始化配置
    func setDefaultConfigureType() -> Self {
        configureManager.updateConfigureType(type: .Default)
        return self
    }
    
    /// 设置ephemeral初始化配置
    func setEphemeralConfigureType() -> Self {
        configureManager.updateConfigureType(type: .Ephemeral)
        return self
    }
    
    func appendHttpAdditionalHeaders(dictionary: [AnyHashable: Any]) -> Self {
        configureManager.appendHttpAdditionalHeaders(dictionary: dictionary)
        return self
    }
    
    func setIsDiscretionary(for new: Bool) -> Self {
        configureManager.updateIsDiscretionary(for: new)
        return self
    }
    
    /// 设置资源请求的允许超时间隔
    /// - Parameter new: 目标时长
    func setTimeoutIntervalForResource(for new: TimeInterval) -> Self {
        configureManager.updateTimeoutIntervalForResource(for: new)
        return self
    }
    
    /// 设置等待其他数据时的允许超时间隔
    /// - Parameter new: 目标时长
    func setTimeoutIntervalForRequest(for new: TimeInterval) -> Self {
        configureManager.updateTimeoutIntervalForRequest(for: new)
        return self
    }
    
    /// 设置传输完成之后是否应该恢复或者在后台启动应用
    /// - Parameter new: Bool
    func setSessionSendsLaunchEvents(for new: Bool) -> Self {
        configureManager.updateSessionSendsLaunchEvents(for: new)
        return self
    }
    
    /// 设置是否请求应包含cookie存储中的cookie
    /// - Parameter new: bool
    func setHttpShouldSetCookies(for new: Bool) -> Self {
        configureManager.updateHttpShouldSetCookies(for: new)
        return self
    }
    
    func setRequestCachePolicy(for new: NSURLRequest.CachePolicy) -> Self {
        configureManager.updateRequestCachePolicy(for: new)
        return self
    }
    
    func setHttpCookieAcceptPolicy(for new: HTTPCookie.AcceptPolicy) -> Self {
        configureManager.updateHttpCookieAcceptPolicy(for: new)
        return self
    }
}

extension LiteNetworkStream: URLSessionDelegate {
    /// session级别的鉴权处理
    /// - Parameters:
    ///   - session: 要进行身份认证的session
    ///   - challenge: 包含认证请求的对象
    ///   - completionHandler: 回调处理
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let authentication = sessionAuthentication else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        let authenticationChallenge = authentication(challenge)
        completionHandler(authenticationChallenge.disposition, authenticationChallenge.credential)
    }
}

extension LiteNetworkStream: URLSessionTaskDelegate {
    /// task级别的鉴权处理
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let authentication = taskAuthentication else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        let authenticationChallenge = authentication(challenge)
        completionHandler(authenticationChallenge.disposition, authenticationChallenge.credential)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let handler = self.streamTaskComplete else {
            return
        }
        handler(self.hasError, error)
    }
    
}

extension LiteNetworkStream: URLSessionStreamDelegate {
    func urlSession(_ session: URLSession, readClosedFor streamTask: URLSessionStreamTask) {
        guard let handler = self.streamReadCloseComplete else {
            return
        }
        handler(self.hasError)
    }
    
    func urlSession(_ session: URLSession, writeClosedFor streamTask: URLSessionStreamTask) {
        guard let handler = self.streamWriteCloseComplete else {
            return
        }
        handler(self.hasError)
    }
    
}

extension LiteNetworkStream: LiteNetworkStreamTokenDelegate {
    func cancelSessionRightWay() {
        chainSourceBagsManager.removeAll()
        streamTask?.closeRead()
        streamTask?.closeWrite()
        session.invalidateAndCancel()
        streamTask = nil
    }
    
    func cancelSessionFinishCurrentTask() {
        chainSourceBagsManager.removeAll()
        streamTask?.closeRead()
        streamTask?.closeWrite()
        session.finishTasksAndInvalidate()
        streamTask = nil
    }
    
    func simpleCommunicateWithSever(input: Data, minLength: Int = 1, maxLength: Int = 2048, timeout: TimeInterval? = nil, completionHandler: @escaping DataCommunicateComplteteHandler) {
        let timeout = timeout ?? session.configuration.timeoutIntervalForRequest
        let sourceBag = LiteNetworkStreamChainSourceBag(communicateData: input, minLength: minLength, maxLength: maxLength, timeout: timeout, completeHandler: completionHandler)
        if chainSourceBagsManager.isEmpty() {
            chainSourceBagsManager.append(sourceBag: sourceBag)
            executeChainSourceBag(for: sourceBag)
        } else {
            chainSourceBagsManager.append(sourceBag: sourceBag)
        }
    }
    
    func writeData(input: Data, timeout: TimeInterval? = nil, completionHandler: @escaping NormalCompleteHandler) {
        let timeout = timeout ?? session.configuration.timeoutIntervalForRequest
        let sourceBag = LiteNetworkStreamChainSourceBag(writeData: input, timeout: timeout, completeHandler: completionHandler)
        if chainSourceBagsManager.isEmpty() {
            chainSourceBagsManager.append(sourceBag: sourceBag)
            executeChainSourceBag(for: sourceBag)
        } else {
            chainSourceBagsManager.append(sourceBag: sourceBag)
        }
    }
    
    func readData(minLength: Int = 1, maxLength: Int = 2048, timeout: TimeInterval? = nil, completeHandler: @escaping ReadDataCompleteHandler) {
        let timeout = timeout ?? session.configuration.timeoutIntervalForRequest
        let sourceBag = LiteNetworkStreamChainSourceBag(readMinLength: minLength, maxLength: maxLength, timeout: timeout, completeHandler: completeHandler)
        if chainSourceBagsManager.isEmpty() {
            chainSourceBagsManager.append(sourceBag: sourceBag)
            executeChainSourceBag(for: sourceBag)
        } else {
            chainSourceBagsManager.append(sourceBag: sourceBag)
        }
    }
    
    func closeWriteStream() {
        let sourceBag = LiteNetworkStreamChainSourceBag.closeWriteSourceBag
        if chainSourceBagsManager.isEmpty() {
            chainSourceBagsManager.append(sourceBag: sourceBag)
            executeChainSourceBag(for: sourceBag)
        } else {
            chainSourceBagsManager.append(sourceBag: sourceBag)
        }
    }
    
    func closeReadStream() {
        let sourceBag = LiteNetworkStreamChainSourceBag.closeReadSourceBag
        if chainSourceBagsManager.isEmpty() {
            chainSourceBagsManager.append(sourceBag: sourceBag)
            executeChainSourceBag(for: sourceBag)
        } else {
            chainSourceBagsManager.append(sourceBag: sourceBag)
        }
    }
}
