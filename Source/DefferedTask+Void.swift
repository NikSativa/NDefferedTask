import Foundation

public extension DefferedTask {
    convenience init() where ResultType == Void {
        self.init(execute: { $0(()) })
    }

    static func success() -> DefferedTask
    where ResultType == Void {
        return .init(result: makeVoid())
    }

    static func success<Error: Swift.Error>() -> DefferedResult<Void, Error>
    where ResultType == Result<Void, Error> {
        return .success(makeVoid())
    }

    func flatMapVoid() -> DefferedTask<Void> {
        return flatMap(makeVoid)
    }

    func mapVoid<T, Error: Swift.Error>() -> DefferedResult<Void, Error>
    where ResultType == Result<T, Error> {
        return map(makeVoid)
    }

    func onComplete(_ callback: @escaping () -> Void) where ResultType == Void {
        onComplete { _ in
            callback()
        }
    }

    func onComplete<Error: Swift.Error>(_ callback: @escaping () -> Void)
    where ResultType == Result<Void, Error> {
        onComplete { _ in
            callback()
        }
    }
}

private func makeVoid() {}
private func makeVoid(_: some Any) {}
