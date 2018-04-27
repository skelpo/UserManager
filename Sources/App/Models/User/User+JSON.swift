import Vapor
import Fluent

/// A representation of a `User` model instance
/// which is returned from routes for JSON responses
struct UserResponse: Content {
    let id: Int?
    let firstname, lastname, emailCode: String?
    let email, language: String
    let confirmed: Bool
    let permissionLevel: Int
    let attributes: [Attribute]?
    
    init(user: User, attributes: [Attribute]?) {
        self.id = user.id
        self.firstname = user.firstname
        self.lastname = user.lastname
        self.emailCode = user.emailCode
        self.email = user.email
        self.language = user.language
        self.confirmed = user.confirmed
        self.permissionLevel = user.permissionLevel.id
        self.attributes = attributes
    }
}

extension User {
    
    /// Creates a `UserResponse` representation of the current user.
    func response(on request: Request, forProfile profile: Bool)throws -> Future<UserSuccessResponse> {
        if !profile { return Future.map(on: request) { UserSuccessResponse(user: UserResponse(user: self, attributes: nil)) } }
        
        return try self.attributes(on: request).all().map(to: UserSuccessResponse.self) { attributes in
            let user = UserResponse(user: self, attributes: attributes)
            return UserSuccessResponse(user: user)
        }
    }
}

extension Future where T == User {
    
    /// Creates a `UserResponse` representation of the current user.
    func response(on request: Request, forProfile profile: Bool) -> Future<UserSuccessResponse> {
        return self.flatMap(to: UserSuccessResponse.self) { try $0.response(on: request, forProfile: profile) }
    }
}
