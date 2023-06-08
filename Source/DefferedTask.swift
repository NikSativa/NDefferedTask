import Foundation
import NQueue

public typealias DefferedResult<T, E: Error> = DefferedTask<Result<T, E>>

public final class DefferedTask<ResultType> {
    public typealias Completion = (_ result: ResultType) -> Void
    public typealias TaskClosure = (_ completion: @escaping Completion) -> Void
    public typealias DeinitClosure = () -> Void

    public var userInfo: Any?

    private let work: TaskClosure
    private let cancel: DeinitClosure
    private var beforeCallback: Completion?
    private var completeCallback: Completion?
    private var afterComplete: Completion?
    private var options: MemoryOption = .selfRetained
    private var mutex: Mutexing = Mutex.pthread(.recursive)
    private var completionQueue: DelayedQueue = .absent
    private var workQueue: DelayedQueue = .absent
    private var strongyfy: DefferedTask?
    private var completed: Bool = false

    public required init(execute workItem: @escaping TaskClosure,
                         onDeinit cancelation: @escaping DeinitClosure = {}) {
        self.work = workItem
        self.cancel = cancelation
    }

    private func complete(_ result: ResultType) {
        typealias Callbacks = (before: Completion?, complete: Completion?, deferred: Completion?)

        let callbacks: Callbacks = mutex.sync {
            let callbacks: Callbacks = (before: self.beforeCallback, complete: self.completeCallback, deferred: self.afterComplete)

            self.beforeCallback = nil
            self.completeCallback = nil
            self.afterComplete = nil
            self.strongyfy = nil

            return callbacks
        }

        completionQueue.fire {
            callbacks.before?(result)
            callbacks.complete?(result)
            callbacks.deferred?(result)
        }
    }

    public func onComplete(_ callback: @escaping Completion) {
        assert(!completed, "`onComplete` was called twice, please check it!")

        mutex.sync {
            switch options {
            case .selfRetained:
                strongyfy = self
            case .weakness:
                break
            }

            completeCallback = callback
            completed = true
        }

        workQueue.fire {
            self.work { [unowned self] in
                complete($0)
            }
        }
    }

    deinit {
        cancel()
    }
}

// MARK: - public

public extension DefferedTask {
    // MARK: - convenience init

    convenience init(result: @escaping () -> ResultType) {
        self.init(execute: { $0(result()) })
    }

    convenience init(result: @escaping @autoclosure () -> ResultType) {
        self.init(execute: { $0(result()) })
    }

    // MARK: - oneWay

    /// execute work and ignore result
    func oneWay() {
        onComplete { _ in }
    }

    // MARK: - map

    func flatMap<NewResultType>(_ mapper: @escaping (ResultType) -> NewResultType) -> DefferedTask<NewResultType> {
        assert(!completed, "you can't change configuration after `onComplete`")
        mutex.sync {
            completed = true
            options = .weakness
            strongyfy = nil
        }

        let copy = DefferedTask<NewResultType>(execute: { [self] actual in
            mutex.sync {
                completed = false
            }

            onComplete {
                let new = mapper($0)
                actual(new)
            }
        })

        return copy
    }

    // MARK: - before

    @discardableResult
    func beforeComplete(_ callback: @escaping Completion) -> Self {
        mutex.sync {
            let originalCallback = beforeCallback
            beforeCallback = { result in
                originalCallback?(result)
                callback(result)
            }
        }

        return self
    }

    // MARK: - defer

    @discardableResult
    func afterComplete(_ callback: @escaping Completion) -> Self {
        mutex.sync {
            let originalCallback = afterComplete
            afterComplete = { result in
                originalCallback?(result)
                callback(result)
            }
        }

        return self
    }

    // MARK: - unwrap

    func unwrap<Response>(with value: @escaping @autoclosure () -> Response) -> DefferedTask<Response>
    where ResultType == Response? {
        return flatMap {
            return $0 ?? value()
        }
    }

    func unwrap<Response>(_ value: @escaping () -> Response) -> DefferedTask<Response>
    where ResultType == Response? {
        return flatMap {
            return $0 ?? value()
        }
    }

    // MARK: - assign

    func assign(to variable: inout AnyObject?) -> Self {
        assert(!completed, "you can't change configuration after `onComplete`")
        variable = self
        return self
    }

    func assign(to variable: inout AnyObject) -> Self {
        assert(!completed, "you can't change configuration after `onComplete`")
        variable = self
        return self
    }

    func assign(to variable: inout Any?) -> Self {
        assert(!completed, "you can't change configuration after `onComplete`")
        variable = self
        return self
    }

    func assign(to variable: inout Any) -> Self {
        assert(!completed, "you can't change configuration after `onComplete`")
        variable = self
        return self
    }

    func assign(to variable: inout DefferedTask?) -> Self {
        assert(!completed, "you can't change configuration after `onComplete`")
        variable = self
        return self
    }

    func assign(to variable: inout DefferedTask) -> Self {
        assert(!completed, "you can't change configuration after `onComplete`")
        variable = self
        return self
    }

    // MARK: - options

    func weakify() -> Self {
        assert(!completed, "you can't change configuration after `onComplete`")
        if options == .weakness {
            return self
        }

        mutex.sync {
            options = .weakness
        }
        return self
    }

    func strongify() -> Self {
        assert(!completed, "you can't change configuration after `onComplete`")
        if options == .selfRetained {
            return self
        }

        mutex.sync {
            options = .selfRetained
        }
        return self
    }

    // MARK: - queue

    func set(workQueue queue: DelayedQueue) -> Self {
        assert(!completed, "you can't change configuration after `onComplete`")
        mutex.sync {
            workQueue = queue
        }
        return self
    }

    func set(completionQueue queue: DelayedQueue) -> Self {
        assert(!completed, "you can't change configuration after `onComplete`")
        mutex.sync {
            completionQueue = queue
        }
        return self
    }

    // MARK: - userInfo

    func set(userInfo value: Any) -> Self {
        assert(!completed, "you can't change configuration after `onComplete`")
        mutex.sync {
            userInfo = value
        }
        return self
    }
}

// MARK: - DefferedTask.MemoryOption

private extension DefferedTask {
    enum MemoryOption: Equatable {
        case selfRetained
        case weakness
    }
}
