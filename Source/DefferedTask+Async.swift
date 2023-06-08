import Foundation

public extension DefferedTask {
    func onComplete() async -> ResultType {
        return await withCheckedContinuation { actual in
            onComplete(actual.resume(returning:))
        }
    }

    func onComplete<Response, Error: Swift.Error>() async throws -> Response
    where ResultType == Result<Response, Error> {
        return try await withCheckedThrowingContinuation { actual in
            onComplete(actual.resume(with:))
        }
    }
}
