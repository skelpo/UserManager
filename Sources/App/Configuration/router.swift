import Routing
import Vapor

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router) throws {
    
    // Create a 'health' route useed by AWS to check if the server needs a re-boot.
    router.get(any, "users", "health") { _ in
        return "all good"
    }
    
    try router.register(collection: AuthController())
    try router.register(collection: VersionedCollection())
}
