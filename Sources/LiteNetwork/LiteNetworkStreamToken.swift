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
       ///   - completionHandler: The completion handler to call when all read and write are finished, or an error occurs.
    func simpleCommunicateWithSever(input: Data, minLength: Int, maxLength: Int, timeout: TimeInterval?, completionHandler: @escaping LiteNetworkStream.DataCommunicateComplteteHandler)
    
    /// write data operation
    /// - Parameters:
    ///   - input: `Data` needed to be written
    ///   - timeout: Allowed time interval
    ///   - completionHandler: The completion handler to call when all bytes are written, or an error occurs.
    func writeData(input: Data, timeout: TimeInterval?, completionHandler: @escaping LiteNetworkStream.WriteDataCompleteHandler)
    
    /// read data operation
    /// - Parameters:
    ///   - minLength: The minimum length of data
    ///   - maxLength: The maximum length of data
    ///   - timeout: Allowed time interval
    ///   - completeHandler: The completion handler to call when all data are read, or an error occurs.
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
    
    /// Simple communicate with server
    /// - Parameters:
    ///   - input: `Data` needed to be written
    ///   - minLength: The minimum length of data
    ///   - maxLength: The maximum length of data
    ///   - timeout: A timeout for reading and writing bytes.
    ///   - completionHandler: The completion handler to call when all read and write are finished, or an error occurs.
    public func simpleCommunicateWithSever(input: Data, minLength: Int = 1, maxLength: Int = 2048, timeout: TimeInterval? = nil, completionHandler: @escaping LiteNetworkStream.DataCommunicateComplteteHandler) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.simpleCommunicateWithSever(input: input, minLength: minLength, maxLength: maxLength, timeout: timeout, completionHandler: completionHandler)
    }
    
    /// Write data operation
    /// - Parameters:
    ///   - input: the data to be written
    ///   - timeout:
    ///   A timeout for writing bytes. If the write is not completed within the specified interval,
    ///   the write is canceled and the completionHandler is called with an error.
    ///   Pass 0 to prevent a write from timing out.
    ///   - completionHandler: The completion handler to call when all bytes are written, or an error occurs.
    public func writeData(input: Data, timeout: TimeInterval?, completionHandler: @escaping LiteNetworkStream.WriteDataCompleteHandler) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.writeData(input: input, timeout: timeout, completionHandler: completionHandler)
    }
    
    /// Read data operation
    /// - Parameters:
    ///   - minLength: The minimum length of data
    ///   - maxLength: The maximum length of data
    ///   - timeout: A timeout for reading bytes.
    ///   - completeHandler: The completion handler to call when all data are read, or an error occurs.
    public func readData(minLength: Int, maxLength: Int, timeout: TimeInterval?, completeHandler: @escaping LiteNetworkStream.ReadDataCompleteHandler) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.readData(minLength: minLength, maxLength: maxLength, timeout: timeout, completeHandler: completeHandler)
    }
    
    /// Close current write stream.
    public func closeWriteStream() {
        guard let delegate = self.delegate else {
            return
        }
        delegate.closeWriteStream()
    }
    
    /// Close current read stream
    public func closeReadStream() {
        guard let delegate = self.delegate else {
            return
        }
        delegate.closeReadStream()
    }
    
    /// Close the read and write stream, then invalid the session
    public func cancelSessionFinishCurrentTask() {
        guard let delegate = self.delegate else {
            return
        }
        delegate.cancelSessionFinishCurrentTask()
        self.delegate = nil
    }
    
    /// Invalid the session right away
    public func cancelSessionRightWay() {
        guard let delegate = self.delegate else {
            return
        }
        delegate.cancelSessionRightWay()
        self.delegate = nil
    }
}
