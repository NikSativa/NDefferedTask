# DefferedTaskKit
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FDefferedTaskKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NikSativa/DefferedTaskKit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FDefferedTaskKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NikSativa/DefferedTaskKit)

DefferedTaskKit is a simple library for wrapping closures that can be executed at a later time.

### DefferedTask
DefferedTask works with Value, but DefferedResult is working with Result type.

> [!IMPORTANT]
> 1. Task will be executed only on subscription by 'onComplete' method'. If you don't subscribe to the task, it will never be executed.
> 2. By default, the task is 'selfRetaint' and you don't need save reference in variables for task. Use 'weakify()' method to prevent retain cycle.
> 3. You can handle 'deinit' of task if you need.

### DefferedTask

```swift
DefferedTask<Int> { completion in
    print("start task")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        completion(10)
        print("end task")
    }
} onDeinit: {
    print("onDeinit")
}
.beforeComplete { result in
    print("beforeComplete: \(result)") // print 10
}
.afterComplete { result in
    print("afterComplete: \(result)") // print 10
}
.set(userInfo: "subject")
.strongify()
.map { value in
    return value * 2
}
.beforeComplete { result in
    print("beforeComplete: \(result)") // print 20
}
.afterComplete { result in
    print("afterComplete: \(result)") // print 20
}
.onComplete { result in
    print("onComplete: \(result)") // print 20
}
```

console output:
```
start task
beforeComplete: 10
beforeComplete: 20
onComplete: 20
afterComplete: 20
afterComplete: 10
onDeinit
end task
```

### PendingTask
Special task that is caching tasks while executing single main task.

```swift
let pending: PendingTask<Int> = .init()

for i in 0..<10 {
    pending.current { completion in
        print("start main task")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(10)
            print("end main task")
        }
    }.onComplete { _ in
        print("onComplete: \(i)")
    }
}
```

console output:
```
start main task
onComplete: 0
onComplete: 1
onComplete: 2
onComplete: 3
onComplete: 4
onComplete: 5
onComplete: 6
onComplete: 7
onComplete: 8
onComplete: 9
end main task
```

### PollingTask
Special task that is polling main task with idleTimeInterval and retryCount.

```swift
var idx = 0
PollingTask<Int>(idleTimeInterval: 1,
                 retryCount: 5,
                 generator: {
    return .init { completion in
        print("start main task")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(idx)
            idx += 1
            print("end main task")
        }
    }
},
                 shouldRepeat: { idx in
    print("shouldRepeat \(idx)")
    return idx < 4
},
                 response: { idx in
    print("response: \(idx)")
})
.start()
.onComplete { result in
    print("completed \(result)")
} 
```

console output:
```
start main task
response: 0
shouldRepeat 0
end main task
start main task
response: 1
shouldRepeat 1
end main task
start main task
response: 2
shouldRepeat 2
end main task
start main task
response: 3
shouldRepeat 3
end main task
start main task
response: 4
shouldRepeat 4
completed 4
end main task
```
