import JWTMiddleware
import FluentMySQL
import Vapor

final class AdminController: RouteCollection {
    func boot(router: Router) throws {
        let admin = router.grouped(
            RouteRestrictionMiddleware<UserStatus, Payload, User>(
                restrictions: [
                    RouteRestriction.init(.GET, at: "users", allowed: [.admin]),
                    RouteRestriction.init(.PATCH, at: "users", User.parameter, allowed: [.admin]),
                    RouteRestriction.init(.PATCH, at: "attributes", Attribute.parameter, allowed: [.admin])
                ],
                parameters: [User.routingSlug: User.resolveParameter, Attribute.routingSlug: Attribute.resolveParameter])
        )
        
        admin.get("users", use: allUsers)
        admin.patch(UserUpdate.self, at: "users", User.parameter, use: editUser)
        admin.patch(AttributeUpdate.self, at: "attributes", Attribute.parameter, use: editAttribute)
    }
    
    func allUsers(_ request: Request)throws -> Future<AllUsersSuccessResponse> {
        return User.query(on: request).all().flatMap(to: [([Attribute], User)].self) { users in
            return try users.map { user in
                return try user.attributes(on: request).all().and(result: user)
            }.flatten(on: request)
        }.map(to: [UserResponse].self) { responses in
            return responses.map { response in
                return UserResponse(user: response.1, attributes: response.0)
            }
        }.map(AllUsersSuccessResponse.init)
    }
    
    func editUser(_ request: Request, _ body: UserUpdate)throws -> Future<UserSuccessResponse> {
        let user = try request.parameters.next(User.self)
        return user.flatMap(to: User.self) { user in
            user.firstname = body.firstname ?? user.firstname
            user.lastname = body.lastname ?? user.lastname
            user.email = body.email ?? user.email
            user.language = body.language ?? user.language
            user.confirmed = body.confirmed ?? user.confirmed
            user.permissionLevel = body.permissionLevel ?? user.permissionLevel
            return user.update(on: request)
        }.response(on: request, forProfile: true)
    }
    
    func editAttribute(_ request: Request, _ body: AttributeUpdate)throws -> Future<Attribute> {
        let attribute = try request.parameters.next(Attribute.self)
        return attribute.flatMap(to: Attribute.self) { attribute in
            attribute.text = body.value ?? attribute.text
            return attribute.update(on: request)
        }
    }
}

struct AllUsersSuccessResponse: Content {
    let status: String = "success"
    let users: [UserResponse]
}

struct UserUpdate: Content {
    let firstname: String?
    let lastname: String?
    let email: String?
    let language: String?
    let confirmed: Bool?
    let permissionLevel: UserStatus?
}

struct AttributeUpdate: Content {
    let value: String?
}
