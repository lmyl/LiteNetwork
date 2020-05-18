//
//  LiteNetworkStreamChainSourceBagManager.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/3/10.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

final class LiteNetworkStreamChainSourceBagManager {
    private var sourceBags: [LiteNetworkStreamChainSourceBag] = []
    
    private var rwQueue = DispatchQueue(label: "LiteNetworkStreamChainSourceBagManager.token.com", attributes: .concurrent)
}

extension LiteNetworkStreamChainSourceBagManager {
    /// read source Bags
    /// - Returns: array of `LiteNetworkStreamChainSourceBag`
    func readSourceBags() -> [LiteNetworkStreamChainSourceBag] {
        var sourceBags: [LiteNetworkStreamChainSourceBag] = []
        rwQueue.sync {
            [unowned self] in
            sourceBags =  self.sourceBags
        }
        return sourceBags
    }
    
    /// write source Bags
    /// - Parameter sourceBags: array of  `LiteNetworkStreamChainSourceBag`
    func writeSourceBags(sourceBags: [LiteNetworkStreamChainSourceBag]) {
        rwQueue.async(flags: .barrier, execute: {
            [unowned self] in
            self.sourceBags = sourceBags
        })
    }
    
    /// Whether the chain sourceBag array is empty
    func isEmpty() -> Bool {
        readSourceBags().count == 0
    }
    
    /// Append chain sourceBag to the end of sourceBag array
    /// - Parameter sourceBag: the chain sourceBag needed to be appended
    func append(sourceBag: LiteNetworkStreamChainSourceBag) {
        var sourceBags = readSourceBags()
        sourceBags.append(sourceBag)
        writeSourceBags(sourceBags: sourceBags)
    }
    
    /// Remove the first chain sourceBag
    func removeFirst() {
        var sourceBags = readSourceBags()
        if sourceBags.isEmpty {
            return
        }
        sourceBags.removeFirst()
        writeSourceBags(sourceBags: sourceBags)
    }
    
    /// Remove all current chain sourceBags
    func removeAll() {
        let sourceBags: [LiteNetworkStreamChainSourceBag] = []
        writeSourceBags(sourceBags: sourceBags)
    }
    
    /// Get the first chain sourceBag
    func firstSourceBag() -> LiteNetworkStreamChainSourceBag? {
        let sourceBags = readSourceBags()
        if sourceBags.isEmpty {
            return nil
        }
        return sourceBags.first
    }
}
