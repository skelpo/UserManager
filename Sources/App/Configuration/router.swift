import Routing
import Vapor
import JWTMiddleware

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router, _ container: Container) throws {
    let root = router.grouped(any, "users")
    
    // Create a 'health' route useed by AWS to check if the server needs a re-boot.
    root.get("health") { _ in
        return "all good"
    }
    
    let jwtService = try container.make(JWTService.self)
    
    try root.register(collection: AdminController())
    try root.register(collection: AuthController(jwtService: jwtService))
    try root.grouped(JWTAuthenticatableMiddleware<User>()).register(collection: UserController())
}
