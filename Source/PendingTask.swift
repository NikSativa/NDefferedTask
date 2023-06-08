import Foundation
import NQueue

public typealias PendingResult<Response, Error: Swift.Error> = PendingTask<Result<Response, Error>>

public class PendingTask<ResultType> {
    public typealias DefferedTask = NDefferedTask.DefferedTask<ResultType>
    public typealias ServiceClosure = DefferedTask.TaskClosure
    public typealias Completion = DefferedTask.Completion

    private var mutex: Mutexing = Mutex.pthread(.recursive)
    private var cached: DefferedTask?

    private var beforeCallback: Completion?
    private var afterCallback: Completion?

    public var isPending: Bool {
        return cached != nil
    }

    public init() {}

    public func current(_ closure: @escaping ServiceClosure) -> DefferedTask {
        return current(with: .init(execute: closure))
    }

    public func current(with closure: @autoclosure () -> DefferedTask) -> DefferedTask {
        return current(closure)
    }

    public func current(_ closure: () -> DefferedTask) -> DefferedTask {
        return mutex.sync {
            let info = Info(original: cached ?? closure())
            return .init(execute: { [weak self, info] actual in
                guard let self else {
                    info.original?.onComplete(actual)
                    return
                }

                mutex.sync {
                    if let cached = self.cached {
                        cached.afterComplete { result in
                            actual(result)
                        }
                    } else if let original = info.original {
                        original.beforeComplete { [weak self] result in
                            self?.cached = nil
                            self?.beforeCallback?(result)
                        }
                        .afterComplete { [weak self] result in
                            self?.afterCallback?(result)
                        }
                        .assign(to: &self.cached)
                        .weakify()
                        .onComplete { result in
                            actual(result)
                        }
                    } else {
                        assertionFailure("unexpected behavior")
                    }
                }
            })
        }
    }

    @discardableResult
    public func afterComplete(_ callback: @escaping Completion) -> Self {
        mutex.sync {
            let originalCallback = afterCallback
            afterCallback = { result in
                originalCallback?(result)
                callback(result)
            }
        }
        return self
    }

    @discardableResult
    public func beforeComplete(_ callback: @escaping Completion) -> Self {
        mutex.sync {
            let originalCallback = beforeCallback
            beforeCallback = { result in
                originalCallback?(result)
                callback(result)
            }
        }
        return self
    }
}

private final class Info<R> {
    private(set) weak var original: DefferedTask<R>?

    init(original: DefferedTask<R>) {
        self.original = original
    }

    func stop() {
        original = nil
    }
}
