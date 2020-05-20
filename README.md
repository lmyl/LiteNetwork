# LiteNetwork

LiteNetwork is a lightweight and powerful network request framework written in Swift.

- [Overview](#overview)
- [Feature](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Contact](#contact)


## Overview
LiteNetwork is a lightweight network request framework based on the Apple native `URLSession` API. You can easily and quickly change the configuration information, create and update tasks, perform unified management through the framework interface without caring about the underlying methods. The framework supports the creation and configuration of five tasks: data, download, uploadFile, uploadData and uploadStream. And provides a variety of custom interfaces.

## Features
- Handle URLSessionConfiguration and its update easily
- Support custom processing for data, download, upload and stream tasks
- Avoid inconveniently nested callbacks
- Multi-tasks asynchronous operations
- Unified tasks management
- Invalid session after all tasks finished


## Requirements

- iOS 13.0+ / macOS 10.12+
- Swift 5.2+


## Installation
### Swift Packages

Import the open source package to your project through the following operations:
1. `Xcode` -> `File` -> `Swift Packages` -> `Add Package Dependcies`
2. search `https://github.com/lmyl/LiteNetwork` and add it to your targets


## Usage

### Handle stream task
1. Initialize the configuration information and create the stream task use `makeStreamWith()` method:
```swift
// the default initialize create Default type of session
let token = LiteNetworkStream().makeStreamWith(host: "local", port: 9898)
```
2. Make some custom changes here:
```swift
let token = LiteNetworkStream().makeStreamWith(host: "local", port: 9898)
            .setEphemeralConfigureType() // Change Default to Ephemeral
            .updateStreamReadCloseComplete {
                print("Read closed")
        }
```

3. Call `startConnect()` or `startSecureConnect()` to resume the task:
```swift
let token = LiteNetworkStream().makeStreamWith(host: "local", port: 9898)
            .setEphemeralConfigureType()
            .updateStreamReadCloseComplete {
                print("Read closed")
        }
        .startConnect()
```

4. Connect with the server and process your operations. 
   **When there are multiple tasks, they will be executed asynchronously and serially.**
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
            // return Bool to indicate whether current session will be invalidated
            return false
        }
        
// You can create multiple tasks in a row, just like this:
token.writeData(input: input.data(using: .utf8)!, timeout: 30, completionHandler: {
            errorrNil in
            if let error = errorrNil {
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

5. **Notice if** 
* you close the read and write stream manually
* one operation occurs an `error`
* one operation return `true`

then session will call `invalidateAndCancel()` and invalid itself automatically, the rest of operations will not be carried out.
```swift
// manual operations:
token.closeWriteStream()
token.closeReadStream()
// or 
token.cancelSessionFinishCurrentTask()
// or 
token.cancelSessionRightWay()
```

### Handle data/upload/download task
The basic steps are similar to the above. Notice that you need to call `fire()` to resume all the tasks, rather than `startConnect()`.

1. Initialize and create your task:
```swift
let token2 = LiteNetwork().makeDataRequest(for: {
            URLRequest(url: URL(string: "https://www.baidu.com")!)
            })
```

2. Make some custom changes:
```swift
let token2 = LiteNetwork().makeDataRequest(for: {
            URLRequest(url: URL(string: "https://www.baidu.com")!)
            })
            .setRequestCachePolicy(for: .reloadIgnoringCacheData)
```

3. Handle your data received from server(or other kinds of data)
```swift
.processData(for: {
                response, dataOrNil in
                if let data = dataOrNil, let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
            })
```
4. Resume all the tasks use `fire()`. You can create multiple tasks in a row, just like the codes below:
```swift
let token2 = LiteNetwork()
            // first task
            .makeDataRequest(for: {
            URLRequest(url: URL(string: "https://www.baidu.com")!)
            }).setRequestCachePolicy(for: .reloadIgnoringCacheData).processData(for: {
                response, dataOrNil in
                if let data = dataOrNil, let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
            })
            // second task
            .makeDataRequest(for: {
            return URLRequest(url: URL(string: "https://www.apple.com/cn/")!)
            }).setRequestCachePolicy(for: .reloadIgnoringCacheData).processData(for: {
                response, dataOrNil in
                if let data = dataOrNil, let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
                expection.fulfill()
            }).processGlobeFailure(for: {
                print("Error:" + $0.localizedDescription)
                expection.fulfill()
            })
            // resume all
            .fire()
```

5. And you can invalid your session **at any times** using the method below. if you have not called invalid method manually, the framework defaults to invalid the session after all tasks finished.
```swift
token2.cancelSessionFinishCurrentTask()
// or
token2.cancelSessionRightWay()
```

**For more usages, please read [`LiteNetwork.swift`](https://github.com/lmyl/LiteNetwork/blob/master/Sources/LiteNetwork/LiteNetwork.swift) and [`LiteNetworkStream.swift`](https://github.com/lmyl/LiteNetwork/blob/master/Sources/LiteNetwork/LiteNetworkStream.swift)**


## Contact

**GitHub issue tracker**: [issue tracker](https://github.com/lmyl/LiteNetwork/issues) ( report bug here )

**Google email**: `1269458422ly@gmail.com` or `hxh0804@gmail.com` ( if you have any questions or suggestions, contact us)
