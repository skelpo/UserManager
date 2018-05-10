import Vapor

struct RouteRestriction {
    let path: [PathComponent]
    let method: HTTPMethod?
    let allowed: [UserStatus]
    
    init(_ method: HTTPMethod? = nil, at path: PathComponentsRepresentable..., allowed: [UserStatus]) {
        self.method = method
        self.path = path.convertToPathComponents()
        self.allowed = allowed
    }
}
