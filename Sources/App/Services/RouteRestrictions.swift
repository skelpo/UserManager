import HTTP

struct RouteRestriction {
    let path: PathRestiction
    let method: HTTPMethod?
    let allowed: [UserStatus]
}

struct PathRestiction: ExpressibleByStringLiteral {
    let prefix: String?
    let full: String?
    
    init(stringLiteral value: String) {
        if value.last == "*" {
            self.prefix = value
            self.full = nil
        } else {
            self.full = value
            self.prefix = nil
        }
    }
}
