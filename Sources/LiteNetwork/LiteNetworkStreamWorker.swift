//
//  File.swift
//  
//
//  Created by huangxiaohui on 2020/5/15.
//

import Foundation

final class LiteNetworkStreamWorker: NSObject {
    
    private var configureManager = LiteNetworkConfigureManager()
    
    private let sessionTaskDelegateQueue: OperationQueue
    
    private lazy var session = { () -> URLSession in
        let newConfiguration = self.configureManager.getNewSessionConfigure()
        return URLSession(configuration: newConfiguration, delegate: self, delegateQueue: self.sessionTaskDelegateQueue)
    }()
    
    private var streamTask: URLSessionStreamTask?
    
    private var streamToken = LiteNetworkStreamToken()
    
    private var sessionAuthentication: LiteNetworkStream.ProcessAuthenticationChallenge?
    private var taskAuthentication: LiteNetworkStream.ProcessAuthenticationChallenge?
    private var streamTaskComplete: LiteNetworkStream.StreamTaskCompleteHandler?
    private var streamReadCloseComplete: LiteNetworkStream.StreamCloseCompleteHandler?
    private var streamWriteCloseComplete: LiteNetworkStream.StreamCloseCompleteHandler?
    
    private var chainSourceBagsManager = LiteNetworkStreamChainSourceBagManager()
    
    private var hasError: Bool {
        get {
            var result = false
            self.errorFlagRWQueue.sync {
                [unowned self] in
                result = self.underlayHasError
            }
            return result
        }
        set(newValue) {
            self.errorFlagRWQueue.async(flags: .barrier, execute: {
                [unowned self] in
                self.underlayHasError = newValue
            })
        }
    }
    
    private var errorFlagRWQueue = DispatchQueue(label: "LiteNetworkStream.rwHasError.token.com", attributes: .concurrent)
    
    private var underlayHasError = false
    
    override init() {
        let opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = 1
        self.sessionTaskDelegateQueue = opQueue
        
        super.init()
        
        streamToken.setDelegate(delegate: self)
    }
}

extension LiteNetworkStreamWorker {
    /// Update the session-wide authentication processing
    func updateSessionAuthentication(for authentication: @escaping LiteNetworkStream.ProcessAuthenticationChallenge) -> Self {
        sessionAuthentication = authentication
        return self
    }
    
    /// Update the task-specific authentication processing
    func updateTaskAuthentication(for authentication: @escaping LiteNetworkStream.ProcessAuthenticationChallenge) -> Self {
        taskAuthentication = authentication
        return self
    }
    
    func updateStreamTaskComplete(for handler: @escaping LiteNetworkStream.StreamTaskCompleteHandler) -> Self {
        streamTaskComplete = handler
        return self
    }
    
    /// Create a stream task with a given host and port
    func makeStreamWith(host: String, port: Int) -> Self {
        streamTask = session.streamTask(withHostName: host, port: port)
        return self
    }
    
    /// Create a stream task with a given network service
    func makeStreamWith(netSever: NetService) -> Self {
        streamTask = session.streamTask(with: netSever)
        return self
    }
    
    /// Update completion handler of closing read stream
    func updateStreamReadCloseComplete(handler: @escaping LiteNetworkStream.StreamCloseCompleteHandler) -> Self {
        streamReadCloseComplete = handler
        return self
    }
    
    /// Update completion handler of closing write stream
    func updateStreamWriteCloseComplete(handler: @escaping LiteNetworkStream.StreamCloseCompleteHandler) -> Self {
        streamWriteCloseComplete = handler
        return self
    }
    
    /// trigger task withe secure connect
    func startSecureConnect() -> LiteNetworkStreamToken {
        streamTask?.startSecureConnection()
        streamTask?.resume()
        
        return streamToken
    }
    
    /// trigger task
    func startConnect() -> LiteNetworkStreamToken {
        streamTask?.resume()
        
        return streamToken
    }
    
    /// simple communication with server
    /// - Parameter bag: instance of chain sourceBag
    private func simpleCommunicateWithSeverForSourceBag(for bag: LiteNetworkStreamChainSourceBag) {
        // If the initialization fails, remove current chain sourceBag and judge the next in the arrangement
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
            if let error = error { // Close the read and write stream when an error occurs and return directly
                self.hasError = true
                operation.completeHandler(nil, error)
                self.chainSourceBagsManager.removeAll()
                streamTask.closeRead()
                streamTask.closeWrite()
                self.session.invalidateAndCancel() // Cancel all tasks and invalidate the session
                self.streamTask = nil
                return
            }
            streamTask.readData(ofMinLength: operation.min, maxLength: operation.max, timeout: operation.timeout, completionHandler: {
                [weak self] data, eof, error in
                guard let `self` = self else {
                    return
                }
                if let error = error {
                    self.hasError = true
                    operation.completeHandler(nil, error)
                    self.chainSourceBagsManager.removeAll()
                    streamTask.closeRead()
                    streamTask.closeWrite()
                    self.session.invalidateAndCancel()
                    self.streamTask = nil
                    return
                }
                if let data = data {
                    operation.completeHandler(data, nil)
                    self.chainSourceBagsManager.removeFirst()
                    if let first = self.chainSourceBagsManager.firstSourceBag() {
                        self.executeChainSourceBag(for: first)
                    }
                } else {
                    self.hasError = true
                    operation.completeHandler(nil, LiteNetworkError.NoDataReadFormStream)
                    self.chainSourceBagsManager.removeAll()
                    streamTask.closeRead()
                    streamTask.closeWrite()
                    self.session.invalidateAndCancel()
                    self.streamTask = nil
                }
            })
        })
    }
    
    /// Write data operation of the chain sourceBag
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
                self.hasError = true
                operation.completeHandler(error)
                self.chainSourceBagsManager.removeAll()
                streamTask.closeRead()
                streamTask.closeWrite()
                self.session.invalidateAndCancel()
                self.streamTask = nil
                return
            }
            operation.completeHandler(nil)
            self.chainSourceBagsManager.removeFirst()
            if let first = self.chainSourceBagsManager.firstSourceBag() {
                self.executeChainSourceBag(for: first)
            }
        })
    }
    
    /// Read data operation of the chain sourceBag
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
                self.hasError = true
                operation.completeHandler(nil, eof, error)
                self.chainSourceBagsManager.removeAll()
                streamTask.closeRead()
                streamTask.closeWrite()
                self.session.invalidateAndCancel()
                self.streamTask = nil
                return
            }
            if let data = data {
                operation.completeHandler(data, eof, nil)
                self.chainSourceBagsManager.removeFirst()
                if let first = self.chainSourceBagsManager.firstSourceBag() {
                    self.executeChainSourceBag(for: first)
                }
            } else {
                self.hasError = true
                operation.completeHandler(nil, eof, LiteNetworkError.NoDataReadFormStream)
                self.chainSourceBagsManager.removeAll()
                streamTask.closeRead()
                streamTask.closeWrite()
                self.session.invalidateAndCancel()
                self.streamTask = nil
                return
            }
            
        })
    }
    
    /// Close the read operation of the chain souceBag
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
    
    /// Close the write operation of the chain sourceBag
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
    
    /// Determine the operation type of the chain sourceBag and perfrom the coresponding operation
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

extension LiteNetworkStreamWorker {
    /// Set `Default` initial configuration
    func setDefaultConfigureType() -> Self {
        configureManager.updateConfigureType(type: .Default)
        return self
    }
    
    /// Set `Ephemeral` initial configuration
    func setEphemeralConfigureType() -> Self {
        configureManager.updateConfigureType(type: .Ephemeral)
        return self
    }
    
    func appendHttpAdditionalHeaders(dictionary: [AnyHashable: Any]) -> Self {
        configureManager.appendHttpAdditionalHeaders(dictionary: dictionary)
        return self
    }
    
    /// Set allowable timeout interval for chain sourceBag
    /// - Parameter new: Target time interval
    func setTimeoutIntervalForResource(for new: TimeInterval) -> Self {
        configureManager.updateTimeoutIntervalForResource(for: new)
        return self
    }
    
    /// Set allowable timeout interval while waiting for request
    /// - Parameter new: Target time interval
    func setTimeoutIntervalForRequest(for new: TimeInterval) -> Self {
        configureManager.updateTimeoutIntervalForRequest(for: new)
        return self
    }
    
    /// Set whether the request should include cookie
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

extension LiteNetworkStreamWorker: URLSessionDelegate {
    
    /// Requests credentials from the delegate in response to a session-level authentication request from the remote server.
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let authentication = sessionAuthentication else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        let authenticationChallenge = authentication(challenge)
        completionHandler(authenticationChallenge.disposition, authenticationChallenge.credential)
    }
}

extension LiteNetworkStreamWorker: URLSessionTaskDelegate {
    /// Requests credentials from the delegate in response to an authentication request from the remote server.
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

extension LiteNetworkStreamWorker: URLSessionStreamDelegate {
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

extension LiteNetworkStreamWorker: LiteNetworkStreamTokenDelegate {
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
    
    func simpleCommunicateWithSever(input: Data, minLength: Int = 1, maxLength: Int = 2048, timeout: TimeInterval? = nil, completionHandler: @escaping LiteNetworkStream.DataCommunicateComplteteHandler) {
        let timeout = timeout ?? session.configuration.timeoutIntervalForRequest
        let sourceBag = LiteNetworkStreamChainSourceBag(communicateData: input, minLength: minLength, maxLength: maxLength, timeout: timeout, completeHandler: completionHandler)
        if chainSourceBagsManager.isEmpty() {
            chainSourceBagsManager.append(sourceBag: sourceBag)
            executeChainSourceBag(for: sourceBag)
        } else {
            chainSourceBagsManager.append(sourceBag: sourceBag)
        }
    }
    
    func writeData(input: Data, timeout: TimeInterval? = nil, completionHandler: @escaping LiteNetworkStream.WriteDataCompleteHandler) {
        let timeout = timeout ?? session.configuration.timeoutIntervalForRequest
        let sourceBag = LiteNetworkStreamChainSourceBag(writeData: input, timeout: timeout, completeHandler: completionHandler)
        if chainSourceBagsManager.isEmpty() {
            chainSourceBagsManager.append(sourceBag: sourceBag)
            executeChainSourceBag(for: sourceBag)
        } else {
            chainSourceBagsManager.append(sourceBag: sourceBag)
        }
    }
    
    func readData(minLength: Int = 1, maxLength: Int = 2048, timeout: TimeInterval? = nil, completeHandler: @escaping LiteNetworkStream.ReadDataCompleteHandler) {
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
