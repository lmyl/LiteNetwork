//
//  LiteNetworkTask.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/2/27.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation


/// Defines the type of LiteNetwork task
enum LiteNetworkTask {
    case Data
    case UploadStream
    case UploadData
    case UploadFile
    case Download
}

extension LiteNetworkTask: CustomStringConvertible {
    var description: String {
        switch self {
        case .Data:
            return "数据任务"
        case .UploadStream:
            return "上传流任务"
        case .Download:
            return "下载任务"
        case .UploadData:
            return "上传数据任务"
        case .UploadFile:
            return  "上传文件任务"
        }
    }
}
