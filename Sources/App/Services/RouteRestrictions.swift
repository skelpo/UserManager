import JWTVapor
import Fluent
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
    
    /// Parameters types that can be used in
    /// a route path.
    let parameters: [String: (String, Container)throws -> Any]
    
    /// Creates a middleware instance with restrictions and an HTTP status to throw
    /// if they all fail on a request.
    ///
    /// - Parameters:
    ///   - restrioctions: An array the `RouteRestrictions` to verify each incoming
    ///     request against.
    ///   - failureError: The HTTP status to throw if all restrictions fail. The default
    ///     value is `.notFound` (404). `.unauthorized` (401) would be another common option.
    ///   - parameters: Paramater types that can be used in a route path. Basic types are
    ///     added by default, so only add custom types.
    init(restrictions: [RouteRestriction], failureError: HTTPStatus = .notFound, parameters: [String: (String, Container)throws -> Any] = [:]) {
        self.restrictions = restrictions
        self.failureError = failureError
        
        let defaultParameters: [String: (String, Container)throws -> Any] = [
            String.routingSlug: String.resolveParameter,
            Int.routingSlug: Int.resolveParameter,
            Int8.routingSlug: Int8.resolveParameter,
            Int16.routingSlug: Int16.resolveParameter,
            Int32.routingSlug: Int32.resolveParameter,
            Int64.routingSlug: Int64.resolveParameter,
            UInt.routingSlug: UInt.resolveParameter,
            UInt8.routingSlug: UInt8.resolveParameter,
            UInt16.routingSlug: UInt16.resolveParameter,
            UInt32.routingSlug: UInt32.resolveParameter,
            UInt64.routingSlug: UInt64.resolveParameter,
            Float.routingSlug: Float.resolveParameter,
            Double.routingSlug: Double.resolveParameter,
            UUID.routingSlug: UUID.resolveParameter
        ]
        self.parameters = parameters.merging(defaultParameters) { first, _ in first }
    }
    
    /// Called with each `Request` that passes through this middleware.
    /// - Parameters:
    ///     - request: The incoming `Request`.
    ///     - next: Next `Responder` in the chain, potentially another middleware or the main router.
    /// - Returns: An asynchronous `Response`.
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        
        // Iterate over each restrction, seeing if it matches the request.
        let passes = try restrictions.filter { restriction in
            
            // Verify restriction path components and request URI equality.
            // We drop the first element of the request's patch components because
            // that values is always `/`, which we don't need to match against.
            try self.compare(components: restriction.path, to: Array(request.http.url.pathComponents.dropFirst()), parameters: self.parameters, on: request) &&
                
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
            
            // Check that the user's permission level exists in the ones
            // contained in the restrictions thatr match the request.
            guard
                try passes.map({ $0.allowed }).joined().contains(payload.permissionLevel) ||
                self.ids(from: Array(request.http.url.pathComponents.dropFirst()), matching: passes[0].path, for: User.self).contains(payload.id)
            else {
                throw Abort(self.failureError)
            }
        } catch {
            
            // There us no payload, but we expected one.
            // The use is not authenticated, so throw the
            // registered failure error.
            throw Abort(self.failureError)
        }
        
        // Continue the responder chain.
        return try next.respond(to: request)
    }
    
    private func compare(components: [PathComponent], to path: [String], parameters: [String: (String, Container)throws -> Any], on container: Container)throws -> Bool {
        
        // Zip the arrays togeather so we can check each
        // element in the same position.
        for (component, element) in zip(components, path) {
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
                
            // Get the parameter type for the given placeholder slug.
            // Run the `.resolveParameter` method on it. If it doesn't
            // throw, we assume a match and continue the loop.
            case let .parameter(value):
                guard let resolver = parameters[value] else {
                    throw Abort(.internalServerError, reason: "No registed parameter type found for slug '\(value)'")
                }
                _ = try resolver(element, container)
            }
        }
        return true
    }
    
    private func ids<Parent>(from path: [String], matching: [PathComponent], for userType: Parent.Type = Parent.self)throws -> [Parent.ID]
        where Parent: Model & Parameter, Parent.ID: LosslessStringConvertible
    {
        // Get path componentns that are used as parameters.
        return try zip(path, matching).compactMap { components -> (slug: String, element: String)? in
            guard case let PathComponent.parameter(slug) = components.1 else { return nil }
            return (slug, components.0)
        }
            
        // Filter out parameters for the `Parent` model.
        .filter { $0.slug == Parent.routingSlug }
            
        // Get the `Parent` IDs from the paramneter value
        // passed in through the URL.
        .map { parameter in
            guard let id = Parent.ID.init(parameter.element) else {
                throw Abort(.badRequest, reason: "Unable to create \(String(describing: Parent.self)) ID from parameter '\(parameter.element)'")
            }
            return id
        }
    }
}
