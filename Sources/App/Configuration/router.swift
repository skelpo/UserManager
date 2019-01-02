import Routing
import Vapor
import JWTMiddleware

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router, _ container: Container) throws {
    
    // Create a 'health' route useed by AWS to check if the server needs a re-boot.
    router.get(any, "users", "health") { _ in
        return "all good"
    }
    
    let jwtService = try container.make(JWTService.self)
    
    try router.register(collection: AuthController(jwtService: jwtService))
    try router.register(collection: VersionedCollection())
}
