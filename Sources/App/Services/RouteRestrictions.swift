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

/// Verfies incoming request's againts `RouteRestriction` instances.
final class RouteRestrictionMiddleware: Middleware {
    
    /// All the restrictions to check against the
    /// incoming request. Only one restriction must
    /// pass for the request to validated.
    let restrictions: [RouteRestriction]
    
    /// THe status code to throw if no
    /// restriction passes.
    let failureError: HTTPStatus
    
    /// Creates a middleware instance with restrictions and an HTTP status to throw
    /// if they all fail on a request.
    ///
    /// - Parameters:
    ///   - restrioctions: An array the `RouteRestrictions` to verify each incoming
    ///     request against.
    ///   - failureError: The HTTP status to throw if all restrictions fail. The default
    ///     value is `.notFound` (404). `.unauthorized` (401) would be another common option.
    init(restrictions: [RouteRestriction], failureError: HTTPStatus = .notFound) {
        self.restrictions = restrictions
        self.failureError = failureError
    }
    
    /// Called with each `Request` that passes through this middleware.
    /// - Parameters:
    ///     - request: The incoming `Request`.
    ///     - next: Next `Responder` in the chain, potentially another middleware or the main router.
    /// - Returns: An asynchronous `Response`.
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        
        // Iterate over each restrction, seeing if it matches the request.
        let passes = restrictions.filter { restriction in
            
            // Verify restriction path components and request URI equality.
            restriction.path == request.http.url.pathComponents &&
                
            // Verfiy resriction and request method equality.
            (restriction.method == nil || restriction.method == request.http.method)
        }

        if passes.count <= 0 {
            
            // There are no matching restrictions for the request. Continue the responder chain.
            return try next.respond(to: request)
        }
        
        do {
            // Fetch the payload from the request `Authorization: Bearer ...` header.
            // We use the payload to get the user's permission level.
            let payload = try request.payload(as: Payload.self)
            
            // Check that the user's epermission level exists in the ones
            // contained in the restrictions thatr match the request.
            guard passes.map({ $0.allowed }).joined().contains(payload.permissionLevel) else {
                throw Abort(self.failureError)
            }
        } catch {
            
            // There is no payload, so we continue the responder chain.
            return try next.respond(to: request)
        }
        
        // Continue the responder chain.
        return try next.respond(to: request)
    }
}

/// Checks that path components and URL components are
/// loosly equal.
///
/// - Parameters:
///   - lhs: The path components to check against the URL components
///   - rhs: The URL components to check against the path components
///
/// - Returns: `true` if they match, `false` if they don't.
func ==(lhs: [PathComponent], rhs: [String]) -> Bool {
    
    // Zip the arrays togeatherso we can check each
    // element in the sam position.
    for (component, element) in zip(lhs, rhs) {
        switch component {
        
        // Always matches the rest of the components.
        // We haven't returned false yet, so return true.
        case .catchall: return true
            
        // Always matches the current case.
        // Continue to the next loop iteraton.
        case .anything: continue
            
        // Check that the current path element and component match.
        // If they do, continue to the next iteration, otherwise return `false`.
        case let .constant(constant): guard constant == element else { return false }
            
        // Somehow verify that the path element is valid for the parameer.
        case let .parameter(value): print(Abort(.custom(code: 419, reasonPhrase: "Why?"))); return false
        }
    }
    return true
}

/// Checks that path components and URL components are
/// loosly equal.
///
/// - Parameters:
///   - lhs: The URL components to check against the path components
///   - rhs: The path components to check against the URL components
///
/// - Returns: `true` if they match, `false` if they don't.
func ==(lhs: [String], rhs: [PathComponent]) -> Bool {
    return rhs == lhs
}
