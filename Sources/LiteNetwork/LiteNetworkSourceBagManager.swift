//
//  LiteNetworkSourceBagManager.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/2/27.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

final class LiteNetworkSourceBagManager {
    private var sourceBags: [LiteNetworkSourceBag] = []
    
    private var globeRedirect: LiteNetwork.MakeRedirect?
    
    private var globeProcessError: LiteNetwork.ProcessError?
    
    private(set) var sessionAuthenticationChallenge: LiteNetwork.ProcessAuthenticationChallenge?
    
    private var globeRetryCount: Int?
    
    private let rwQueue = DispatchQueue(label: "LiteNetworkSourceBagManager.token.com", attributes: .concurrent)
}


extension LiteNetworkSourceBagManager {
    
    /// 读取资源包
    /// - Returns: 资源包的结构体数组
    func readSourceBags() -> [LiteNetworkSourceBag] {
        var sourceBags: [LiteNetworkSourceBag] = []
        rwQueue.sync(execute: {
            [unowned self] in
            sourceBags = self.sourceBags
        })
        return sourceBags
    }
    
    func writeSourceBag(sourceBags: [LiteNetworkSourceBag]) {
        rwQueue.async(flags: .barrier, execute: {
            [unowned self] in
            self.sourceBags = sourceBags
        })
    }
    
    /// 添加新的资源包到结构体数组中
    /// - Parameter sourceBag: 资源包
    func push(new sourceBag: LiteNetworkSourceBag) {
        var newSourceBag = sourceBag
        var sourceBags = readSourceBags()
        newSourceBag.sourceBagIdentifier = sourceBags.count
        sourceBags.append(newSourceBag)
        writeSourceBag(sourceBags: sourceBags)
    }
    
    /// 资源包数组是否为空
    func isEmpty() -> Bool {
        return readSourceBags().count == 0
    }
    
    /// 获得最后一个资源包（最新添加的）
    func getTrailSourceBag() -> LiteNetworkSourceBag? {
        return readSourceBags().last
    }
    
    /// 更新最后一个资源包
    /// - Parameter sourceBag: 用于更新的资源包
    func setTrailSourceBag(for sourceBag: LiteNetworkSourceBag) {
        guard !isEmpty() else {
            return
        }
        var sourceBags = readSourceBags()
        let lastIndex = sourceBags.endIndex
        sourceBags[lastIndex - 1] = sourceBag
        writeSourceBag(sourceBags: sourceBags)
    }
    
    /// 获取特定taskID的资源包
    /// - Parameter taskID: 要获取资源包的taskID
    func getSourceBag(for taskID: Int) -> LiteNetworkSourceBag? {
        let sourceBags = readSourceBags()
        for sourceBag in sourceBags {
            if sourceBag.requestTaskID == taskID {
                return sourceBag
            }
        }
        return nil
    }
    
    /// 更新特定taskID的资源包
    /// - Parameters:
    ///   - sourceBag: 用于更新的资源包
    ///   - taskID: 要更新的资源包的taskID
    func setSourceBag(new sourceBag: LiteNetworkSourceBag, for taskID: Int) {
        var targetIndex: Int?
        var sourceBags = readSourceBags()
        for (index, old) in sourceBags.enumerated() {
            if old.requestTaskID == taskID {
                targetIndex = index
                break
            }
        }
        guard let target = targetIndex else {
            return
        }
        sourceBags[target] = sourceBag
        writeSourceBag(sourceBags: sourceBags)
    }
    
    /// 更新特定ID的资源包
    /// - Parameters:
    ///   - sourceBag: 用于更新的资源包
    ///   - sourceBagIdentifier: 需要更新资源包的ID
    func setSourceBag(new sourceBag: LiteNetworkSourceBag, sourceBagIdentifier: Int) {
        var targetIndex: Int?
        var sourceBags = readSourceBags()
        for (index, old) in sourceBags.enumerated() {
            if old.sourceBagIdentifier == sourceBagIdentifier {
                targetIndex = index
                break
            }
        }
        guard let target = targetIndex else {
            return
        }
        sourceBags[target] = sourceBag
        writeSourceBag(sourceBags: sourceBags)
    }
    
    /// 移除指定taskID的资源包
    /// - Parameter taskID: 指定taskID
    func removeSourceBag(for taskID: Int) {
        var targetIndex: Int?
        var sourceBags = readSourceBags()
        for (index, sourceBag) in sourceBags.enumerated() {
            if sourceBag.requestTaskID == taskID {
                targetIndex = index
                break
            }
        }
        guard let target = targetIndex else {
            return
        }
        sourceBags.remove(at: target)
        writeSourceBag(sourceBags: sourceBags)
    }
    
    /// 移除现有的所有资源包
    func removeAllSourceBag() {
        var sourceBags = readSourceBags()
        sourceBags.removeAll()
        writeSourceBag(sourceBags: sourceBags)
    }
    
    /// 移除指定ID的资源包
    /// - Parameter id: 指定资源包ID
    func removeSourceBagForIdentifier(id: Int) {
        var targetIndex: Int?
        var sourceBags = readSourceBags()
        for (index, sourceBag) in sourceBags.enumerated() {
            if sourceBag.sourceBagIdentifier == id {
                targetIndex = index
                break
            }
        }
        guard let target = targetIndex else {
            return
        }
        sourceBags.remove(at: target)
        writeSourceBag(sourceBags: sourceBags)
    }
    
    /// 为末尾的资源包添加处理数据
    /// - Parameter processData: (URLResponse, Data) -> ()
    func appendDataProcessToTrail(new processData: @escaping LiteNetwork.ProcessData) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.processData.append(processData)
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// 为末尾的资源包添加处理成功请求
    /// - Parameter processRequestSuccess: (URLResponse) -> ()
    func appendProcessRequestSuccessToTrail(new processRequestSuccess: @escaping LiteNetwork.ProcessRequestSuccess) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.processRequestSuccess.append(processRequestSuccess)
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// 更新末尾资源包的重定向数据
    func updateRedirectToTrail(for redirect: @escaping LiteNetwork.MakeRedirect) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.makeRedirect = redirect
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// 更新全局重定向
    func updateGlobeRedirect(for redirect: @escaping LiteNetwork.MakeRedirect) {
        globeRedirect = redirect
    }
    
    /// 获得指定资源包的重定向数据
    /// - Parameter taskID: 指定taskID
    func getRedirectForSourceBag(for taskID: Int) -> LiteNetwork.MakeRedirect? {
        if let sourceBag = getSourceBag(for: taskID), let redirect = sourceBag.makeRedirect {
            return redirect
        } else {
            return globeRedirect
        }
    }
    
    /// 更新末尾资源包的数据处理方式
    /// - Parameter failure: 目标错误处理
    func updateProcessFailureToTrail(new failure: @escaping LiteNetwork.ProcessError) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.processError = failure
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// 更新全局错误处理方式
    /// - Parameter failure: 目标错误处理
    func updateGlobeProcessFailureToTrail(new failure: @escaping LiteNetwork.ProcessError) {
        globeProcessError = failure
    }
    
    /// 获得指定资源包的全局错误处理
    /// - Parameter taskID: 指定taskID
    func getProcessErrorForSourceBag(for taskID: Int) -> LiteNetwork.ProcessError? {
        if let sourceBag = getSourceBag(for: taskID), let processError = sourceBag.processError {
            return processError
        } else {
            return globeProcessError
        }
    }
    
    /// 添加指定资源包的应答数据
    /// - Parameters:
    ///   - taskID: 指定taskID
    ///   - data: 要添加的数据
    func appendDataForSourceBag(for taskID: Int, data: Data) {
        guard var sourceBag = getSourceBag(for: taskID) else {
            return
        }
        if var responseData = sourceBag.responseData {
            responseData.append(data)
            sourceBag.responseData = responseData
        } else {
            sourceBag.responseData = data
        }
        setSourceBag(new: sourceBag, for: taskID)
    }
    
    /// 更新末尾资源包的上传进程
    func updateUploadProcessProgressToTrail(new progress: @escaping LiteNetwork.ProcessProgress) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.processUploadProgress = progress
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// 更新末尾资源包的下载进程
    func updateDownloadProcessProgressToTrail(new progress: @escaping LiteNetwork.ProcessProgress) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.processDownloadProgress = progress
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// 更新末尾资源包的下载文件
    /// - Parameter processFile: 参数为目标URL的闭包
    func updateDownloadFileToTrail(new processFile: @escaping LiteNetwork.ProcessDownloadFile) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.processDownloadFile = processFile
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// 更新末尾资源包的request指标
    func updateAnalyzeRequestToTrail(for analyze: @escaping LiteNetwork.AnalyzeRequest) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.analyzeRequest = analyze
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// 更新末尾资源包创建的流
    func updateProduceNewStreamToTrail(for new: @escaping LiteNetwork.ProduceNewStream) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.makeNewStream = new
        setTrailSourceBag(for: trailSourceBag)
    }
    
    ///更新末尾资源包的鉴权处理
    func updateProcessAuthenticationChallengeToTrail(for challenge: @escaping LiteNetwork.ProcessAuthenticationChallenge) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.processAuthenticationChallenge = challenge
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// 更新末尾资源包的session级别鉴权处理
    func updateSessionProcessAuthenticationChallengeToTrail(for challenge: @escaping LiteNetwork.ProcessAuthenticationChallenge) {
        sessionAuthenticationChallenge = challenge
    }
    
    /// 更新末尾资源包的请求重试次数
    func updateRequestRetryCountToTrail(for count: Int) {
        guard var trailSourceBag = getTrailSourceBag(), count > 0 else {
            return
        }
        trailSourceBag.retryCount = count
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// 更新全局请求重试次数
    func updateGlobeRequestRetryCount(for count: Int) {
        guard count > 0 else {
            return
        }
        self.globeRetryCount = count
    }
    
    /// 获得指定资源包的重试次数
    /// - Parameter taskID: 指定资源包的taskID
    func getRetryCountForSourceBag(for taskID: Int) -> Int {
        if let sourceBag = getSourceBag(for: taskID) {
            if let count = sourceBag.retryCount {
                return count
            } else {
                return globeRetryCount ?? 0
            }
        }
        return 0
    }
}
