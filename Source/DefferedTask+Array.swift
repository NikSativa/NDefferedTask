import Foundation

public extension DefferedTask {
    func filterNils<Response>() -> DefferedTask<[Response]>
    where ResultType == [Response?] {
        return flatMap { result in
            result.compactMap { $0 }
        }
    }

    func filterNils<Response, Error: Swift.Error>() -> DefferedResult<[Response], Error>
    where ResultType == Result<[Response?], Error> {
        return map { result in
            result.compactMap { $0 }
        }
    }
}
