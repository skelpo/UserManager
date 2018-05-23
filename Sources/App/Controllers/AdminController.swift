import FluentMySQL
import Vapor

final class AdminController: RouteCollection {
    func boot(router: Router) throws {
        let users = router.grouped("users")
        
        users.get(use: allUsers)
        users.patch(UserUpdate.self, at: User.parameter, use: editUser)
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
}

struct AllUsersSuccessResponse: Content {
    let status: String = "success"
    let users: [UserResponse]
}

struct UserUpdate: Content {
    var firstname: String?
    var lastname: String?
    var email: String?
    var language: String?
    var confirmed: Bool?
    var permissionLevel: UserStatus?
}
