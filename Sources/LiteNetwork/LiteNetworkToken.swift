//
//  LiteNetworkToken.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/3/4.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

protocol LiteNetworkTokenDelegate: class {
    /// cancel current session immediately
    func cancelSessionRightWay()
    
    /// cancel current session after finish current task
    func cancelSessionFinishCurrentTask()
}

public final class LiteNetworkToken {
    
    private weak var delegate: LiteNetworkTokenDelegate?
    
    public func cancelSessionRightWay() {
        guard let delegate = delegate else {
            return
        }
        delegate.cancelSessionRightWay()
        self.delegate = nil
    }
    
    public func cancelSessionFinishCurrentTask() {
        guard let delegate = delegate else {
            return
        }
        delegate.cancelSessionFinishCurrentTask()
        self.delegate = nil
    }
    
    func setDelegate(delegate: LiteNetworkTokenDelegate) {
        self.delegate = delegate
    }

}
