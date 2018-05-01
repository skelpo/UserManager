import APIErrorMiddleware
import Vapor

/// Catches decoding errors thrown from `URLEncodedFormDeocder`.
struct URLFormDecodingFailed: ErrorCatchingSpecialization {
    func convert(error: Error, on request: Request) -> ErrorResult? {
        if let error = error as? Debuggable, error.reason == "Value of type 'String' required for key ''." {
            return ErrorResult(message: "Form deocding failed. Are you sure you have all the required key/value pairs?", status: .badRequest)
        }
        return nil
    }
}
