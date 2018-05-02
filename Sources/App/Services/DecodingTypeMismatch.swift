import APIErrorMiddleware
import Vapor

/// Converts `DecodingError.typeMismatch` errors to a human friendly response.
struct DecodingTypeMismatch: ErrorCatchingSpecialization {
    func convert(error: Error, on request: Request) -> ErrorResult? {
        if case let DecodingError.typeMismatch(type, context) = error {
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
            return ErrorResult(message: "Decoding request body failed. Make sure the '\(path)' key exists and is of type \(type)", status: .badRequest)
        }
        return nil
    }
}
