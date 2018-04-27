import JWTMiddleware
import Vapor

/// This is where the routes from the `UserController` are initialized and registered.
/// - note: The confomance to `RouteCollection`.
///   This requires a `.boot(router: Router)` method and allows you to call `router.register(collection: routeCollection)`.
final class VersionedCollection: RouteCollection {
    
    /// Conforms `V1Collection` to `RouteCollection`.
    ///
    /// Registers the routes from the `UserController`
    /// to the router with a root path of `any`.
    ///
    /// - Parameter router: The router the `UserController`
    ///   routes will be registered to.
    func boot(router: Router) throws {
        try router.grouped(any).grouped(JWTAuthenticatableMiddlware<User>()).register(collection: UserController())
    }
}
