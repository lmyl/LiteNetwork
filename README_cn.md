# LiteNetwork

LiteNetwork是一个功能强大的轻量级网络请求框架，开发语言为Swift。

- [概述](#概述)
- [功能](#功能)
- [环境](#环境)
- [配置](#配置)
- [使用](#使用)
- [联系我们](#联系我们)


## 概述

LiteNetwork是基于Apple原生API `URLSession` 的轻量级网络存储框架。它使用链式资源包管理系统来确保多任务有序、高效地执行。框架支持使用方法链调用多个请求并顺序执行，并可以轻松快速地更改配置信息、创建和新建任务等。您可以通过框架接口集成管理，而无需关心方法的底层实现。框架支持data, download, uploadFile, uploadData 和 uploadStream五种任务的创建和配置，并提供了一系列自定义接口。

## 功能
- 轻松处理`URLSessionConfiguration`的配置和更新
- 自定义data, download, upload 和 stream tasks 
- 避免多闭包嵌套回调
- 多任务异步执行
- 集成task管理系统
- 自动无效session

## 环境

- iOS 13.0+ / macOS 10.12+
- Swift 5.2+

## 配置
### Swift Packages

通过以下步骤向你的项目中导入开源包：
1. `Xcode` -> `File` -> `Swift Packages` -> `Add Package Dependcies`
2. 搜索 `https://github.com/lmyl/LiteNetwork` 并添加到你的targets中

### Cocoapods

在您项目的 `Podfile` 文件中添加声明：
```ruby
pod 'LiteNetwork' 
```

## 使用

### 处理流任务
1. 使用 `makeStreamWith()` 方法来初始化配置信息并创建 stream task：
```swift
// 使用默认初始化器创建Default类型会话
let token = LiteNetworkStream().makeStreamWith(host: "local", port: 9898)
```
2. 自定义session参数：
```swift
let token = LiteNetworkStream().makeStreamWith(host: "local", port: 9898)
            .setEphemeralConfigureType() // 修改 Default 为 Ephemeral
            .updateStreamReadCloseComplete {
                print("Read closed")
        }
```

3. 调用 `startConnect()` 或  `startSecureConnect()` 方法来resume task
```swift
let token = LiteNetworkStream().makeStreamWith(host: "local", port: 9898)
            .setEphemeralConfigureType()
            .updateStreamReadCloseComplete {
                print("Read closed")
        }
        .startConnect()
```

4. 与服务器通信并处理数据，注意：**当存在多个任务时，任务将会异步、串行执行**。
```swift
let input = "hello world!"
token.readData(minLength: 1, maxLength: 1000, timeout: 30) { dataOrNil, eof, errorOrNil in
            if let error = errorOrNil {
                print("Error: " + error.localizedDescription)
            }
            if let data = dataOrNil {
                print(String.init(data: data, encoding: .utf8)!)
            }
            print("EOF: \(eof)")
            // 返回Bool以判断当前session是否会失效
            return false
        }
        
// 连续创建多个任务，如以下代码所示:
token.writeData(input: input.data(using: .utf8)!, timeout: 30, completionHandler: {
            errorOrNil in
            if let error = errorOrNil {
                print("Error: " + error.localizedDescription)
            } else {
                print("Complete")
            }
            return false
        })
token.simpleCommunicateWithSever(input: input.data(using: .utf8)!) { dataOrNil, errorOrNil in
            if let data = dataOrNil {
                print(String.init(data: data, encoding: .utf8)!)
            }
            if let error = errorOrNil {
                print("Error: " + error.localizedDescription)
            }
            return false
        }
        
```
5. 注意：
* 如果**手动**关闭了读写流
* 如果某一个操作（`writeData()`, `readData()` 或 `simpleCommunicateWithSever()`）出现 `error`
* 如果某一个操作（`writeData()`, `readData()` 或 `simpleCommunicateWithSever()`）在完成回调中返回了 `true`

当前session将会自动调用 `invalidateAndCancel()` 无效自身，剩余的操作将不会被执行。
```swift
// 手动操作：
token.closeWriteStream()
token.closeReadStream()
// 或 
token.cancelSessionFinishCurrentTask()
// 或 
token.cancelSessionRightWay()
```

### 处理 data/upload/download 任务
基本的步骤与上述流任务的处理很相似。不同的是，你要调用 `fire()` 来激活所有的task，而不是上文中的 `startConnect()`

1. 创建并初始化task：
```swift
let token2 = LiteNetwork().makeDataRequest(for: {
            URLRequest(url: URL(string: "https://www.baidu.com")!)
            })
```

2. 自定义参数：
```swift
let token2 = LiteNetwork().makeDataRequest(for: {
            URLRequest(url: URL(string: "https://www.baidu.com")!)
            })
            .setRequestCachePolicy(for: .reloadIgnoringCacheData)
```

3. 处理从服务器收到的数据：
```swift
.processData(for: {
                response, dataOrNil in
                if let data = dataOrNil, let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
            })
```

4. 使用`fire()`来激活所有的task。你可以像如下代码所示连续创建多个任务：
```swift
let token2 = LiteNetwork()
            // 第一个task
            .makeDataRequest(for: {
            URLRequest(url: URL(string: "https://www.baidu.com")!)
            }).setRequestCachePolicy(for: .reloadIgnoringCacheData).processData(for: {
                response, dataOrNil in
                if let data = dataOrNil, let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
            })
            // 第二个task
            .makeDataRequest(for: {
            return URLRequest(url: URL(string: "https://www.apple.com/cn/")!)
            }).processData(for: {
                response, dataOrNil in
                if let data = dataOrNil, let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
            }).processGlobeFailure(for: {
                print("Error:" + $0.localizedDescription)
            })
            // 激活所有task
            .fire()
```
5. 你可以在**任何时候**使用下面的方法无效session。如果你没有手动调用这些无效方法，框架默认在所有task完成后使session无效。
```swift
token2.cancelSessionFinishCurrentTask()
// 或
token2.cancelSessionRightWay()
```

**了解更多使用方法，请参照[`LiteNetwork.swift`](https://github.com/lmyl/LiteNetwork/blob/master/Sources/LiteNetwork/LiteNetwork.swift) 
和
[`LiteNetworkStream.swift`](https://github.com/lmyl/LiteNetwork/blob/master/Sources/LiteNetwork/LiteNetworkStream.swift)**

## 联系我们

**GitHub issue tracker**: [issue tracker](https://github.com/lmyl/LiteNetwork/issues) ( 提出错误和改进 )

**Google 邮箱**: `1269458422ly@gmail.com` or `hxh0804@gmail.com` ( 如果有任何建议和问题，欢迎联系我们)

