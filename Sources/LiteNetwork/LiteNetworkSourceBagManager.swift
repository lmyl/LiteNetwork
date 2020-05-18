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
    
    /// Read source Bag
    /// - Returns: `Array` of LiteNetworkSourceBag struct
    func readSourceBags() -> [LiteNetworkSourceBag] {
        var sourceBags: [LiteNetworkSourceBag] = []
        rwQueue.sync(execute: {
            [unowned self] in
            sourceBags = self.sourceBags
        })
        return sourceBags
    }
    
    /// Write source Bag
    /// - Parameter sourceBags: `Array` of LiteNetworkSourceBag struct
    func writeSourceBag(sourceBags: [LiteNetworkSourceBag]) {
        rwQueue.async(flags: .barrier, execute: {
            [unowned self] in
            self.sourceBags = sourceBags
        })
    }
    
    /// Add new sourceBag into the `Array`
    /// - Parameter sourceBag: the sourceBag that
    func push(new sourceBag: LiteNetworkSourceBag) {
        var newSourceBag = sourceBag
        var sourceBags = readSourceBags()
        newSourceBag.sourceBagIdentifier = sourceBags.count
        sourceBags.append(newSourceBag)
        writeSourceBag(sourceBags: sourceBags)
    }
    
    /// Whether the sourceBag array is empty
    func isEmpty() -> Bool {
        return readSourceBags().count == 0
    }
    
    /// Get the newest sourceBag ( also the last in the sourceBag array )
    func getTrailSourceBag() -> LiteNetworkSourceBag? {
        return readSourceBags().last
    }
    
    /// Update the last sourceBag
    /// - Parameter sourceBag: Replacement sourceBag
    func setTrailSourceBag(for sourceBag: LiteNetworkSourceBag) {
        guard !isEmpty() else {
            return
        }
        var sourceBags = readSourceBags()
        let lastIndex = sourceBags.endIndex
        sourceBags[lastIndex - 1] = sourceBag
        writeSourceBag(sourceBags: sourceBags)
    }
    
    /// Get the sourceBag with the specified task ID
    /// - Parameter taskID: task ID of the specified sourceBag
    func getSourceBag(for taskID: Int) -> LiteNetworkSourceBag? {
        let sourceBags = readSourceBags()
        for sourceBag in sourceBags {
            if sourceBag.requestTaskID == taskID {
                return sourceBag
            }
        }
        return nil
    }
    
    /// Update the sourceBag with the specified task ID
    /// - Parameters:
    ///   - sourceBag: Replacement sourceBag
    ///   - taskID: task ID of the sourceBag to update
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
    
    /// Update the sourceBag with the specified ID
    /// - Parameters:
    ///   - sourceBag: Replacement sourceBag
    ///   - sourceBagIdentifier: ID of the sourceBag to update
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
    
    /// Remove the sourceBag with the specified task ID
    /// - Parameter taskID: specified task ID
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
    
    /// Remove all current sourceBags
    func removeAllSourceBag() {
        var sourceBags = readSourceBags()
        sourceBags.removeAll()
        writeSourceBag(sourceBags: sourceBags)
    }
    
    /// Remove the sourceBag with the specified ID
    /// - Parameter id: specified sourceBag ID
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
    
    /// Append data handling method to the last sourceBag
    /// - Parameter processData: `(URLResponse, Data) -> ()`
    func appendDataProcessToTrail(new processData: @escaping LiteNetwork.ProcessData) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.processData.append(processData)
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// Append request success handling method to the last sourceBag
    /// - Parameter processRequestSuccess: `(URLResponse) -> ()`
    func appendProcessRequestSuccessToTrail(new processRequestSuccess: @escaping LiteNetwork.ProcessRequestSuccess) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.processRequestSuccess.append(processRequestSuccess)
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// Update redirect information of the last sourceBag
    func updateRedirectToTrail(for redirect: @escaping LiteNetwork.MakeRedirect) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.makeRedirect = redirect
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// Update global redirect information
    func updateGlobeRedirect(for redirect: @escaping LiteNetwork.MakeRedirect) {
        globeRedirect = redirect
    }
    
    /// Get redirect information of  sourceBag with the specified task ID
    /// - Parameter taskID: specified task ID
    func getRedirectForSourceBag(for taskID: Int) -> LiteNetwork.MakeRedirect? {
        if let sourceBag = getSourceBag(for: taskID), let redirect = sourceBag.makeRedirect {
            return redirect
        } else {
            return globeRedirect
        }
    }
    
    /// Update error handling method of the last sourceBag
    /// - Parameter failure: replacement error handling method
    func updateProcessFailureToTrail(new failure: @escaping LiteNetwork.ProcessError) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.processError = failure
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// Update global error handling mehod
    /// - Parameter failure: replacement error handling method
    func updateGlobeProcessFailureToTrail(new failure: @escaping LiteNetwork.ProcessError) {
        globeProcessError = failure
    }
    
    /// Get error handling method of sourceBag with specified task ID
    /// - Parameter taskID: specidied task ID
    /// - Returns: if specified sourcebag exist and get error handling method successfully, return it. Else return global error handling method.
    func getProcessErrorForSourceBag(for taskID: Int) -> LiteNetwork.ProcessError? {
        if let sourceBag = getSourceBag(for: taskID), let processError = sourceBag.processError {
            return processError
        } else {
            return globeProcessError
        }
    }
    
    /// Append respense data for sourceBag with specified task ID
    /// - Parameters:
    ///   - taskID: specified task ID
    ///   - data: `Data` needed to be append
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
    
    /// Update the upload process progress of the last sourceBag
    func updateUploadProcessProgressToTrail(new progress: @escaping LiteNetwork.ProcessProgress) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.processUploadProgress = progress
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// Update the download process progress of the last sourceBag
    func updateDownloadProcessProgressToTrail(new progress: @escaping LiteNetwork.ProcessProgress) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.processDownloadProgress = progress
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// Update the download file `URL` of the last sourceBag
    /// - Parameter processFile: a closure that accepts a `URL` parameter
    func updateDownloadFileToTrail(new processFile: @escaping LiteNetwork.ProcessDownloadFile) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.processDownloadFile = processFile
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// Update the request analyzing method of the last sourceBag
    /// - Parameter analyze: `(URLSessionTaskMetrics) -> ()`
    func updateAnalyzeRequestToTrail(for analyze: @escaping LiteNetwork.AnalyzeRequest) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.analyzeRequest = analyze
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// Update stream created by the last sourceBag
    func updateProduceNewStreamToTrail(for new: @escaping LiteNetwork.ProduceNewStream) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.makeNewStream = new
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// Update the authentication challenge handing of the last sourceBag ( task-specified )
    func updateProcessAuthenticationChallengeToTrail(for challenge: @escaping LiteNetwork.ProcessAuthenticationChallenge) {
        guard var trailSourceBag = getTrailSourceBag() else {
            return
        }
        trailSourceBag.processAuthenticationChallenge = challenge
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// Update the authentication challenge handling of the last sourceBag ( session-wide )
    func updateSessionProcessAuthenticationChallengeToTrail(for challenge: @escaping LiteNetwork.ProcessAuthenticationChallenge) {
        sessionAuthenticationChallenge = challenge
    }
    
    /// Update the  request retry times of the last sourceBag
    func updateRequestRetryCountToTrail(for count: Int) {
        guard var trailSourceBag = getTrailSourceBag(), count > 0 else {
            return
        }
        trailSourceBag.retryCount = count
        setTrailSourceBag(for: trailSourceBag)
    }
    
    /// Update the global request retry times
    func updateGlobeRequestRetryCount(for count: Int) {
        guard count > 0 else {
            return
        }
        self.globeRetryCount = count
    }
    
    /// Get the retry times of the specified-taskID sourceBag
    /// - Parameter taskID: specified task ID
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
