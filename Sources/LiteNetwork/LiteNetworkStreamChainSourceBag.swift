//
//  LiteNetworkStreamChainSourceBag.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/3/10.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

final class LiteNetworkStreamChainSourceBag {
    /// Defines the type of chain souceBag type
    enum ChainSourceBagType {
        case Read
        case Write
        case Communicate
        case CloseWrite
        case CloseRead
    }
    
    let type: ChainSourceBagType
    var writeOperation: (input: Data, timout: TimeInterval, completeHandler: LiteNetworkStream.WriteDataCompleteHandler)?
    var readOperation: (min: Int, max: Int, timeout: TimeInterval, completeHandler: LiteNetworkStream.ReadDataCompleteHandler)?
    var communicateOperation: (input: Data, min: Int, max: Int, timeout: TimeInterval, completeHandler: LiteNetworkStream.DataCommunicateComplteteHandler)?
    
    /// Write data operation initialization
    /// - Parameters:
    ///   - writeData: `Data` needed to be written
    ///   - timeout: A timeout for writing bytes.
    ///   - completeHandler: The completion handler to call when all bytes are written, or an error occurs.
    init(writeData: Data, timeout: TimeInterval, completeHandler: @escaping LiteNetworkStream.WriteDataCompleteHandler) {
        type = .Write
        writeOperation = (writeData, timeout, completeHandler)
    }
    
    /// Read operation initialization
    /// - Parameters:
    ///   - readMinLength: The minimum length of the read data
    ///   - maxLength: Maximum length of the read data
    ///   - timeout: A timeout for reading bytes.
    ///   - completeHandler: The completion handler to call when all bytes are read, or an error occurs.
    init(readMinLength: Int, maxLength: Int, timeout: TimeInterval, completeHandler: @escaping LiteNetworkStream.ReadDataCompleteHandler) {
        type = .Read
        readOperation = (readMinLength, maxLength, timeout, completeHandler)
    }
    
    /// communication operation initialization
    /// - Parameters:
    ///   - communicateData: `Data`
    ///   - minLength: The minimum length of data
    ///   - maxLength: The maximum length of data
    ///   - timeout: Allowed timeout interval
    ///   - completeHandler: The completion handler to call when all bytes are read and write, or an error occurs.
    init(communicateData: Data, minLength: Int, maxLength: Int, timeout: TimeInterval, completeHandler: @escaping LiteNetworkStream.DataCommunicateComplteteHandler) {
        type = .Communicate
        communicateOperation = (communicateData, minLength, maxLength, timeout, completeHandler)
    }
    
    private init(type: ChainSourceBagType) {
        self.type = type
    }
    
    static var closeReadSourceBag: LiteNetworkStreamChainSourceBag {
        LiteNetworkStreamChainSourceBag(type: .CloseRead)
    }
    
    static var closeWriteSourceBag: LiteNetworkStreamChainSourceBag {
        LiteNetworkStreamChainSourceBag(type: .CloseWrite)
    }
}
