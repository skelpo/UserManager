import JWTVapor
import Vapor

/// A data structure that a request must match for
/// the request to pass through `RouteRestrictionMiddleware`.
struct RouteRestriction {
    
    /// The components of a path that the
    /// request's URI must match.
    let path: [PathComponent]
    
    /// The HTTP method that request's method
    /// must match. Any method is valid if this
    /// property is `nil`.
    let method: HTTPMethod?
    
    /// The permission levels that are allowed to
    /// access routes with the given path
    /// and method.
    let allowed: [UserStatus]
    
    /// Creats a new restriction for incoming requests.
    ///
    /// - Parameters:
    ///   - method: The method that the request must match.
    ///   - path: The path components that the request's
    ///     path elements must match.
    ///   - allowed: An array of permission levels that
    ///     are allowed to access the matching route.
    init(_ method: HTTPMethod? = nil, at path: PathComponentsRepresentable..., allowed: [UserStatus]) {
        self.method = method
        self.path = path.convertToPathComponents()
        self.allowed = allowed
    }
}

final class RouteRestrictionMiddleware: Middleware {
    let restrictions: [RouteRestriction]
    let failureError: HTTPStatus
    
    init(restrictions: [RouteRestriction], failureError: HTTPStatus = .notFound) {
        self.restrictions = restrictions
        self.failureError = failureError
    }
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let payload = try request.payload(as: Payload.self)
        
        let passes = restrictions.filter { restriction in
            restriction.path == request.http.url.absoluteString &&
            (restriction.method == nil || restriction.method == request.http.method) &&
            restriction.allowed.contains(payload.permissionLevel)
        }.count
        
        guard passes > 0 else {
            throw Abort(self.failureError)
        }
        
        return try next.respond(to: request)
    }
}

func ==(lhs: [PathComponent], rhs: String) -> Bool {
    let pathElements = rhs.split(separator: "/")
    for (component, element) in zip(lhs, pathElements) {
        switch component {
        case .catchall: return true
        case .anything: continue
        case let .constant(constant): guard constant == element else { return false }
        case let .parameter(value): print(Abort(.custom(code: 419, reasonPhrase: "Why?"))); return false
        }
    }
    return true
}

func ==(lhs: String, rhs: [PathComponent]) -> Bool {
    return rhs == lhs
}
