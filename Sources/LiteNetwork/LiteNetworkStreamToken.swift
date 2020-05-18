//
//  LiteNetworkStreamToken.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/3/10.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

protocol LiteNetworkStreamTokenDelegate: LiteNetworkTokenDelegate {
    /// simple communicate with server
       /// - Parameters:
       ///   - input: `Data` needed to be written
       ///   - minLength: The minimum length of data
       ///   - maxLength: The maximum length of data
       ///   - timeout: Allowed time interval
       ///   - completionHandler: completion handler
    func simpleCommunicateWithSever(input: Data, minLength: Int, maxLength: Int, timeout: TimeInterval?, completionHandler: @escaping LiteNetworkStream.DataCommunicateComplteteHandler)
    
    /// write data operation
    /// - Parameters:
    ///   - input: `Data` needed to be written
    ///   - timeout: Allowed time interval
    ///   - completionHandler: completion handler
    func writeData(input: Data, timeout: TimeInterval?, completionHandler: @escaping LiteNetworkStream.WriteDataCompleteHandler)
    
    /// read data operation
    /// - Parameters:
    ///   - minLength: The minimum length of data
    ///   - maxLength: The maximum length of data
    ///   - timeout: Allowed time interval
    ///   - completeHandler: completion handler
    func readData(minLength: Int, maxLength: Int, timeout: TimeInterval?, completeHandler: @escaping LiteNetworkStream.ReadDataCompleteHandler)
    
    /// close write stream
    func closeWriteStream()
    
    /// close read stream
    func closeReadStream()
}

public final class LiteNetworkStreamToken {
    private weak var delegate: LiteNetworkStreamTokenDelegate?
    
    func setDelegate(delegate: LiteNetworkStreamTokenDelegate) {
        self.delegate = delegate
    }
    
    public func simpleCommunicateWithSever(input: Data, minLength: Int = 1, maxLength: Int = 2048, timeout: TimeInterval? = nil, completionHandler: @escaping LiteNetworkStream.DataCommunicateComplteteHandler) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.simpleCommunicateWithSever(input: input, minLength: minLength, maxLength: maxLength, timeout: timeout, completionHandler: completionHandler)
    }
    
    public func writeData(input: Data, timeout: TimeInterval?, completionHandler: @escaping LiteNetworkStream.WriteDataCompleteHandler) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.writeData(input: input, timeout: timeout, completionHandler: completionHandler)
    }
    
    public func readData(minLength: Int, maxLength: Int, timeout: TimeInterval?, completeHandler: @escaping LiteNetworkStream.ReadDataCompleteHandler) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.readData(minLength: minLength, maxLength: maxLength, timeout: timeout, completeHandler: completeHandler)
    }
    
    public func closeWriteStream() {
        guard let delegate = self.delegate else {
            return
        }
        delegate.closeWriteStream()
    }
    
    public func closeReadStream() {
        guard let delegate = self.delegate else {
            return
        }
        delegate.closeReadStream()
    }
    
    public func cancelSessionFinishCurrentTask() {
        guard let delegate = self.delegate else {
            return
        }
        delegate.cancelSessionFinishCurrentTask()
        self.delegate = nil
    }
    
    public func cancelSessionRightWay() {
        guard let delegate = self.delegate else {
            return
        }
        delegate.cancelSessionRightWay()
        self.delegate = nil
    }
}
