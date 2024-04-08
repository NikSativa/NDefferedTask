import Foundation
import Threading

public typealias PendingResult<Response, Error: Swift.Error> = PendingTask<Result<Response, Error>>

public class PendingTask<ResultType> {
    public typealias DefferedTask = DefferedTaskKit.DefferedTask<ResultType>
    public typealias ServiceClosure = DefferedTask.TaskClosure
    public typealias Completion = DefferedTask.Completion

    private var mutex: Mutexing = Mutex.pthread(.recursive)
    private var cached: DefferedTask?

    private var beforeCallback: Completion?
    private var cachedCallback: Completion?
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
            let loacalCached: DefferedTask = cached ?? closure()
            return .init(execute: { [weak self, loacalCached] actual in
                guard let self else {
                    loacalCached.onComplete(actual)
                    return
                }

                mutex.sync {
                    if let _ = self.cached {
                        let originalCallback = self.cachedCallback
                        self.cachedCallback = { result in
                            originalCallback?(result)
                            actual(result)
                        }
                    } else {
                        loacalCached.beforeComplete { [weak self] result in
                            self?.beforeCallback?(result)
                        }
                        .afterComplete { [weak self] result in
                            self?.afterCallback?(result)
                        }
                        .assign(to: &self.cached)
                        .weakify()
                        .onComplete { [weak self] result in
                            self?.mutex.sync {
                                self?.cached = nil
                            }

                            let cachedCallback = self?.mutex.sync {
                                let originalCallback = self?.cachedCallback
                                self?.cachedCallback = nil
                                return originalCallback
                            }
                            cachedCallback?(result)
                            actual(result)
                        }
                    }
                }
            })
        }
    }

    public func restart(_ closure: @escaping ServiceClosure) -> DefferedTask {
        return restart(with: .init(execute: closure))
    }

    public func restart(with closure: @autoclosure () -> DefferedTask) -> DefferedTask {
        return restart(closure)
    }

    public func restart(_ closure: () -> DefferedTask) -> DefferedTask {
        cached = nil
        return current(closure)
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
