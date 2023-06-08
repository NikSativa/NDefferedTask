import Foundation

@inline(__always)
@discardableResult
public func sync<T>(_ callback: DefferedTask<T>,
                    seconds: Double? = nil,
                    timeoutResult timeout: @autoclosure () -> T) -> T {
    return sync(callback,
                seconds: seconds,
                timeoutResult: timeout)
}

@inline(__always)
@discardableResult
public func sync<T>(_ callback: DefferedTask<T>,
                    seconds: Double? = nil,
                    timeoutResult timeout: () -> T) -> T {
    let group = DispatchGroup()
    var result: T!

    group.enter()
    callback.strongify()
        .onComplete {
            result = $0
            group.leave()
        }

    assert(seconds.map { $0 > 0 } ?? true, "seconds must be nil or greater than 0")

    if let seconds, seconds > 0 {
        let timeoutResult = group.wait(timeout: .now() + seconds)
        switch timeoutResult {
        case .success:
            break
        case .timedOut:
            result = timeout()
        }
    } else {
        group.wait()
    }

    return result
}
